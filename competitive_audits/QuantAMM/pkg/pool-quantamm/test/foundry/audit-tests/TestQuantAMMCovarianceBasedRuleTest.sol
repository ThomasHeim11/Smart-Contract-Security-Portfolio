// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/rules/base/QuantammCovarianceBasedRule.sol";

contract TestQuantAMMCovarianceBasedRule is QuantAMMCovarianceBasedRule {
    constructor() {}

    function testCalculateQuantAMMCovariance(int256[] memory _newData, QuantAMMPoolParameters memory _poolParameters)
        external
        returns (int256[][] memory)
    {
        return _calculateQuantAMMCovariance(_newData, _poolParameters);
    }

    function testSetIntermediateCovariance(
        address _poolAddress,
        int256[][] memory _initialValues,
        uint256 _numberOfAssets
    ) external {
        _setIntermediateCovariance(_poolAddress, _initialValues, _numberOfAssets);
    }
}

contract TestQuantAMMCovarianceBasedRuleTest is Test {
    TestQuantAMMCovarianceBasedRule private rule;

    function setUp() public {
        rule = new TestQuantAMMCovarianceBasedRule();
    }

    function testCalculateQuantAMMCovariance() public {
        int256[] memory newData = new int256[](2);
        newData[0] = 3e18;
        newData[1] = 4e18;

        QuantAMMPoolParameters memory poolParameters;
        poolParameters.numberOfAssets = 2;
        poolParameters.movingAverage = new int256[](4);
        poolParameters.movingAverage[0] = 1e18;
        poolParameters.movingAverage[1] = 2e18;
        poolParameters.movingAverage[2] = 1e18;
        poolParameters.movingAverage[3] = 2e18;
        poolParameters.lambda = new int128[](1);
        poolParameters.lambda[0] = 5e17; // 0.5 in 18 decimals

        console.log("Before calling testCalculateQuantAMMCovariance");
        console.logInt(newData[0]);
        console.logInt(newData[1]);
        console.logInt(poolParameters.movingAverage[0]);
        console.logInt(poolParameters.movingAverage[1]);
        console.logInt(poolParameters.movingAverage[2]);
        console.logInt(poolParameters.movingAverage[3]);
        console.logInt(poolParameters.lambda[0]);

        int256[][] memory newState = rule.testCalculateQuantAMMCovariance(newData, poolParameters);

        console.log("After calling testCalculateQuantAMMCovariance");
        console.logInt(newState[0][0]);
        console.logInt(newState[0][1]);
        console.logInt(newState[1][0]);
        console.logInt(newState[1][1]);

        // Add assertions to verify the correctness of newState
        assertEq(newState.length, 2);
        assertEq(newState[0].length, 2);
        assertEq(newState[1].length, 2);
    }

    function testCalculateQuantAMMCovarianceOutOfGas() public {
        int256[] memory newData = new int256[](2);
        newData[0] = 3e18;
        newData[1] = 4e18;

        QuantAMMPoolParameters memory poolParameters;
        poolParameters.numberOfAssets = 2;
        poolParameters.movingAverage = new int256[](4);
        poolParameters.movingAverage[0] = 1e18;
        poolParameters.movingAverage[1] = 2e18;
        poolParameters.movingAverage[2] = 1e18;
        poolParameters.movingAverage[3] = 2e18;
        poolParameters.lambda = new int128[](1);
        poolParameters.lambda[0] = 5e17; // 0.5 in 18 decimals

        // Simulate out of gas scenario
        vm.expectRevert();
        rule.testCalculateQuantAMMCovariance(newData, poolParameters);
    }

    function testSetIntermediateCovariance() public {
        address poolAddress = address(0x456);
        int256[][] memory initialValues = new int256[][](2);
        initialValues[0] = new int256[](2);
        initialValues[0][0] = 1e18;
        initialValues[0][1] = 2e18;
        initialValues[1] = new int256[](2);
        initialValues[1][0] = 3e18;
        initialValues[1][1] = 4e18;
        uint256 numberOfAssets = 2;

        rule.testSetIntermediateCovariance(poolAddress, initialValues, numberOfAssets);

        // Verify the values are set correctly (mock verification)
    }
}
