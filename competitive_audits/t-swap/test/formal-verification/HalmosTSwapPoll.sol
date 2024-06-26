// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/TSwapPool.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TSwapPoolFormalVerification is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        // Mint initial tokens for liquidityProvider and user
        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 10e18);
        poolToken.mint(user, 10e18);
    }

    // Property 1: Test deposit functionality
    function checkDeposit() public {
        uint256 depositAmount = vm.createUint256("depositAmount");
        uint256 tokenADeposit = vm.createUint256("tokenADeposit");
        uint256 tokenBDeposit = vm.createUint256("tokenBDeposit");
        uint64 timestamp = vm.createUint64("timestamp");

        weth.approve(address(pool), depositAmount);
        poolToken.approve(address(pool), depositAmount);

        pool.deposit(depositAmount, tokenADeposit, tokenBDeposit, timestamp);

        // Assert balances and pool states
        assert(pool.balanceOf(liquidityProvider) == tokenADeposit);
        assert(weth.balanceOf(liquidityProvider) == tokenADeposit);
        assert(poolToken.balanceOf(liquidityProvider) == tokenBDeposit);

        assert(weth.balanceOf(address(pool)) == tokenADeposit);
        assert(poolToken.balanceOf(address(pool)) == tokenBDeposit);
    }

    // Property 2: Test deposit and swap functionality
    function checkDepositSwap() public {
        uint256 depositAmount = vm.createUint256("depositAmount");
        uint256 tokenADeposit = vm.createUint256("tokenADeposit");
        uint256 tokenBDeposit = vm.createUint256("tokenBDeposit");
        uint64 timestamp = vm.createUint64("timestamp");
        uint256 swapAmount = vm.createUint256("swapAmount");
        uint256 expectedWETH = vm.createUint256("expectedWETH");

        weth.approve(address(pool), depositAmount);
        poolToken.approve(address(pool), depositAmount);

        pool.deposit(depositAmount, tokenADeposit, tokenBDeposit, timestamp);

        poolToken.approve(address(pool), swapAmount);

        pool.swapExactInput(poolToken, swapAmount, weth, expectedWETH, timestamp);

        // Assert expected WETH balance for user after swap
        assert(weth.balanceOf(user) >= expectedWETH);
    }

    // Property 3: Test withdraw functionality
    function checkWithdraw() public {
        uint256 depositAmount = vm.createUint256("depositAmount");
        uint256 tokenADeposit = vm.createUint256("tokenADeposit");
        uint256 tokenBDeposit = vm.createUint256("tokenBDeposit");
        uint64 timestamp = vm.createUint64("timestamp");

        weth.approve(address(pool), depositAmount);
        poolToken.approve(address(pool), depositAmount);

        pool.deposit(depositAmount, tokenADeposit, tokenBDeposit, timestamp);

        pool.approve(address(pool), depositAmount);
        pool.withdraw(depositAmount, depositAmount, depositAmount, timestamp);

        // Assert pool state after withdrawal
        assert(pool.totalSupply() == 0);
        assert(weth.balanceOf(liquidityProvider) == 200e18);
        assert(poolToken.balanceOf(liquidityProvider) == 200e18);
    }

    // Property 4: Test collect fees functionality
    function checkCollectFees() public {
        uint256 depositAmount = vm.createUint256("depositAmount");
        uint256 tokenADeposit = vm.createUint256("tokenADeposit");
        uint256 tokenBDeposit = vm.createUint256("tokenBDeposit");
        uint64 timestamp = vm.createUint64("timestamp");
        uint256 swapAmount = vm.createUint256("swapAmount");
        uint256 expectedWETH = vm.createUint256("expectedWETH");

        weth.approve(address(pool), depositAmount);
        poolToken.approve(address(pool), depositAmount);

        pool.deposit(depositAmount, tokenADeposit, tokenBDeposit, timestamp);

        poolToken.approve(address(pool), swapAmount);
        pool.swapExactInput(poolToken, swapAmount, weth, expectedWETH, timestamp);

        pool.approve(address(pool), depositAmount);
        pool.withdraw(depositAmount, 90e18, depositAmount, timestamp);

        // Assert pool state after fee collection
        assert(pool.totalSupply() == 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }

    // Assertion function
    function assert(bool condition) internal pure {
        require(condition, "Assertion failed");
    }
}
