// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MysteryBox.sol";

contract EventTest is Test {
    MysteryBox public mysteryBox;
    address public owner = address(0xBEEF);

    event BoxPriceUpdated(uint256 newPrice);

    function setUp() public {
        // Seed the owner address with some ether
        vm.deal(owner, 1 ether);

        // Deploy the MysteryBox contract with the owner as the sender
        vm.prank(owner);
        mysteryBox = new MysteryBox{value: 0.5 ether}();
    }

    function testSetBoxPrice() public {
        // Start acting as the owner
        vm.startPrank(owner);

        // Log initial box price for debugging
        uint256 initialPrice = mysteryBox.boxPrice();
        console.log("Initial Box Price:", initialPrice);

        // New price to be set
        uint256 newPrice = 0.2 ether;
        console.log("Setting new Box Price:", newPrice);

        // Expect the BoxPriceUpdated event to be emitted with correct value
        vm.expectEmit(true, true, true, true);
        emit BoxPriceUpdated(newPrice);

        // Set the new box price
        mysteryBox.setBoxPrice(newPrice);

        // Log the box price after the change for debugging
        uint256 updatedPrice = mysteryBox.boxPrice();
        console.log("Updated Box Price:", updatedPrice);

        // Verify that the new price was correctly set
        assertEq(updatedPrice, newPrice, "Box price should be updated");

        // Stop acting as the owner
        vm.stopPrank();
    }
}
