// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/rules/base/QuantAMMMathMovingAverage.sol";

contract ConcreteQuantAMMMathMovingAverage is QuantAMMMathMovingAverage {
    function calculateQuantAMMMovingAverage(
        int256[] memory _prevMovingAverage,
        int256[] memory _newData,
        int128[] memory _lambda,
        uint256 _numberOfAssets
    ) public pure returns (int256[] memory) {
        return _calculateQuantAMMMovingAverage(_prevMovingAverage, _newData, _lambda, _numberOfAssets);
    }

    function setInitialMovingAverages(
        address _poolAddress,
        int256[] memory _initialMovingAverages,
        uint256 _numberOfAssets
    ) public {
        _setInitialMovingAverages(_poolAddress, _initialMovingAverages, _numberOfAssets);
    }

    function getMovingAverages(address _poolAddress) public view returns (int256[] memory) {
        return movingAverages[_poolAddress];
    }

    function unpackMovingAverages(int256[] memory packedAverages, uint256 numberOfAssets)
        public
        pure
        returns (int256[] memory)
    {
        return _quantAMMUnpack128Array(packedAverages, numberOfAssets);
    }
}

contract TestQuantAMMMathMovingAverage is Test {
    ConcreteQuantAMMMathMovingAverage movingAverage;

    function setUp() public {
        movingAverage = new ConcreteQuantAMMMathMovingAverage();
    }

    function testCalculateQuantAMMMovingAverage() public {
        int256[] memory prevMovingAverage = new int256[](2);
        prevMovingAverage[0] = 1 * 1e18;
        prevMovingAverage[1] = 2 * 1e18;

        int256[] memory newData = new int256[](2);
        newData[0] = 2 * 1e18;
        newData[1] = 3 * 1e18;

        int128[] memory lambda = new int128[](1);
        lambda[0] = 5 * 1e17; // 0.5 in SD59x18

        uint256 numberOfAssets = 2;

        int256[] memory result =
            movingAverage.calculateQuantAMMMovingAverage(prevMovingAverage, newData, lambda, numberOfAssets);

        console.log("Result length:", result.length);
        console.logInt(result[0]);
        console.logInt(result[1]);

        assertEq(result.length, 2);
        assertEq(result[0], 1.5 * 1e18);
        assertEq(result[1], 2.5 * 1e18);
    }

    function testSetInitialMovingAverages() public {
        address poolAddress = address(0x123);
        int256[] memory initialMovingAverages = new int256[](2);
        initialMovingAverages[0] = 1 * 1e18;
        initialMovingAverages[1] = 2 * 1e18;

        uint256 numberOfAssets = 2;

        movingAverage.setInitialMovingAverages(poolAddress, initialMovingAverages, numberOfAssets);

        int256[] memory storedMovingAverages = movingAverage.getMovingAverages(poolAddress);
        int256[] memory unpackedMovingAverages =
            movingAverage.unpackMovingAverages(storedMovingAverages, numberOfAssets);

        console.log("Unpacked Moving Averages length:", unpackedMovingAverages.length);
        console.logInt(unpackedMovingAverages[0]);
        console.logInt(unpackedMovingAverages[1]);

        assertEq(unpackedMovingAverages.length, 2);
        assertEq(unpackedMovingAverages[0], 1 * 1e18);
        assertEq(unpackedMovingAverages[1], 2 * 1e18);
    }

    function testFuzzCalculateQuantAMMMovingAverage(
        int256[] memory prevMovingAverage,
        int256[] memory newData,
        int128[] memory lambda,
        uint256 numberOfAssets
    ) public {
        vm.assume(prevMovingAverage.length == numberOfAssets);
        vm.assume(newData.length == numberOfAssets);
        vm.assume(lambda.length == 1 || lambda.length == numberOfAssets);
        vm.assume(numberOfAssets > 0 && numberOfAssets <= 10); // Limit the number of assets to a reasonable range
        for (uint256 i = 0; i < numberOfAssets; i++) {
            vm.assume(prevMovingAverage[i] >= -1e18 && prevMovingAverage[i] <= 1e18);
            vm.assume(newData[i] >= -1e18 && newData[i] <= 1e18);
            if (lambda.length == numberOfAssets) {
                vm.assume(lambda[i] >= 0 && lambda[i] <= 1e18);
            }
        }

        int256[] memory result =
            movingAverage.calculateQuantAMMMovingAverage(prevMovingAverage, newData, lambda, numberOfAssets);

        console.log("Fuzz Result length:", result.length);
        for (uint256 i = 0; i < numberOfAssets; i++) {
            console.logInt(result[i]);
        }

        assertEq(result.length, numberOfAssets);
    }

    function testFuzzSetInitialMovingAverages(
        address poolAddress,
        int256[] memory initialMovingAverages,
        uint256 numberOfAssets
    ) public {
        vm.assume(initialMovingAverages.length == numberOfAssets);
        vm.assume(numberOfAssets > 0 && numberOfAssets <= 10); // Limit the number of assets to a reasonable range
        for (uint256 i = 0; i < numberOfAssets; i++) {
            vm.assume(initialMovingAverages[i] >= -1e18 && initialMovingAverages[i] <= 1e18);
        }

        movingAverage.setInitialMovingAverages(poolAddress, initialMovingAverages, numberOfAssets);

        int256[] memory storedMovingAverages = movingAverage.getMovingAverages(poolAddress);
        int256[] memory unpackedMovingAverages =
            movingAverage.unpackMovingAverages(storedMovingAverages, numberOfAssets);

        console.log("Fuzz Unpacked Moving Averages length:", unpackedMovingAverages.length);
        for (uint256 i = 0; i < numberOfAssets; i++) {
            console.logInt(unpackedMovingAverages[i]);
        }

        assertEq(unpackedMovingAverages.length, numberOfAssets);
    }
}
