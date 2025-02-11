// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import "../pool-quantamm/OracleWrapper.sol";

contract MockOracleWrapper is OracleWrapper {
    int216 private mockData;
    uint40 private mockTimestamp;

    function setMockData(int216 data, uint40 timestamp) external {
        mockData = data;
        mockTimestamp = timestamp;
    }

    function _getData() internal view override returns (int216 data, uint40 timestamp) {
        return (mockData, mockTimestamp);
    }
}

contract OracleWrapperTest is Test {
    MockOracleWrapper private oracleWrapper;

    function setUp() public {
        oracleWrapper = new MockOracleWrapper();
    }

    function testGetDataValidTimestamp() public {
        int216 expectedData = 123456789;
        uint40 expectedTimestamp = uint40(block.timestamp);

        oracleWrapper.setMockData(expectedData, expectedTimestamp);

        (int216 data, uint40 timestamp) = oracleWrapper.getData();

        assertEq(data, expectedData, "Data should match the expected value");
        assertEq(timestamp, expectedTimestamp, "Timestamp should match the expected value");
    }

    function testGetDataInvalidTimestamp() public {
        int216 expectedData = 123456789;
        uint40 invalidTimestamp = 0;

        oracleWrapper.setMockData(expectedData, invalidTimestamp);

        vm.expectRevert("INVORCLVAL");
        oracleWrapper.getData();
    }
}
