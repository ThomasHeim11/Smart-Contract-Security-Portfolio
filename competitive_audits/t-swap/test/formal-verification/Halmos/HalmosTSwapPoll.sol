// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { TSwapPool } from "../../../src/TSwapPool.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TSwapPoolFormalVerification is Test {
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

    function checkDeposit() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 0.5e18); // Further reduce the approval amount
        poolToken.approve(address(pool), 0.5e18);
        pool.deposit(0.5e18, 0.5e18, 0.5e18, uint64(block.timestamp)); // Further reduce deposit amounts
        vm.stopPrank();
    }

    function checkWithdraw() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 100e18, 100e18, uint64(block.timestamp));

        assert(pool.totalSupply() == 0);
        assert(weth.balanceOf(liquidityProvider) == 200e18);
        assert(poolToken.balanceOf(liquidityProvider) == 200e18);
    }

    function checkCollectFees() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assert(pool.totalSupply() == 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }

    function checkRevertIfDeadlinePassed() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        (bool success,) = address(pool).call(
            abi.encodeWithSelector(pool.deposit.selector, 100e18, 100e18, 100e18, uint64(block.timestamp - 1))
        );
        assert(!success);
    }

    function checkRevertIfZero() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);

        (bool success,) = address(pool).call(
            abi.encodeWithSelector(pool.deposit.selector, 0, 100e18, 100e18, uint64(block.timestamp))
        );
        assert(!success);

        (success,) = address(pool).call(
            abi.encodeWithSelector(pool.withdraw.selector, 0, 100e18, 100e18, uint64(block.timestamp))
        );
        assert(!success);

        (success,) =
            address(pool).call(abi.encodeWithSelector(pool.getOutputAmountBasedOnInput.selector, 0, 100e18, 100e18));
        assert(!success);

        (success,) =
            address(pool).call(abi.encodeWithSelector(pool.getInputAmountBasedOnOutput.selector, 0, 100e18, 100e18));
        assert(!success);
    }

    function checkWethDepositAmountTooLow() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        (bool success,) = address(pool).call(
            abi.encodeWithSelector(pool.deposit.selector, 1_000_000_000 - 1, 100e18, 100e18, uint64(block.timestamp))
        );
        assert(!success);
    }

    function checkMaxPoolTokenDepositTooHigh() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        (bool success,) =
            address(pool).call(abi.encodeWithSelector(pool.deposit.selector, 1e18, 1e18, 1e18, uint64(block.timestamp)));
        assert(!success);
    }

    function checkMinLiquidityTokensToMintTooLow() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        (bool success,) = address(pool).call(
            abi.encodeWithSelector(pool.deposit.selector, 100e18, 200e18, 100e18, uint64(block.timestamp))
        );
        assert(!success);
    }

    function checkInvalidToken() public {
        ERC20Mock unknownToken = new ERC20Mock();
        unknownToken.mint(user, 100e18);

        (bool success,) = address(pool).call(
            abi.encodeWithSelector(
                pool.swapExactInput.selector, unknownToken, 100e18, weth, 1e18, uint64(block.timestamp)
            )
        );
        assert(!success);

        (success,) = address(pool).call(
            abi.encodeWithSelector(pool.swapExactOutput.selector, unknownToken, weth, 1e18, uint64(block.timestamp))
        );
        assert(!success);
    }

    function checkOutputTooLow() public {
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        poolToken.approve(address(pool), 10e18);
        (bool success,) = address(pool).call(
            abi.encodeWithSelector(pool.swapExactInput.selector, poolToken, 10e18, weth, 10e18, uint64(block.timestamp))
        );
        assert(!success);
    }
}
