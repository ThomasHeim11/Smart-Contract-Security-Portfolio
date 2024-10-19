// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    address otherUser = makeAddr("otherUser");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 10e18);
        poolToken.mint(user, 10e18);

        weth.mint(otherUser, 10e18);
        poolToken.mint(otherUser, 10e18);
    }

    function testDeposit() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.balanceOf(liquidityProvider), 100e18);
        assertEq(weth.balanceOf(liquidityProvider), 100e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 100e18);

        assertEq(weth.balanceOf(address(pool)), 100e18);
        assertEq(poolToken.balanceOf(address(pool)), 100e18);
    }

    function testDepositSwap() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        uint256 expected = 9e18;

        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        assert(weth.balanceOf(user) >= expected);
    }

    function testWithdraw() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.totalSupply(), 0);
        assertEq(weth.balanceOf(liquidityProvider), 200e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 200e18);
    }

    function testCollectFees() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assertEq(pool.totalSupply(), 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }
    //Audit TSwapPool::deposit is missing deadline check causing transactions to complete even after the deadline

    function testRevertIfDeadlinePassed() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        vm.expectRevert(
            abi.encodeWithSelector(TSwapPool.TSwapPool__DeadlineHasPassed.selector, uint64(block.timestamp - 1))
        );
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp - 1));
        vm.stopPrank();
    }

    function testRevertIfZero() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);

        vm.expectRevert(TSwapPool.TSwapPool__MustBeMoreThanZero.selector);
        pool.deposit(0, 100e18, 100e18, uint64(block.timestamp));

        vm.expectRevert(TSwapPool.TSwapPool__MustBeMoreThanZero.selector);
        pool.withdraw(0, 100e18, 100e18, uint64(block.timestamp));

        vm.expectRevert(TSwapPool.TSwapPool__MustBeMoreThanZero.selector);
        pool.getOutputAmountBasedOnInput(0, 100e18, 100e18);

        vm.expectRevert(TSwapPool.TSwapPool__MustBeMoreThanZero.selector);
        pool.getInputAmountBasedOnOutput(0, 100e18, 100e18);

        vm.stopPrank();
    }

    function testWethDepositAmountTooLow() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        vm.expectRevert(
            abi.encodeWithSelector(
                TSwapPool.TSwapPool__WethDepositAmountTooLow.selector, 1_000_000_000, 1_000_000_000 - 1
            )
        );
        pool.deposit(1_000_000_000 - 1, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();
    }

    function testMaxPoolTokenDepositTooHigh() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        vm.expectRevert(abi.encodeWithSelector(TSwapPool.TSwapPool__MaxPoolTokenDepositTooHigh.selector, 1e18, 1e20));
        pool.deposit(1e18, 1e18, 1e18, uint64(block.timestamp));
        vm.stopPrank();
    }

    function testMinLiquidityTokensToMintTooLow() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        vm.expectRevert(
            abi.encodeWithSelector(TSwapPool.TSwapPool__MinLiquidityTokensToMintTooLow.selector, 200e18, 100e18)
        );
        pool.deposit(100e18, 200e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();
    }

    function testInvalidToken() public {
        vm.startPrank(user);
        ERC20Mock unknownToken = new ERC20Mock();
        unknownToken.mint(user, 100e18);

        unknownToken.approve(address(pool), 100e18);
        vm.expectRevert(TSwapPool.TSwapPool__InvalidToken.selector);
        pool.swapExactInput(unknownToken, 100e18, weth, 1e18, uint64(block.timestamp));

        unknownToken.approve(address(pool), 100e18);
        vm.expectRevert(TSwapPool.TSwapPool__InvalidToken.selector);
        pool.swapExactOutput(unknownToken, weth, 1e18, uint64(block.timestamp));

        vm.stopPrank();
    }

    function testOutputTooLow() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        vm.expectRevert(abi.encodeWithSelector(TSwapPool.TSwapPool__OutputTooLow.selector, 1e18, 10e18));
        pool.swapExactInput(poolToken, 10e18, weth, 10e18, uint64(block.timestamp));
        vm.stopPrank();
    }
}
