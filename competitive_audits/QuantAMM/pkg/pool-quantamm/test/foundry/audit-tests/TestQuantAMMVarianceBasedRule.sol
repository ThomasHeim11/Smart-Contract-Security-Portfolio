// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/rules/base/QuantAMMVarianceBasedRule.sol";

contract ConcreteQuantAMMVarianceBasedRule is QuantAMMVarianceBasedRule {
    function calculateQuantAMMVariance(int256[] memory _newData, QuantAMMPoolParameters memory _poolParameters)
        public
        returns (int256[] memory)
    {
        return _calculateQuantAMMVariance(_newData, _poolParameters);
    }

    function setIntermediateVariance(address _poolAddress, int256[] memory _initialValues, uint256 _numberOfAssets)
        public
    {
        _setIntermediateVariance(_poolAddress, _initialValues, _numberOfAssets);
    }

    function getIntermediateVarianceState(address _poolAddress) public view returns (int256[] memory) {
        return intermediateVarianceStates[_poolAddress];
    }

    function unpackIntermediateVarianceState(int256[] memory packedState, uint256 numberOfAssets)
        public
        pure
        returns (int256[] memory)
    {
        return _quantAMMUnpack128Array(packedState, numberOfAssets);
    }
}

contract TestQuantAMMVarianceBasedRule is Test {
    ConcreteQuantAMMVarianceBasedRule varianceRule;

    function setUp() public {
        varianceRule = new ConcreteQuantAMMVarianceBasedRule();
    }

    function testCalculateQuantAMMVariance() public {
        int256[] memory newData = new int256[](2);
        newData[0] = 2 * 1e18;
        newData[1] = 3 * 1e18;

        int256[] memory movingAverage = new int256[](4);
        movingAverage[0] = 1 * 1e18;
        movingAverage[1] = 2 * 1e18;
        movingAverage[2] = 1 * 1e18;
        movingAverage[3] = 2 * 1e18;

        int128[] memory lambda = new int128[](1);
        lambda[0] = 5 * 1e17; // 0.5 in SD59x18

        QuantAMMPoolParameters memory poolParameters = QuantAMMPoolParameters({
            movingAverage: movingAverage,
            lambda: lambda,
            numberOfAssets: 2,
            pool: address(this)
        });

        // Set initial intermediate variance state
        int256[] memory initialVarianceState = new int256[](2);
        initialVarianceState[0] = 1 * 1e18;
        initialVarianceState[1] = 2 * 1e18;
        varianceRule.setIntermediateVariance(address(this), initialVarianceState, 2);

        int256[] memory result = varianceRule.calculateQuantAMMVariance(newData, poolParameters);

        console.log("Result length:", result.length);
        console.logInt(result[0]);
        console.logInt(result[1]);

        assertEq(result.length, 2);
    }

    function testSetIntermediateVariance() public {
        address poolAddress = address(0x123);
        int256[] memory initialValues = new int256[](2);
        initialValues[0] = 1 * 1e18;
        initialValues[1] = 2 * 1e18;

        uint256 numberOfAssets = 2;

        varianceRule.setIntermediateVariance(poolAddress, initialValues, numberOfAssets);

        int256[] memory storedVarianceState = varianceRule.getIntermediateVarianceState(poolAddress);
        int256[] memory unpackedVarianceState =
            varianceRule.unpackIntermediateVarianceState(storedVarianceState, numberOfAssets);

        console.log("Unpacked Variance State length:", unpackedVarianceState.length);
        console.logInt(unpackedVarianceState[0]);
        console.logInt(unpackedVarianceState[1]);

        assertEq(unpackedVarianceState.length, 2);
        assertEq(unpackedVarianceState[0], 1 * 1e18);
        assertEq(unpackedVarianceState[1], 2 * 1e18);
    }

    function testCalculateQuantAMMVarianceLargeData() public {
        uint256 numberOfAssets = 100;
        int256[] memory newData = new int256[](numberOfAssets);
        int256[] memory movingAverage = new int256[](numberOfAssets * 2);
        int128[] memory lambda = new int128[](1);
        lambda[0] = 5 * 1e17; // 0.5 in SD59x18

        for (uint256 i = 0; i < numberOfAssets; i++) {
            newData[i] = int256((i + 1) * 1e18);
            movingAverage[i] = int256((i + 1) * 1e18);
            movingAverage[numberOfAssets + i] = int256((i + 1) * 1e18);
        }

        QuantAMMPoolParameters memory poolParameters = QuantAMMPoolParameters({
            movingAverage: movingAverage,
            lambda: lambda,
            numberOfAssets: numberOfAssets,
            pool: address(this)
        });

        // Set initial intermediate variance state
        int256[] memory initialVarianceState = new int256[](numberOfAssets);
        for (uint256 i = 0; i < numberOfAssets; i++) {
            initialVarianceState[i] = int256((i + 1) * 1e18);
        }
        varianceRule.setIntermediateVariance(address(this), initialVarianceState, numberOfAssets);

        int256[] memory result = varianceRule.calculateQuantAMMVariance(newData, poolParameters);

        console.log("Result length:", result.length);
        for (uint256 i = 0; i < numberOfAssets; i++) {
            console.logInt(result[i]);
        }

        assertEq(result.length, numberOfAssets);
    }

    function testSetIntermediateVarianceLargeData() public {
        address poolAddress = address(0x123);
        uint256 numberOfAssets = 100;
        int256[] memory initialValues = new int256[](numberOfAssets);

        for (uint256 i = 0; i < numberOfAssets; i++) {
            initialValues[i] = int256((i + 1) * 1e18);
        }

        varianceRule.setIntermediateVariance(poolAddress, initialValues, numberOfAssets);

        int256[] memory storedVarianceState = varianceRule.getIntermediateVarianceState(poolAddress);
        int256[] memory unpackedVarianceState =
            varianceRule.unpackIntermediateVarianceState(storedVarianceState, numberOfAssets);

        console.log("Unpacked Variance State length:", unpackedVarianceState.length);
        for (uint256 i = 0; i < numberOfAssets; i++) {
            console.logInt(unpackedVarianceState[i]);
        }

        assertEq(unpackedVarianceState.length, numberOfAssets);
    }
}
