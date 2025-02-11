// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity >=0.8.24;

// import "forge-std/Test.sol";
// import "../../../contracts/rules/base/QuantammCovarianceBasedRule.sol";

// contract ConcreteQuantAMMCovarianceBasedRule is QuantAMMCovarianceBasedRule {
//     function calculateQuantAMMCovariance(int256[] memory _newData, QuantAMMPoolParameters memory _poolParameters)
//         public
//         returns (int256[][] memory)
//     {
//         return _calculateQuantAMMCovariance(_newData, _poolParameters);
//     }

//     function setIntermediateCovariance(address _poolAddress, int256[][] memory _initialValues, uint256 _numberOfAssets)
//         public
//     {
//         _setIntermediateCovariance(_poolAddress, _initialValues, _numberOfAssets);
//     }
// }

// contract TestQuantAMMCovarianceBasedRule is Test {
//     ConcreteQuantAMMCovarianceBasedRule rule;

//     function setUp() public {
//         rule = new ConcreteQuantAMMCovarianceBasedRule();
//     }

//     function testCalculateQuantAMMCovariance() public {
//         int256[] memory newData = new int256[](2);
//         newData[0] = 1 * 1e18;
//         newData[1] = 2 * 1e18;

//         QuantAMMPoolParameters memory poolParameters;
//         poolParameters.numberOfAssets = 2;
//         poolParameters.movingAverage = new int256[](4);
//         poolParameters.movingAverage[0] = 1 * 1e18;
//         poolParameters.movingAverage[1] = 2 * 1e18;
//         poolParameters.movingAverage[2] = 1 * 1e18;
//         poolParameters.movingAverage[3] = 2 * 1e18;
//         poolParameters.lambda = new int256[](1);
//         poolParameters.lambda[0] = 1 * 1e18;

//         int256[][] memory result = rule.calculateQuantAMMCovariance(newData, poolParameters);

//         assertEq(result.length, 2);
//         assertEq(result[0][0], 0);
//     }

//     function testSetIntermediateCovariance() public {
//         int256[][] memory initialValues = new int256[][](2);
//         initialValues[0] = new int256[](2);
//         initialValues[1] = new int256[](2);
//         initialValues[0][0] = 1 * 1e18;
//         initialValues[0][1] = 2 * 1e18;
//         initialValues[1][0] = 3 * 1e18;
//         initialValues[1][1] = 4 * 1e18;

//         rule.setIntermediateCovariance(address(this), initialValues, 2);

//         // Add assertions to verify the state
//     }
// }
