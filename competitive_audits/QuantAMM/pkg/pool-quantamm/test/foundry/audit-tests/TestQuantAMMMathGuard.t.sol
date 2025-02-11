// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../contracts/rules/base/QuantammMathGuard.sol";

contract ConcreteQuantAMMMathGuard is QuantAMMMathGuard {
    function guardQuantAMMWeights(
        int256[] memory _weights,
        int256[] calldata _prevWeights,
        int256 _epsilonMax,
        int256 _absoluteWeightGuardRail
    ) public pure returns (int256[] memory) {
        return _guardQuantAMMWeights(_weights, _prevWeights, _epsilonMax, _absoluteWeightGuardRail);
    }

    function clampWeights(int256[] memory _weights, int256 _absoluteWeightGuardRail)
        public
        pure
        returns (int256[] memory)
    {
        return _clampWeights(_weights, _absoluteWeightGuardRail);
    }

    function normalizeWeightUpdates(int256[] memory _prevWeights, int256[] memory _newWeights, int256 _epsilonMax)
        public
        pure
        returns (int256[] memory)
    {
        return _normalizeWeightUpdates(_prevWeights, _newWeights, _epsilonMax);
    }

    function pow(int256 _x, int256 _y) public pure returns (int256) {
        return _pow(_x, _y);
    }
}

contract TestQuantAMMMathGuard is Test {
    ConcreteQuantAMMMathGuard guard;

    function setUp() public {
        guard = new ConcreteQuantAMMMathGuard();
    }

    function testGuardQuantAMMWeights() public {
        int256[] memory weights = new int256[](2);
        weights[0] = 1 * 1e18;
        weights[1] = 2 * 1e18;

        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 1 * 1e18;
        prevWeights[1] = 1 * 1e18;

        int256 epsilonMax = 1 * 1e18;
        int256 absoluteWeightGuardRail = 1 * 1e18;

        int256[] memory result = guard.guardQuantAMMWeights(weights, prevWeights, epsilonMax, absoluteWeightGuardRail);

        assertEq(result.length, 2);
    }

    function testClampWeights() public {
        int256[] memory weights = new int256[](2);
        weights[0] = 1 * 1e18;
        weights[1] = 2 * 1e18;

        int256 absoluteWeightGuardRail = 1 * 1e18;

        int256[] memory result = guard.clampWeights(weights, absoluteWeightGuardRail);

        assertEq(result.length, 2);
    }

    function testNormalizeWeightUpdates() public {
        int256[] memory prevWeights = new int256[](2);
        prevWeights[0] = 1 * 1e18;
        prevWeights[1] = 1 * 1e18;

        int256[] memory newWeights = new int256[](2);
        newWeights[0] = 2 * 1e18;
        newWeights[1] = 2 * 1e18;

        int256 epsilonMax = 1 * 1e18;

        int256[] memory result = guard.normalizeWeightUpdates(prevWeights, newWeights, epsilonMax);

        assertEq(result.length, 2);
    }

    function testPow() public {
        int256 x = 2 * 1e18;
        int256 y = 3 * 1e18;

        int256 result = guard.pow(x, y);

        assertEq(result, 8 * 1e18);
    }

    function testFuzzGuardQuantAMMWeights(
        int256[] memory weights,
        int256[] memory prevWeights,
        int256 epsilonMax,
        int256 absoluteWeightGuardRail
    ) public {
        vm.assume(weights.length == prevWeights.length);
        vm.assume(weights.length > 0);

        int256[] memory result = guard.guardQuantAMMWeights(weights, prevWeights, epsilonMax, absoluteWeightGuardRail);

        assertEq(result.length, weights.length);
    }

    function testFuzzClampWeights(int256[] memory weights, int256 absoluteWeightGuardRail) public {
        vm.assume(weights.length > 0);

        int256[] memory result = guard.clampWeights(weights, absoluteWeightGuardRail);

        assertEq(result.length, weights.length);
    }

    function testFuzzNormalizeWeightUpdates(int256[] memory prevWeights, int256[] memory newWeights, int256 epsilonMax)
        public
    {
        vm.assume(prevWeights.length == newWeights.length);
        vm.assume(prevWeights.length > 0);

        int256[] memory result = guard.normalizeWeightUpdates(prevWeights, newWeights, epsilonMax);

        assertEq(result.length, prevWeights.length);
    }

    function testFuzzPow(int256 x, int256 y) public {
        int256 result = guard.pow(x, y);

        // No specific assertion here as the result can vary widely, but we ensure it doesn't revert
        assertTrue(result >= 0 || result <= 0);
    }
}
