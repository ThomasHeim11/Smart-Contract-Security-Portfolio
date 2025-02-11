// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import "../../contracts/mock/MockChainlinkOracles.sol";
import "../../contracts/MultiHopOracle.sol";

contract MultiHopOracleTest is Test {
    MockChainlinkOracle internal chainlinkOracle1;
    MockChainlinkOracle internal chainlinkOracle2;
    MultiHopOracle internal multiHopOracle;

    // Helper function to deploy the oracles
    function deployOracles(int216 fixedValue1, int216 fixedValue2, uint256 delay1, uint256 delay2, bool[] memory invert)
        internal
        returns (MultiHopOracle)
    {
        chainlinkOracle1 = new MockChainlinkOracle(fixedValue1, delay1);
        chainlinkOracle2 = new MockChainlinkOracle(fixedValue2, delay2);

        address[] memory oracles = new address[](2);
        oracles[0] = address(chainlinkOracle1);
        oracles[1] = address(chainlinkOracle2);
        bool[] memory invertFlags = new bool[](2);
        invertFlags[0] = invert[0];
        invertFlags[1] = invert[1];

        MultiHopOracle.HopConfig[] memory hops = new MultiHopOracle.HopConfig[](2);
        hops[0] = MultiHopOracle.HopConfig({oracle: OracleWrapper(address(chainlinkOracle1)), invert: invert[0]});
        hops[1] = MultiHopOracle.HopConfig({oracle: OracleWrapper(address(chainlinkOracle2)), invert: invert[1]});

        multiHopOracle = new MultiHopOracle(hops);
        return multiHopOracle;
    }

    // Test 1: Without inversion
    function testShouldReturnMultipliedDataWithoutInversion() public {
        int216 fixedValue1 = 1000;
        int216 fixedValue2 = 0.001e18;
        uint256 delay1 = 3600;
        uint256 delay2 = 3600;

        bool[] memory invert = new bool[](2);
        invert[0] = false;
        invert[1] = false;

        multiHopOracle = deployOracles(fixedValue1, fixedValue2, delay1, delay2, invert);

        // Simulate time
        vm.warp(block.timestamp + 3600);

        (int216 data, uint40 timestamp) = multiHopOracle.getData();
        uint40 nowTimestamp = uint40(block.timestamp);

        assertEq(timestamp, nowTimestamp - delay1);
        assertEq(data, 1); // 1000 * 0.001 = 1
    }

    // Test 2: With second oracle inverted
    function testShouldReturnMultipliedDataWithSecondInverted() public {
        int216 fixedValue1 = 10e18; //this tests the invert conversion
        int216 fixedValue2 = 100;
        uint256 delay1 = 3600;
        uint256 delay2 = 3600;

        bool[] memory invert = new bool[](2);
        invert[0] = true;
        invert[1] = false;

        multiHopOracle = deployOracles(fixedValue1, fixedValue2, delay1, delay2, invert);

        // Simulate time
        vm.warp(block.timestamp + 3600);

        (int216 data, uint40 timestamp) = multiHopOracle.getData();
        uint40 nowTimestamp = uint40(block.timestamp);

        assertEq(timestamp, nowTimestamp - delay1);
        assertEq(data, 10); // 1000 / 100 = 10
    }

    // Test 3: With first oracle inverted
    function testShouldReturnMultipliedDataWithFirstInverted() public {
        int216 fixedValue1 = 1000;
        int216 fixedValue2 = 10e18;
        uint256 delay1 = 3600;
        uint256 delay2 = 3600;

        bool[] memory invert = new bool[](2);
        invert[0] = false;
        invert[1] = true;

        multiHopOracle = deployOracles(fixedValue1, fixedValue2, delay1, delay2, invert);

        // Simulate time
        vm.warp(block.timestamp + 3600);

        (int216 data, uint40 timestamp) = multiHopOracle.getData();
        uint40 nowTimestamp = uint40(block.timestamp);

        assertEq(timestamp, nowTimestamp - delay1);
        assertEq(data, 100); // 1000 / 10 = 100
    }

    // Test 4: Should return lower timestamp (the second delay is greater)
    function testShouldReturnLowerTimestamp() public {
        int216 fixedValue1 = 1000;
        int216 fixedValue2 = 0.001e18;
        uint256 delay1 = 3600;
        uint256 delay2 = 3650;

        bool[] memory invert = new bool[](2);
        invert[0] = false;
        invert[1] = false;

        multiHopOracle = deployOracles(fixedValue1, fixedValue2, delay1, delay2, invert);

        // Simulate time
        vm.warp(block.timestamp + 3650);

        (int216 data, uint40 timestamp) = multiHopOracle.getData();
        uint40 nowTimestamp = uint40(block.timestamp);

        assertEq(timestamp, nowTimestamp - delay2);
        assertEq(data, 1); // 1000 * 0.001 = 1
    }

    // @audit Fuzz test to catch edge cases in multi-hop combinations
    function testFuzz_MultiHopOracle(
        int216 fixedValue1,
        int216 fixedValue2,
        uint256 delay1,
        uint256 delay2,
        bool invert1,
        bool invert2
    ) public {
        // Log input values for debugging
        console.log("fixedValue1:");
        console.logInt(int256(fixedValue1));
        console.log("fixedValue2:");
        console.logInt(int256(fixedValue2));
        console.log("delay1:");
        console.logUint(delay1);
        console.log("delay2:");
        console.logUint(delay2);
        console.log("invert1:");
        console.logBool(invert1);
        console.log("invert2:");
        console.logBool(invert2);

        // Add constraints to avoid unrealistic values
        vm.assume(fixedValue1 > 0 && fixedValue1 < 1e18); // Adjusted constraint for fixedValue1
        vm.assume(fixedValue2 > 0 && fixedValue2 < 1e18); // Adjusted constraint for fixedValue2
        vm.assume(delay1 < 1e8); // Adjusted constraint for delay1
        vm.assume(delay2 < 1e8); // Adjusted constraint for delay2

        bool[] memory invert = new bool[](2);
        invert[0] = invert1;
        invert[1] = invert2;

        // Deploy the oracles
        MultiHopOracle deployedOracle = deployOracles(fixedValue1, fixedValue2, delay1, delay2, invert);

        // Jump forward in time by the maximum delay
        uint256 maxDelay = delay1 > delay2 ? delay1 : delay2;
        vm.warp(block.timestamp + maxDelay);

        // Attempt to get data
        (int216 data, uint40 timestamp) = deployedOracle.getData();
        console.log("Result data:");
        console.logInt(int256(data));
        console.log("Result timestamp:");
        console.logUint(timestamp);

        // Basic sanity checks
        assertTrue(data != 0, "Data should not be zero if both values are > 0");
        assertTrue(timestamp <= block.timestamp, "Timestamp should be current or in the past");
    }
}
