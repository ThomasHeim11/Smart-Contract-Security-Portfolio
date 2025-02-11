// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/rules/MomentumUpdateRule.sol";

contract ConcreteMomentumUpdateRule is MomentumUpdateRule {
    constructor(address _updateWeightRunner) MomentumUpdateRule(_updateWeightRunner) {}

    function getWeights(
        int256[] calldata _prevWeights,
        int256[] memory _data,
        int256[][] calldata _parameters,
        QuantAMMPoolParameters memory _poolParameters
    ) public returns (int256[] memory) {
        return _getWeights(_prevWeights, _data, _parameters, _poolParameters);
    }

    function setInitialIntermediateValues(address _poolAddress, int256[] memory _initialValues, uint256 _numberOfAssets)
        public
    {
        _setInitialIntermediateValues(_poolAddress, _initialValues, _numberOfAssets);
    }

    function getGradient(address _poolAddress) public view returns (int256[] memory) {
        return intermediateGradientStates[_poolAddress];
    }
}

contract TestMomentumUpdateRule is Test {
    ConcreteMomentumUpdateRule updateRule;

    function setUp() public {
        updateRule = new ConcreteMomentumUpdateRule(address(this));
    }

    function testGetWeights() public {
        int256[] memory data = new int256[](2);
        data[0] = 2 * 1e18;
        data[1] = 3 * 1e18;

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 1 * 1e18;
        prevWeights[1] = 2 * 1e18;

        int256[] memory movingAverage = new int256[](2);
        movingAverage[0] = 1 * 1e18;
        movingAverage[1] = 2 * 1e18;

        int128[] memory lambda = new int128[](1);
        lambda[0] = 5 * 1e17; // 0.5 in SD59x18

        QuantAMMPoolParameters memory poolParameters = QuantAMMPoolParameters({
            movingAverage: movingAverage,
            lambda: lambda,
            numberOfAssets: 2,
            pool: address(this)
        });

        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[1] = new int256[](1);

        parameters[0][0] = 1 * 1e18; // kappa
        parameters[1][0] = 0; // use moving average

        // Set initial intermediate gradient state
        int256[] memory initialGradientState = new int256[](2);
        initialGradientState[0] = 1 * 1e18;
        initialGradientState[1] = 2 * 1e18;
        updateRule.setInitialIntermediateValues(address(this), initialGradientState, 2);

        int256[] memory result = updateRule.getWeights(prevWeights, data, parameters, poolParameters);

        console.log("Result length:", result.length);
        console.logInt(result[0]);
        console.logInt(result[1]);

        assertEq(result.length, 2);
    }

    function testSetInitialIntermediateValues() public {
        address poolAddress = address(0x123);
        int256[] memory initialValues = new int256[](2);
        initialValues[0] = 1 * 1e18;
        initialValues[1] = 2 * 1e18;

        uint256 numberOfAssets = 2;

        updateRule.setInitialIntermediateValues(poolAddress, initialValues, numberOfAssets);

        // Verify the state
        int256[] memory storedValues = updateRule.getGradient(poolAddress);
        console.log("Stored Values length:", storedValues.length);
        console.logInt(storedValues[0]);
        console.logInt(storedValues[1]);

        assertEq(storedValues.length, 2);
        assertEq(storedValues[0], 1 * 1e18);
        assertEq(storedValues[1], 2 * 1e18);
    }

    function testValidParameters() public {
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[1] = new int256[](1);

        parameters[0][0] = 1 * 1e18; // kappa
        parameters[1][0] = 0; // use moving average

        bool isValid = updateRule.validParameters(parameters);

        console.log("Parameters are valid:", isValid);

        assertTrue(isValid);
    }

    function testGetWeightsOutOfGas() public {
        uint256 numberOfAssets = 1000; // Large number to simulate potential out-of-gas scenario
        int256[] memory data = new int256[](numberOfAssets);
        int256[] memory prevWeights = new int256[](numberOfAssets);
        int256[] memory movingAverage = new int256[](numberOfAssets * 2);
        int128[] memory lambda = new int128[](1);
        lambda[0] = 5 * 1e17; // 0.5 in SD59x18

        for (uint256 i = 0; i < numberOfAssets; i++) {
            data[i] = int256((i + 1) * 1e18);
            prevWeights[i] = int256((i + 1) * 1e18);
            movingAverage[i] = int256((i + 1) * 1e18);
            movingAverage[numberOfAssets + i] = int256((i + 1) * 1e18);
        }

        QuantAMMPoolParameters memory poolParameters = QuantAMMPoolParameters({
            movingAverage: movingAverage,
            lambda: lambda,
            numberOfAssets: numberOfAssets,
            pool: address(this)
        });

        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](numberOfAssets);
        parameters[1] = new int256[](1);

        for (uint256 i = 0; i < numberOfAssets; i++) {
            parameters[0][i] = 1 * 1e18; // kappa
        }
        parameters[1][0] = 0; // use moving average

        try updateRule.getWeights(prevWeights, data, parameters, poolParameters) {
            console.log("Out of gas test passed");
        } catch Error(string memory reason) {
            console.log("Out of gas test failed with reason:", reason);
        } catch (bytes memory) {
            console.log("Out of gas test failed with unknown reason");
        }
    }
}
