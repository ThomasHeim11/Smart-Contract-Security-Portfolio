//SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ChristmasDinner} from "../src/ChristmasDinner.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract ChristmasDinnerTest is Test {
    ChristmasDinner cd;
    ERC20Mock wbtc;
    ERC20Mock weth;
    ERC20Mock usdc;

    uint256 constant DEADLINE = 7;
    address deployer = makeAddr("deployer");
    address user1;
    address user2;
    address user3;

    function setUp() public {
        wbtc = new ERC20Mock();
        weth = new ERC20Mock();
        usdc = new ERC20Mock();
        vm.startPrank(deployer);
        cd = new ChristmasDinner(address(wbtc), address(weth), address(usdc));
        vm.warp(1);
        cd.setDeadline(DEADLINE);
        vm.stopPrank();
        _makeParticipants();
    }

    ////////////////////////////////////////////////////////////////
    //////////////////    Deadline Shenenigans     /////////////////
    ////////////////////////////////////////////////////////////////

    // Try resetting Deadline
    function test_tryResettingDeadlineAsHost() public {
        vm.startPrank(deployer);
        cd.setDeadline(8 days);
        vm.stopPrank();
    }

    function test_settingDeadlineAsUser() public {
        vm.startPrank(user1);
        vm.expectRevert();
        cd.setDeadline(3);
        vm.stopPrank();
    }

    // Refund Scenarios
    function test_refundAfterDeadline() public {
        uint256 depositAmount = 1e18;
        vm.startPrank(user1);
        cd.deposit(address(wbtc), depositAmount);
        assertEq(wbtc.balanceOf(address(cd)), depositAmount);
        vm.warp(1 + 8 days);
        vm.expectRevert();
        cd.refund();
        vm.stopPrank();
        assertEq(wbtc.balanceOf(address(cd)), depositAmount);
    }

    function test_refundWithinDeadline() public {
        uint256 depositAmount = 1e18;
        uint256 userBalanceBefore = weth.balanceOf(user1);
        vm.startPrank(user1);
        cd.deposit(address(weth), depositAmount);
        assertEq(weth.balanceOf(address(cd)), depositAmount);
        assertEq(weth.balanceOf(user1), userBalanceBefore - depositAmount);
        vm.warp(1 + 3 days);
        cd.refund();
        assertEq(weth.balanceOf(address(cd)), 0);
        assertEq(weth.balanceOf(user1), userBalanceBefore);
    }

    function test_refundWithEther() public {
        address payable _cd = payable(address(cd));
        vm.deal(user1, 10e18);
        vm.prank(user1);
        (bool sent,) = _cd.call{value: 1e18}("");
        require(sent, "transfer failed");
        assertEq(user1.balance, 9e18);
        assertEq(address(cd).balance, 1e18);
        vm.prank(user1);
        cd.refund();
        assertEq(user1.balance, 10e18);
        assertEq(address(cd).balance, 0);
    }

    // Change Participation Status Scenarios
    function test_participationStatusAfterDeadlineToFalse() public {
        vm.startPrank(user1);
        cd.deposit(address(weth), 1e18);
        assertEq(cd.getParticipationStatus(user1), true);
        vm.warp(1 + 8 days);
        cd.changeParticipationStatus();
        assertEq(cd.getParticipationStatus(user1), false);
    }

    function test_participationStatusAfterDeadlineToTrue() public {
        vm.startPrank(user1);
        cd.deposit(address(weth), 1e18);
        assertEq(cd.getParticipationStatus(user1), true);
        cd.changeParticipationStatus();
        assertEq(cd.getParticipationStatus(user1), false);
        vm.warp(1 + 8 days);
        vm.expectRevert();
        cd.changeParticipationStatus();
        assertEq(cd.getParticipationStatus(user1), false);
    }

    function test_participationStatusBeforeDeadline() public {
        vm.startPrank(user1);
        cd.deposit(address(weth), 1e18);
        assertEq(cd.getParticipationStatus(user1), true);
        cd.changeParticipationStatus();
        assertEq(cd.getParticipationStatus(user1), false);
    }

    // Deposit Scenarios
    function test_depositBeforeDeadline() public {
        vm.warp(1 + 3 days);
        vm.startPrank(user1);
        cd.deposit(address(wbtc), 1e18);
        assertEq(wbtc.balanceOf(user1), 1e18);
        assertEq(wbtc.balanceOf(address(cd)), 1e18);
        vm.stopPrank();
    }

    function test_depositAfterDeadline() public {
        vm.warp(1 + 8 days);
        vm.startPrank(user1);
        vm.expectRevert();
        cd.deposit(address(wbtc), 1e18);
        vm.stopPrank();
    }

    function test_depositNonWhitelistedToken() public {
        ERC20Mock usdt = new ERC20Mock();
        usdt.mint(user1, 1e19);
        vm.startPrank(user1);
        usdt.approve(address(cd), type(uint256).max);
        vm.expectRevert();
        cd.deposit(address(usdt), 1e18);
        vm.stopPrank();
    }

    function test_depositGenerousAdditionalContribution() public {
        vm.startPrank(user1);
        cd.deposit(address(wbtc), 1e18);
        cd.deposit(address(weth), 2e18);
        assertEq(weth.balanceOf(address(cd)), 2e18);
        assertEq(wbtc.balanceOf(address(cd)), 1e18);
    }

    function test_depositEther() public {
        address payable _cd = payable(address(cd));
        vm.deal(user1, 10e18);
        vm.prank(user1);
        (bool sent,) = _cd.call{value: 1e18}("");
        require(sent, "transfer failed");
        assertEq(user1.balance, 9e18);
        assertEq(address(cd).balance, 1e18);
    }

    ////////////////////////////////////////////////////////////////
    ////////////////// Access Controll Shenenigans /////////////////
    ////////////////////////////////////////////////////////////////

    // Change Host Scenarios
    function test_changeHostFail() public {
        vm.startPrank(user1);
        vm.expectRevert();
        cd.changeHost(user1);
        vm.stopPrank();
    }

    function test_changeHostFailNonParticipant() public {
        vm.startPrank(deployer);
        vm.expectRevert();
        cd.changeHost(user1);
        vm.stopPrank();
    }

    function test_changeHostSuccess() public {
        vm.startPrank(user1);
        cd.deposit(address(wbtc), 1e18);
        vm.stopPrank();
        vm.startPrank(deployer);
        cd.changeHost(user1);
        vm.stopPrank();
        address newHost = cd.getHost();
        assertEq(newHost, user1);
    }

    // Withdraw Scenarios
    function test_withdrawAsNonHost() public {
        vm.startPrank(user2);
        cd.deposit(address(weth), 1e18);
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert();
        cd.withdraw();
        vm.stopPrank();
    }

    function test_withdrawAsHost() public {
        uint256 wethAmount;
        uint256 wbtcAmount;
        uint256 usdcAmount;
        vm.startPrank(user1);
        cd.deposit(address(wbtc), 0.5e18);
        wbtcAmount += 0.5e18;
        cd.deposit(address(weth), 2e18);
        wethAmount += 2e18;
        vm.stopPrank();
        vm.startPrank(user2);
        cd.deposit(address(usdc), 2e18);
        usdcAmount += 2e18;
        cd.deposit(address(wbtc), 1e18);
        wbtcAmount += 1e18;
        vm.stopPrank();
        vm.startPrank(deployer);
        cd.withdraw();
        vm.stopPrank();
        assertEq(wbtc.balanceOf(deployer), wbtcAmount);
        assertEq(weth.balanceOf(deployer), wethAmount);
        assertEq(usdc.balanceOf(deployer), usdcAmount);
    }

    ////////////////////////////////////////////////////////////////
    //////////////////    Internal Helper Elves    /////////////////
    ////////////////////////////////////////////////////////////////

    function _makeParticipants() internal {
        user1 = makeAddr("user1");
        wbtc.mint(user1, 2e18);
        weth.mint(user1, 2e18);
        usdc.mint(user1, 2e18);
        vm.startPrank(user1);
        wbtc.approve(address(cd), 2e18);
        weth.approve(address(cd), 2e18);
        usdc.approve(address(cd), 2e18);
        vm.stopPrank();
        user2 = makeAddr("user2");
        wbtc.mint(user2, 2e18);
        weth.mint(user2, 2e18);
        usdc.mint(user2, 2e18);
        vm.startPrank(user2);
        wbtc.approve(address(cd), 2e18);
        weth.approve(address(cd), 2e18);
        usdc.approve(address(cd), 2e18);
        vm.stopPrank();
        user3 = makeAddr("user3");
        wbtc.mint(user3, 2e18);
        weth.mint(user3, 2e18);
        usdc.mint(user3, 2e18);
        vm.startPrank(user3);
        wbtc.approve(address(cd), 2e18);
        weth.approve(address(cd), 2e18);
        usdc.approve(address(cd), 2e18);
        vm.stopPrank();
    }
}
