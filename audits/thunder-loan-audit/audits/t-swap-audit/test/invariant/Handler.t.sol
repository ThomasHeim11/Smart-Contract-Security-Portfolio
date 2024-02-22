// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    address liquidityProvider = makeAddr("LP");
    address swapper = makeAddr("swapper");

    int256 public expectedDeltaY;
    int256 public expectedDeltaX;
    int256 startingY;
    int256 startingX;

    int256 public actualDeltaX;
    int256 public actualDeltaY;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        poolToken = ERC20Mock(_pool.getPoolToken());
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWeth) public {
        outputWeth = bound(outputWeth, pool.getMinimumWethDepositAmount(), type(uint64).max);
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }
        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth, poolToken.balanceOf(address(pool)), weth.balanceOf(address(pool))
        );
        if (poolTokenAmount > type(uint64).max) {
            return;
        }

        startingY = int256(weth.balanceOf(address(pool)));
        startingX = int256(poolToken.balanceOf(address(pool)));
        expectedDeltaY = int256(-1) * int256(outputWeth);
        expectedDeltaX = int256(poolTokenAmount);
        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            poolToken.mint(swapper, poolTokenAmount - poolToken.balanceOf(swapper) + 1);
        }

        vm.startPrank(swapper);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(pool));
        uint256 endingX = poolToken.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
    }

    function deposit(uint256 wethAmount) public {
        uint256 minWeth = pool.getMinimumWethDepositAmount();
        wethAmount = bound(wethAmount, minWeth, weth.balanceOf(address(pool)));

        startingY = int256(weth.balanceOf(address(pool)));
        startingX = int256(poolToken.balanceOf(address(pool)));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        pool.deposit(wethAmount, 0, uint256(expectedDeltaX), uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(pool));
        uint256 endingX = poolToken.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
    }
}
