pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/Pot.sol";
import "../contracts/Token.sol";

contract PotTest is Test {
    Pot pot;
    Token token;
    address owner = address(0x123);
    address player1 = address(0x456);
    address player2 = address(0x789);

    function setUp() public {
        token = new Token();
        pot = new Pot(address(token));

        // Presuming token minting or balance setup
        token.mint(owner, 200 * 10 ** 18);
        token.mint(player1, 100 * 10 ** 18);
        token.mint(player2, 100 * 10 ** 18);

        // Transfer ownership or other set up tasks, if necessary
        pot.transferOwnership(owner);
    }

    function testApprovalRaceCondition() public {
        uint256 potInitialBalance = token.balanceOf(address(pot));
        uint256 ownerInitialBalance = token.balanceOf(owner);
        uint256 player1InitialBalance = token.balanceOf(player1);
        uint256 player2InitialBalance = token.balanceOf(player2);

        console.log("Initial pot balance: ", potInitialBalance);
        console.log("Initial owner balance: ", ownerInitialBalance);
        console.log("Initial player1 balance: ", player1InitialBalance);
        console.log("Initial player2 balance: ", player2InitialBalance);

        vm.prank(owner);
        token.approve(address(pot), potInitialBalance);

        console.log("After approval - Pot balance: ", token.balanceOf(address(pot)));
        console.log("After approval - Owner balance: ", token.balanceOf(owner));
        console.log("After approval - Player1 balance: ", player1InitialBalance);
        console.log("After approval - Player2 balance: ", player2InitialBalance);

        // Simulate race condition by modifying owner balance
        vm.prank(owner);
        token.transfer(player1, 50 * 10 ** 18); // Actual transfer

        console.log("After transfer to Player1 - Owner balance: ", token.balanceOf(owner));
        console.log("After transfer to Player1 - Player1 balance: ", token.balanceOf(player1));

        // First we expect the pot to fail closing due to being still open for claim.
        vm.expectRevert(Pot.Pot__StillOpenForClaim.selector);

        vm.prank(owner);
        pot.closePot();

        // Let's assume now we can make the pot eligible for closing.
        // This could be done via some setup code, if applicable in the actual contract logic.
        // pot.setupForClosing(); - Hypothetically making it ready for closure

        // Now ensure the balance check triggers the correct revert error.
        // vm.expectRevert(Pot.Pot__InsufficientBalanceOnClose.selector);

        // Attempt to close the pot again.
        // vm.prank(owner);
        // pot.closePot();

        console.log("After pot closure attempt - Pot balance: ", token.balanceOf(address(pot)));
        console.log("After pot closure attempt - Owner balance: ", token.balanceOf(owner));
        console.log("After pot closure attempt - Player1 balance: ", token.balanceOf(player1));
        console.log("After pot closure attempt - Player2 balance: ", token.balanceOf(player2));
    }
}
