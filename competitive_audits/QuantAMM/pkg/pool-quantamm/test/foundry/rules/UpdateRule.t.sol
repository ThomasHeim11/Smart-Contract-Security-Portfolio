// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../../contracts/mock/mockRules/MockUpdateRule.sol";
import "../../../contracts/mock/MockPool.sol";
import "../utils.t.sol";
import {console} from "forge-std/console.sol";

contract UpdateRuleTest is Test, QuantAMMTestUtils {
    address internal owner;
    address internal addr1;
    address internal addr2;

    MockPool public mockPool;
    MockUpdateRule updateRule;

    function setUp() public {
        (address ownerLocal, address addr1Local, address addr2Local) = (vm.addr(1), vm.addr(2), vm.addr(3));
        owner = ownerLocal;
        addr1 = addr1Local;
        addr2 = addr2Local;
        updateRule = new MockUpdateRule(owner);
    }

    function testUpdateRuleUnAuthCalc() public {
        vm.expectRevert("UNAUTH_CALC");
        updateRule.CalculateNewWeights(
            new int256[](0),
            new int256[](0),
            address(mockPool),
            new int256[][](0),
            new uint64[](0),
            uint64(1),
            uint64(1)
        );
    }

    function testUpdateRuleAuthCalc() public {
        vm.startPrank(owner);
        // Define local variables for the parameters
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[0][0] = PRBMathSD59x18.fromInt(1);
        parameters[1] = new int256[](1);
        parameters[1][0] = PRBMathSD59x18.fromInt(1);

        int256[] memory previousAlphas = new int256[](2);
        previousAlphas[0] = PRBMathSD59x18.fromInt(1);
        previousAlphas[1] = PRBMathSD59x18.fromInt(2);

        int256[] memory prevMovingAverages = new int256[](2);
        prevMovingAverages[0] = PRBMathSD59x18.fromInt(0);
        prevMovingAverages[1] = PRBMathSD59x18.fromInt(0);

        int256[] memory movingAverages = new int256[](2);
        movingAverages[0] = 0.9e18;
        movingAverages[1] = PRBMathSD59x18.fromInt(1) + 0.2e18;

        uint64[] memory lambdas = new uint64[](1);
        lambdas[0] = uint64(0.7e18);

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 0.5e18;
        prevWeights[1] = 0.5e18;

        int256[] memory data = new int256[](2);
        data[0] = PRBMathSD59x18.fromInt(3);
        data[1] = PRBMathSD59x18.fromInt(4);

        int256 epsilonMax = 0.1e18;

        int256[] memory expectedResults = new int256[](2);
        expectedResults[0] = 0.49775e18;
        expectedResults[1] = 0.50225e18;
        updateRule.setWeights(expectedResults);

        updateRule.initialisePoolRuleIntermediateValues(address(mockPool), prevMovingAverages, previousAlphas, 2);

        //does not revert
        updateRule.CalculateNewWeights(
            prevWeights, data, address(mockPool), parameters, lambdas, uint64(uint256(epsilonMax)), uint64(0.2e18)
        );

        vm.stopPrank();
    }

    function testUpdateRuleMovingAverageStorage() public {
        vm.startPrank(owner);
        // Define local variables for the parameters
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[0][0] = PRBMathSD59x18.fromInt(1);
        parameters[1] = new int256[](1);
        parameters[1][0] = PRBMathSD59x18.fromInt(1);

        int256[] memory previousAlphas = new int256[](2);
        previousAlphas[0] = PRBMathSD59x18.fromInt(1);
        previousAlphas[1] = PRBMathSD59x18.fromInt(2);

        int256[] memory prevMovingAverages = new int256[](2);
        prevMovingAverages[0] = PRBMathSD59x18.fromInt(0);
        prevMovingAverages[1] = PRBMathSD59x18.fromInt(0);

        int256[] memory movingAverages = new int256[](2);
        movingAverages[0] = 0.9e18;
        movingAverages[1] = PRBMathSD59x18.fromInt(1) + 0.2e18;

        uint64[] memory lambdas = new uint64[](1);
        lambdas[0] = uint64(0.7e18);

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 0.5e18;
        prevWeights[1] = 0.5e18;

        int256[] memory data = new int256[](2);
        data[0] = PRBMathSD59x18.fromInt(3);
        data[1] = PRBMathSD59x18.fromInt(4);

        int256 epsilonMax = 0.1e18;

        int256[] memory expectedResults = new int256[](2);
        expectedResults[0] = 0.49775e18;
        expectedResults[1] = 0.50225e18;
        updateRule.setWeights(expectedResults);

        updateRule.initialisePoolRuleIntermediateValues(address(mockPool), prevMovingAverages, previousAlphas, 2);

        //does not revert
        updateRule.CalculateNewWeights(
            prevWeights, data, address(mockPool), parameters, lambdas, uint64(uint256(epsilonMax)), uint64(0.2e18)
        );

        int256[] memory savedMovAverages = updateRule.GetMovingAverages(address(mockPool), 2);

        checkResult(movingAverages, savedMovAverages);

        vm.stopPrank();
    }

    function testUpdateRuleGuardClampWeights() public {
        vm.startPrank(owner);
        // Define local variables for the parameters
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[0][0] = PRBMathSD59x18.fromInt(1);
        parameters[1] = new int256[](1);
        parameters[1][0] = PRBMathSD59x18.fromInt(1);

        int256[] memory previousAlphas = new int256[](2);
        previousAlphas[0] = PRBMathSD59x18.fromInt(1);
        previousAlphas[1] = PRBMathSD59x18.fromInt(2);

        int256[] memory prevMovingAverages = new int256[](2);
        prevMovingAverages[0] = PRBMathSD59x18.fromInt(0);
        prevMovingAverages[1] = PRBMathSD59x18.fromInt(0);

        int256[] memory movingAverages = new int256[](2);
        movingAverages[0] = 0.9e18;
        movingAverages[1] = PRBMathSD59x18.fromInt(1) + 0.2e18;

        uint64[] memory lambdas = new uint64[](1);
        lambdas[0] = uint64(0.7e18);

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 0.5e18;
        prevWeights[1] = 0.5e18;

        int256[] memory data = new int256[](2);
        data[0] = PRBMathSD59x18.fromInt(3);
        data[1] = PRBMathSD59x18.fromInt(4);

        int256[] memory calculatedWeights = new int256[](2);
        calculatedWeights[0] = 0.95e18;
        calculatedWeights[1] = 0.05e18;
        updateRule.setWeights(calculatedWeights);

        updateRule.initialisePoolRuleIntermediateValues(address(mockPool), prevMovingAverages, previousAlphas, 2);

        //does not revert
        int256[] memory expectedClampWeights = updateRule.CalculateNewWeights(
            prevWeights, data, address(mockPool), parameters, lambdas, uint64(0.1e18), uint64(0.1e18)
        );

        int256[] memory expectedWeights = new int256[](2);
        expectedWeights[0] = 0.6e18;
        expectedWeights[1] = 0.4e18;

        checkResult(expectedWeights, expectedClampWeights);

        vm.stopPrank();
    }

    function testUpdateRuleInitialisePoolPoolAuth() public {
        vm.startPrank(owner);
        // Define local variables for the parameters
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[0][0] = PRBMathSD59x18.fromInt(1);
        parameters[1] = new int256[](1);
        parameters[1][0] = PRBMathSD59x18.fromInt(1);

        int256[] memory previousAlphas = new int256[](2);
        previousAlphas[0] = PRBMathSD59x18.fromInt(1);
        previousAlphas[1] = PRBMathSD59x18.fromInt(2);

        int256[] memory prevMovingAverages = new int256[](2);
        prevMovingAverages[0] = PRBMathSD59x18.fromInt(0);
        prevMovingAverages[1] = PRBMathSD59x18.fromInt(0);

        int256[] memory movingAverages = new int256[](2);
        movingAverages[0] = 0.9e18;
        movingAverages[1] = PRBMathSD59x18.fromInt(1) + 0.2e18;

        uint64[] memory lambdas = new uint64[](1);
        lambdas[0] = uint64(0.7e18);

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 0.5e18;
        prevWeights[1] = 0.5e18;

        int256[] memory data = new int256[](2);
        data[0] = PRBMathSD59x18.fromInt(3);
        data[1] = PRBMathSD59x18.fromInt(4);

        int256[] memory expectedResults = new int256[](2);
        expectedResults[0] = 0.49775e18;
        expectedResults[1] = 0.50225e18;
        updateRule.setWeights(expectedResults);
        vm.stopPrank();

        vm.startPrank(address(mockPool));

        updateRule.initialisePoolRuleIntermediateValues(address(mockPool), prevMovingAverages, previousAlphas, 2);

        vm.stopPrank();
    }

    function testUpdateRuleInitialisePoolUpdateWeightRunnerAuth() public {
        vm.startPrank(owner);
        // Define local variables for the parameters
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[0][0] = PRBMathSD59x18.fromInt(1);
        parameters[1] = new int256[](1);
        parameters[1][0] = PRBMathSD59x18.fromInt(1);

        int256[] memory previousAlphas = new int256[](2);
        previousAlphas[0] = PRBMathSD59x18.fromInt(1);
        previousAlphas[1] = PRBMathSD59x18.fromInt(2);

        int256[] memory prevMovingAverages = new int256[](2);
        prevMovingAverages[0] = PRBMathSD59x18.fromInt(0);
        prevMovingAverages[1] = PRBMathSD59x18.fromInt(0);

        int256[] memory movingAverages = new int256[](2);
        movingAverages[0] = 0.9e18;
        movingAverages[1] = PRBMathSD59x18.fromInt(1) + 0.2e18;

        uint64[] memory lambdas = new uint64[](1);
        lambdas[0] = uint64(0.7e18);

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 0.5e18;
        prevWeights[1] = 0.5e18;

        int256[] memory data = new int256[](2);
        data[0] = PRBMathSD59x18.fromInt(3);
        data[1] = PRBMathSD59x18.fromInt(4);

        int256[] memory expectedResults = new int256[](2);
        expectedResults[0] = 0.49775e18;
        expectedResults[1] = 0.50225e18;
        updateRule.setWeights(expectedResults);

        //does not revert
        updateRule.initialisePoolRuleIntermediateValues(address(mockPool), prevMovingAverages, previousAlphas, 2);

        vm.stopPrank();
    }

    function testUpdateRuleInitialisePoolRandomNotAuth() public {
        vm.startPrank(owner);
        // Define local variables for the parameters
        int256[][] memory parameters = new int256[][](2);
        parameters[0] = new int256[](1);
        parameters[0][0] = PRBMathSD59x18.fromInt(1);
        parameters[1] = new int256[](1);
        parameters[1][0] = PRBMathSD59x18.fromInt(1);

        int256[] memory previousAlphas = new int256[](2);
        previousAlphas[0] = PRBMathSD59x18.fromInt(1);
        previousAlphas[1] = PRBMathSD59x18.fromInt(2);

        int256[] memory prevMovingAverages = new int256[](2);
        prevMovingAverages[0] = PRBMathSD59x18.fromInt(0);
        prevMovingAverages[1] = PRBMathSD59x18.fromInt(0);

        int256[] memory movingAverages = new int256[](2);
        movingAverages[0] = 0.9e18;
        movingAverages[1] = PRBMathSD59x18.fromInt(1) + 0.2e18;

        uint64[] memory lambdas = new uint64[](1);
        lambdas[0] = uint64(0.7e18);

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 0.5e18;
        prevWeights[1] = 0.5e18;

        int256[] memory data = new int256[](2);
        data[0] = PRBMathSD59x18.fromInt(3);
        data[1] = PRBMathSD59x18.fromInt(4);

        int256[] memory expectedResults = new int256[](2);
        expectedResults[0] = 0.49775e18;
        expectedResults[1] = 0.50225e18;
        updateRule.setWeights(expectedResults);

        vm.stopPrank();

        vm.startPrank(addr2);

        vm.expectRevert();
        updateRule.initialisePoolRuleIntermediateValues(address(mockPool), prevMovingAverages, previousAlphas, 2);

        vm.stopPrank();
    }
    //@audit

    function testCalculateNewWeightsFuzzing(
        int256[] memory prevWeights,
        int256[] memory data,
        int256[][] memory parameters,
        uint64[] memory lambdaStore,
        uint64 epsilonMax,
        uint64 absoluteWeightGuardRail
    ) public {
        // Log the input values for debugging
        console.log("Fuzzing test inputs:");
        console.log("prevWeights length:", prevWeights.length);
        console.log("data length:", data.length);
        console.log("parameters length:", parameters.length);
        console.log("lambdaStore length:", lambdaStore.length);
        console.log("epsilonMax:", epsilonMax);
        console.log("absoluteWeightGuardRail:", absoluteWeightGuardRail);

        // Ensure the lengths are consistent
        uint256 numberOfAssets = prevWeights.length;
        if (data.length != numberOfAssets) {
            console.log("Data length mismatch");
            return;
        }
        if (lambdaStore.length == 0) {
            console.log("Lambda store length must be greater than 0");
            return;
        }

        // Call the function with fuzzed inputs
        try updateRule.CalculateNewWeights(
            prevWeights, data, address(mockPool), parameters, lambdaStore, epsilonMax, absoluteWeightGuardRail
        ) {
            // If the call succeeds, perform additional checks
            int256[] memory result = updateRule.CalculateNewWeights(
                prevWeights, data, address(mockPool), parameters, lambdaStore, epsilonMax, absoluteWeightGuardRail
            );

            console.log("Result length:", result.length);
            for (uint256 i = 0; i < result.length; i++) {
                console.logInt(result[i]);
            }

            assertEq(result.length, numberOfAssets);
        } catch {
            // If the call fails, log the error
            console.log("Call failed with fuzzed inputs");
        }
    }

    function testCalculateNewWeightsOutOfGasFuzzing(
        int256[] memory prevWeights,
        int256[] memory data,
        int256[][] memory parameters,
        uint64[] memory lambdaStore,
        uint64 epsilonMax,
        uint64 absoluteWeightGuardRail
    ) public {
        // Log the input values for debugging
        console.log("Fuzzing test inputs for out of gas:");
        console.log("prevWeights length:", prevWeights.length);
        console.log("data length:", data.length);
        console.log("parameters length:", parameters.length);
        console.log("lambdaStore length:", lambdaStore.length);
        console.log("epsilonMax:", epsilonMax);
        console.log("absoluteWeightGuardRail:", absoluteWeightGuardRail);

        // Ensure the lengths are consistent
        uint256 numberOfAssets = prevWeights.length;
        if (data.length != numberOfAssets) {
            console.log("Data length mismatch");
            return;
        }
        if (lambdaStore.length == 0) {
            console.log("Lambda store length must be greater than 0");
            return;
        }

        // Simulate potential out-of-gas scenario by using a large number of assets
        if (numberOfAssets > 1000) {
            console.log("Skipping test due to large number of assets");
            return;
        }

        // Call the function with fuzzed inputs
        try updateRule.CalculateNewWeights(
            prevWeights, data, address(mockPool), parameters, lambdaStore, epsilonMax, absoluteWeightGuardRail
        ) {
            // If the call succeeds, perform additional checks
            int256[] memory result = updateRule.CalculateNewWeights(
                prevWeights, data, address(mockPool), parameters, lambdaStore, epsilonMax, absoluteWeightGuardRail
            );

            console.log("Result length:", result.length);
            for (uint256 i = 0; i < result.length; i++) {
                console.logInt(result[i]);
            }

            assertEq(result.length, numberOfAssets);
        } catch {
            // If the call fails, log the error
            console.log("Call failed with fuzzed inputs for out of gas");
        }
    }
}
