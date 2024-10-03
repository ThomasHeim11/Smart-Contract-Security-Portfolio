// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Test } from "forge-std/Test.sol";
import { FjordPoints } from "../../src/FjordPoints.sol";
import { ReentrancyAttackFjordPoints } from "./ReentrancyAttackFjordPoints.sol";

contract FjordPointsReentrancyFuzzTest is Test {
    FjordPoints fjordPoints;
    ReentrancyAttackFjordPoints attacker;

    function setUp() public {
        fjordPoints = new FjordPoints();
        attacker = new ReentrancyAttackFjordPoints(fjordPoints);
    }

    function testAttackOnStake(uint256 amount) public {
        // Ensure amount is within a reasonable range
        vm.assume(amount > 0 && amount < type(uint256).max / 10);

        // Fund the attacker contract
        deal(address(attacker), amount);

        uint256 initialStaked = fjordPoints.totalStaked();

        // Initiate the attack
        attacker.attackOnStake(amount);

        uint256 finalStaked = fjordPoints.totalStaked();

        // Assert that the attack succeeded
        assert(finalStaked > initialStaked); // finalStaked should be higher than initialStaked
    }

    function testAttackOnUnstake(uint256 amount) public {
        // Ensure amount is within a reasonable range
        vm.assume(amount > 0 && amount < type(uint256).max / 10);

        // Fund and stake from the attacker contract
        deal(address(attacker), amount);
        attacker.attackOnStake(amount);

        uint256 initialStaked = fjordPoints.totalStaked();

        // Initiate the attack
        attacker.attackOnUnstake(amount);

        uint256 finalStaked = fjordPoints.totalStaked();

        // Assert that the attack created an inconsistency
        assert(finalStaked < initialStaked); // finalStaked should be lower than initialStaked
    }
}
