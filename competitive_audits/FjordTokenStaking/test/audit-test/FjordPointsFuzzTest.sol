// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { Test } from "forge-std/Test.sol";
import { FjordPoints } from "../../src/FjordPoints.sol"; // Adjust the path according to your setup

contract FjordPointsFuzzTest is Test {
    FjordPoints fjordPoints;

    function setUp() external {
        fjordPoints = new FjordPoints();
        fjordPoints.setStakingContract(address(this));
    }

    function testFuzzClaimPoints(uint256 iterations, uint256 stakeAmount) external {
        address user1 = address(0x1);
        address user2 = address(0x2);
        address user3 = address(0x3);

        // Limiting the number of iterations to avoid out-of-gas error
        uint256 maxIterations = 100;
        if (iterations > maxIterations) {
            iterations = maxIterations;
        }

        // Limiting the stake amount to avoid excessive gas usage
        uint256 maxStakeAmount = 1000 ether;
        if (stakeAmount > maxStakeAmount) {
            stakeAmount = maxStakeAmount;
        }

        // Simulate staking for multiple users
        fjordPoints.onStaked(user1, stakeAmount);
        fjordPoints.onStaked(user2, stakeAmount / 2);
        fjordPoints.onStaked(user3, stakeAmount / 3);

        for (uint256 i = 0; i < iterations; i++) {
            vm.prank(user1);
            fjordPoints.claimPoints();

            vm.prank(user2);
            fjordPoints.claimPoints();

            vm.prank(user3);
            fjordPoints.claimPoints();
        }

        (, uint256 pendingPoints1,) = fjordPoints.users(user1);
        (, uint256 pendingPoints2,) = fjordPoints.users(user2);
        (, uint256 pendingPoints3,) = fjordPoints.users(user3);

        // Check to ensure points have been claimed completely
        assertEq(pendingPoints1, 0, "User1 pending points should be claimable, but they are not.");
        assertEq(pendingPoints2, 0, "User2 pending points should be claimable, but they are not.");
        assertEq(pendingPoints3, 0, "User3 pending points should be claimable, but they are not.");
    }

    // Staking function for testing purposes
    function onStaked(address user, uint256 amount) external {
        fjordPoints.onStaked(user, amount);
    }

    // Claim points function for testing purposes
    function claimPoints() external {
        fjordPoints.claimPoints();
    }
}
