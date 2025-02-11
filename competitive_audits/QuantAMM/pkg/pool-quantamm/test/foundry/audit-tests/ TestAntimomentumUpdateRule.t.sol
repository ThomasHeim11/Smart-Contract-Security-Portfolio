// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity >=0.8.24;

// import "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import "../../../contracts/rules/AntimomentumUpdateRule.sol";

// contract TestAntiMomentumUpdateRule is AntiMomentumUpdateRule {
//     constructor(address _updateWeightRunner) AntiMomentumUpdateRule(_updateWeightRunner) {}

//     function testGetWeights(
//         int256[] calldata _prevWeights,
//         int256[] memory _data,
//         int256[][] calldata _parameters,
//         QuantAMMPoolParameters memory _poolParameters
//     ) external returns (int256[] memory) {
//         return _getWeights(_prevWeights, _data, _parameters, _poolParameters);
//     }

//     function testRequiresPrevMovingAverage() external pure returns (uint16) {
//         return _requiresPrevMovingAverage();
//     }

//     function testSetInitialIntermediateValues(
//         address _poolAddress,
//         int256[] memory _initialValues,
//         uint256 _numberOfAssets
//     ) external {
//         _setInitialIntermediateValues(_poolAddress, _initialValues, _numberOfAssets);
//     }
// }

// contract TestAntimomentumUpdateRule is Test {
//     TestAntiMomentumUpdateRule private rule;
//     address private updateWeightRunner = address(0x123);

//     function setUp() public {
//         rule = new TestAntiMomentumUpdateRule(updateWeightRunner);
//     }

//     function testGetWeights() public {
//         int256[] memory prevWeights = new int256[](2);
//         prevWeights[0] = 1e18;
//         prevWeights[1] = 2e18;

//         int256[] memory data = new int256[](2);
//         data[0] = 3e18;
//         data[1] = 4e18;

//         int256[][] memory parameters = new int256[][](2);
//         parameters[0] = new int256[](2);
//         parameters[0][0] = 1e18;
//         parameters[0][1] = 2e18;
//         parameters[1] = new int256[](1);
//         parameters[1][0] = 0;

//         QuantAMMPoolParameters memory poolParameters;
//         poolParameters.movingAverage = new int256[](2);
//         poolParameters.movingAverage[0] = 5e18;
//         poolParameters.movingAverage[1] = 6e18;

//         console.log("Before calling testGetWeights");
//         console.logInt(prevWeights[0]);
//         console.logInt(prevWeights[1]);
//         console.logInt(data[0]);
//         console.logInt(data[1]);
//         console.logInt(parameters[0][0]);
//         console.logInt(parameters[0][1]);
//         console.logInt(parameters[1][0]);
//         console.logInt(poolParameters.movingAverage[0]);
//         console.logInt(poolParameters.movingAverage[1]);

//         int256[] memory newWeights = rule.testGetWeights(prevWeights, data, parameters, poolParameters);

//         console.log("After calling testGetWeights");
//         console.logInt(newWeights[0]);
//         console.logInt(newWeights[1]);

//         // Expected values for newWeights
//         int256 expectedWeight0 = calculateExpectedWeight0(prevWeights, data, parameters, poolParameters);
//         int256 expectedWeight1 = calculateExpectedWeight1(prevWeights, data, parameters, poolParameters);

//         console.log("Expected weights");
//         console.logInt(expectedWeight0);
//         console.logInt(expectedWeight1);

//         assertEq(newWeights.length, 2);
//         assertEq(newWeights[0], expectedWeight0);
//         assertEq(newWeights[1], expectedWeight1);
//     }

//     function calculateExpectedWeight0(
//         int256[] memory prevWeights,
//         int256[] memory data,
//         int256[][] memory parameters,
//         QuantAMMPoolParameters memory poolParameters
//     ) internal pure returns (int256) {
//         // Implement the logic to calculate the expected weight for the first asset
//         // Replace the following line with the actual calculation
//         return prevWeights[0] + parameters[0][0] * (data[0] - poolParameters.movingAverage[0]);
//     }

//     function calculateExpectedWeight1(
//         int256[] memory prevWeights,
//         int256[] memory data,
//         int256[][] memory parameters,
//         QuantAMMPoolParameters memory poolParameters
//     ) internal pure returns (int256) {
//         // Implement the logic to calculate the expected weight for the second asset
//         // Replace the following line with the actual calculation
//         return prevWeights[1] + parameters[0][1] * (data[1] - poolParameters.movingAverage[1]);
//     }

//     function testGetWeightsOutOfGas() public {
//         int256[] memory prevWeights = new int256[](2);
//         prevWeights[0] = 1e18;
//         prevWeights[1] = 2e18;

//         int256[] memory data = new int256[](2);
//         data[0] = 3e18;
//         data[1] = 4e18;

//         int256[][] memory parameters = new int256[][](2);
//         parameters[0] = new int256[](2);
//         parameters[0][0] = 1e18;
//         parameters[0][1] = 2e18;
//         parameters[1] = new int256[](1);
//         parameters[1][0] = 0;

//         QuantAMMPoolParameters memory poolParameters;
//         poolParameters.movingAverage = new int256[](2);
//         poolParameters.movingAverage[0] = 5e18;
//         poolParameters.movingAverage[1] = 6e18;

//         // Simulate out of gas scenario
//         vm.expectRevert();
//         rule.testGetWeights(prevWeights, data, parameters, poolParameters);
//     }

//     function testRequiresPrevMovingAverage() public {
//         uint16 result = rule.testRequiresPrevMovingAverage();
//         assertEq(result, 0);
//     }

//     function testSetInitialIntermediateValues() public {
//         address poolAddress = address(0x456);
//         int256[] memory initialValues = new int256[](2);
//         initialValues[0] = 1e18;
//         initialValues[1] = 2e18;
//         uint256 numberOfAssets = 2;

//         rule.testSetInitialIntermediateValues(poolAddress, initialValues, numberOfAssets);

//         // Verify the values are set correctly (mock verification)
//     }

//     function testValidParameters() public {
//         int256[][] memory validParams = new int256[][](2);
//         validParams[0] = new int256[](2);
//         validParams[0][0] = 1e18;
//         validParams[0][1] = 2e18;
//         validParams[1] = new int256[](1);
//         validParams[1][0] = 0;

//         bool isValid = rule.validParameters(validParams);
//         assertTrue(isValid);

//         int256[][] memory invalidParams = new int256[][](2);
//         invalidParams[0] = new int256[](2);
//         invalidParams[0][0] = -1e18;
//         invalidParams[0][1] = 2e18;
//         invalidParams[1] = new int256[](1);
//         invalidParams[1][0] = 0;

//         bool isInvalid = rule.validParameters(invalidParams);
//         assertFalse(isInvalid);
//     }
// }
