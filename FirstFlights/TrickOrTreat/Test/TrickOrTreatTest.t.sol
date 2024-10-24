// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TrickOrTreat.sol";

contract SpookySwapTest is Test {
    SpookySwap public spookySwap;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x1234);

        SpookySwap.Treat[] memory treats = new SpookySwap.Treat[](1);
        treats[0] = SpookySwap.Treat("Candy", 1 ether, "ipfs://example");

        spookySwap = new SpookySwap(treats);
    }

    function testAddTreat() public {
        spookySwap.addTreat("Chocolate", 2 ether, "ipfs://chocolate");
        (string memory name, uint256 cost, string memory metadataURI) = spookySwap.treatList("Chocolate");
        assertEq(name, "Chocolate");
        assertEq(cost, 2 ether);
        assertEq(metadataURI, "ipfs://chocolate");
    }

    function testSetTreatCost() public {
        spookySwap.setTreatCost("Candy", 2 ether);
        (, uint256 cost,) = spookySwap.treatList("Candy");
        assertEq(cost, 2 ether);
    }

    function testTrickOrTreat() public {
        vm.deal(user, 3 ether);
        vm.prank(user);
        spookySwap.trickOrTreat{value: 1 ether}("Candy");
        assertEq(spookySwap.balanceOf(user), 1);
    }

    function testResolveTrick() public {
        vm.deal(user, 3 ether);
        vm.prank(user);
        spookySwap.trickOrTreat{value: 0.5 ether}("Candy");

        uint256 tokenId = spookySwap.nextTokenId() - 1;
        vm.prank(user);
        spookySwap.resolveTrick{value: 1.5 ether}(tokenId);

        assertEq(spookySwap.balanceOf(user), 1);
    }

    function testWithdrawFees() public {
        vm.deal(user, 3 ether);
        vm.prank(user);
        spookySwap.trickOrTreat{value: 1 ether}("Candy");

        uint256 balanceBefore = owner.balance;
        spookySwap.withdrawFees();
        uint256 balanceAfter = owner.balance;

        assertEq(balanceAfter, balanceBefore + 1 ether);
    }

    function testFuzzTrickOrTreat(uint256 amount) public {
        vm.assume(amount > 0 && amount < 10 ether);
        vm.deal(user, amount);
        vm.prank(user);
        spookySwap.trickOrTreat{value: amount}("Candy");
    }

    function testFuzzResolveTrick(uint256 amount) public {
        vm.assume(amount > 0 && amount < 10 ether);
        vm.deal(user, amount);
        vm.prank(user);
        spookySwap.trickOrTreat{value: amount / 2}("Candy");

        uint256 tokenId = spookySwap.nextTokenId() - 1;
        vm.prank(user);
        spookySwap.resolveTrick{value: amount / 2}(tokenId);

        assertEq(spookySwap.balanceOf(user), 1);
    }
}
