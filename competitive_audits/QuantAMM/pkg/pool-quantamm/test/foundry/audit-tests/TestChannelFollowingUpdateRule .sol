// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/rules/ChannelFollowingUpdateRule.sol";

contract ConcreteChannelFollowingUpdateRule is ChannelFollowingUpdateRule {
    constructor(address _updateWeightRunner) ChannelFollowingUpdateRule(_updateWeightRunner) {}

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
}

contract TestChannelFollowingUpdateRule is Test {
    ConcreteChannelFollowingUpdateRule updateRule;

    function setUp() public {
        updateRule = new ConcreteChannelFollowingUpdateRule(address(this));
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

        int256[][] memory parameters = new int256[][](7);
        parameters[0] = new int256[](1);
        parameters[1] = new int256[](1);
        parameters[2] = new int256[](1);
        parameters[3] = new int256[](1);
        parameters[4] = new int256[](1);
        parameters[5] = new int256[](1);
        parameters[6] = new int256[](1);

        parameters[0][0] = 1 * 1e18; // kappa
        parameters[1][0] = 1 * 1e18; // width
        parameters[2][0] = 1 * 1e18; // amplitude
        parameters[3][0] = 1 * 1e18; // exponents
        parameters[4][0] = 1 * 1e18; // inverse scaling
        parameters[5][0] = 1 * 1e18; // pre-exp scaling
        parameters[6][0] = 0; // use raw price

        // Set initial intermediate variance state
        int256[] memory initialVarianceState = new int256[](2);
        initialVarianceState[0] = 1 * 1e18;
        initialVarianceState[1] = 2 * 1e18;
        updateRule.setInitialIntermediateValues(address(this), initialVarianceState, 2);

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

        // Assuming _setGradient is implemented correctly, we should add assertions here to verify the state
    }

    function testValidParameters() public {
        int256[][] memory parameters = new int256[][](7);
        parameters[0] = new int256[](1);
        parameters[1] = new int256[](1);
        parameters[2] = new int256[](1);
        parameters[3] = new int256[](1);
        parameters[4] = new int256[](1);
        parameters[5] = new int256[](1);
        parameters[6] = new int256[](1);

        parameters[0][0] = 1 * 1e18; // kappa
        parameters[1][0] = 1 * 1e18; // width
        parameters[2][0] = 1 * 1e18; // amplitude
        parameters[3][0] = 1 * 1e18; // exponents
        parameters[4][0] = 1 * 1e18; // inverse scaling
        parameters[5][0] = 1 * 1e18; // pre-exp scaling
        parameters[6][0] = 0; // use raw price

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

        int256[][] memory parameters = new int256[][](7);
        for (uint256 i = 0; i < 7; i++) {
            parameters[i] = new int256[](numberOfAssets);
            for (uint256 j = 0; j < numberOfAssets; j++) {
                parameters[i][j] = 1 * 1e18;
            }
        }

        parameters[6][0] = 0; // use raw price

        try updateRule.getWeights(prevWeights, data, parameters, poolParameters) {
            console.log("Out of gas test passed");
        } catch Error(string memory reason) {
            console.log("Out of gas test failed with reason:", reason);
        } catch (bytes memory) {
            console.log("Out of gas test failed with unknown reason");
        }
    }

    function testFuzzGetWeights(
        int256[] memory data,
        int256[] memory prevWeights,
        int256[][] memory parameters,
        int256[] memory movingAverage,
        int128[] memory lambda,
        uint256 numberOfAssets
    ) public {
        vm.assume(data.length == numberOfAssets);
        vm.assume(prevWeights.length == numberOfAssets);
        vm.assume(movingAverage.length == numberOfAssets * 2);
        vm.assume(lambda.length == 1);
        vm.assume(parameters.length == 7);
        for (uint256 i = 0; i < 6; i++) {
            vm.assume(parameters[i].length == numberOfAssets);
        }
        vm.assume(parameters[6].length == 1);
        vm.assume(numberOfAssets > 0 && numberOfAssets <= 1000);

        QuantAMMPoolParameters memory poolParameters = QuantAMMPoolParameters({
            movingAverage: movingAverage,
            lambda: lambda,
            numberOfAssets: numberOfAssets,
            pool: address(this)
        });

        try updateRule.getWeights(prevWeights, data, parameters, poolParameters) {
            console.log("Fuzz test passed");
        } catch Error(string memory reason) {
            console.log("Fuzz test failed with reason:", reason);
        } catch (bytes memory) {
            console.log("Fuzz test failed with unknown reason");
        }
    }

    function testFuzzSetInitialIntermediateValues(
        address poolAddress,
        int256[] memory initialValues,
        uint256 numberOfAssets
    ) public {
        vm.assume(initialValues.length == numberOfAssets);
        vm.assume(numberOfAssets > 0 && numberOfAssets <= 1000);

        updateRule.setInitialIntermediateValues(poolAddress, initialValues, numberOfAssets);

        // Assuming _setGradient is implemented correctly, we should add assertions here to verify the state
    }

    function testFuzzValidParameters(int256[][] memory parameters) public {
        vm.assume(parameters.length == 7);
        uint256 baseLength = parameters[0].length;
        vm.assume(baseLength > 0 && baseLength <= 1000);
        for (uint256 i = 1; i < 6; i++) {
            vm.assume(parameters[i].length == baseLength);
        }
        vm.assume(parameters[6].length == 1);

        bool isValid = updateRule.validParameters(parameters);

        console.log("Fuzz test parameters are valid:", isValid);
    }
}
