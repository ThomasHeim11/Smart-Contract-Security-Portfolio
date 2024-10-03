// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import { FjordAuction } from "../../src/FjordAuction.sol";
import { ReentrancyAttack } from "./ReentrancyAttack.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC20Mock } from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol"; // Import ERC20Mock from OpenZeppelin Contracts

contract FjordAuctionTest is Test {
    FjordAuction auction;
    ERC20Mock fjordPoints;
    ReentrancyAttack attacker;

    function setUp() public {
        // Initialize the ERC20Mock with token name and symbol
        fjordPoints = new ERC20Mock();

        // Mint tokens for testing
        fjordPoints.mint(address(this), 1000 ether);

        // Initialize the FjordAuction contract with the fjordPoints token
        auction = new FjordAuction(address(fjordPoints), address(fjordPoints), 300, 500 ether);

        // Initialize the ReentrancyAttack contract
        attacker = new ReentrancyAttack(auction, IERC20(address(fjordPoints))); // Explicit casting to IERC20

        // Mint some tokens for the attacker and approve them
        fjordPoints.mint(address(attacker), 100 ether);
        fjordPoints.approve(address(attacker), 100 ether); // Add approval here
    }

    function testFuzz_ReentrancyAttack(uint256 bidAmount) public {
        // Fuzz assumption to stay within the range of bid amounts we want to test
        vm.assume(bidAmount > 0 && bidAmount <= 10 ether);

        // Transfer tokens to the attacker
        fjordPoints.transfer(address(attacker), 100 ether);

        // Approving the attacker contract to spend on behalf of the attacker
        vm.prank(address(attacker));
        fjordPoints.approve(address(attacker), 100 ether);

        vm.prank(address(attacker));
        attacker.attack(bidAmount);

        // Increase allowance for reentrancy
        vm.prank(address(attacker));
        fjordPoints.approve(address(auction), 20 ether); // Ensure sufficient allowance for reentrancy

        vm.prank(address(attacker));
        bool success = false;
        (success,) = address(attacker).call(abi.encodeWithSignature("reenter()"));
        assertTrue(success, "Reentrancy attack should succeed");

        uint256 attackerBalance = fjordPoints.balanceOf(address(attacker));
        assertGt(attackerBalance, bidAmount * 2, "Attacker should have more due to reentrancy");
    }
}
