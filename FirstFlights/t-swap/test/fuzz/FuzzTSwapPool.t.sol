// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/TSwapPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    address user = address(0x1);
    address anotherUser = address(0x2);

    function setUp() public {
        weth = new ERC20Mock("Wrapped Ether", "WETH");
        poolToken = new ERC20Mock("Pool Token", "PTKN");
        pool = new TSwapPool(address(poolToken), address(weth), "Liquidity Token", "LTKN");

        weth.mint(user, 1000 * 10 ** 18);
        poolToken.mint(user, 1000 * 10 ** 18);

        weth.mint(anotherUser, 1000 * 10 ** 18);
        poolToken.mint(anotherUser, 1000 * 10 ** 18);

        vm.startPrank(user);
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(anotherUser);
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testFuzzDeposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        public
    {
        vm.assume(wethToDeposit > 0 && wethToDeposit < 1000 * 10 ** 18);
        vm.assume(minimumLiquidityTokensToMint >= 0);
        vm.assume(maximumPoolTokensToDeposit >= 0);
        vm.assume(deadline > block.timestamp);

        vm.startPrank(user);
        try pool.deposit(wethToDeposit, minimumLiquidityTokensToMint, maximumPoolTokensToDeposit, deadline) {
            // Add additional checks and assertions here
        } catch (bytes memory) {
            // Handle reverts
        }
        vm.stopPrank();
    }

    function testFuzzWithdraw(
        uint256 liquidityTokensToBurn,
        uint256 minWethToWithdraw,
        uint256 minPoolTokensToWithdraw,
        uint64 deadline
    )
        public
    {
        vm.assume(liquidityTokensToBurn > 0 && liquidityTokensToBurn < 1000 * 10 ** 18);
        vm.assume(minWethToWithdraw > 0);
        vm.assume(minPoolTokensToWithdraw > 0);
        vm.assume(deadline > block.timestamp);

        vm.startPrank(user);
        // Assume some initial deposit has been made
        pool.deposit(100 * 10 ** 18, 100 * 10 ** 18, 100 * 10 ** 18, uint64(block.timestamp + 1 hours));
        try pool.withdraw(liquidityTokensToBurn, minWethToWithdraw, minPoolTokensToWithdraw, deadline) {
            // Add additional checks and assertions here
        } catch (bytes memory) {
            // Handle reverts
        }
        vm.stopPrank();
    }

    function testFuzzSwapExactInput(uint256 inputAmount, uint256 minOutputAmount, uint64 deadline) public {
        vm.assume(inputAmount > 0 && inputAmount < 1000 * 10 ** 18);
        vm.assume(minOutputAmount > 0);
        vm.assume(deadline > block.timestamp);

        vm.startPrank(user);
        // Assume some initial deposit has been made
        pool.deposit(100 * 10 ** 18, 100 * 10 ** 18, 100 * 10 ** 18, uint64(block.timestamp + 1 hours));
        try pool.swapExactInput(weth, inputAmount, poolToken, minOutputAmount, deadline) {
            // Add additional checks and assertions here
        } catch (bytes memory) {
            // Handle reverts
        }
        vm.stopPrank();
    }

    function testFuzzSwapExactOutput(uint256 outputAmount, uint64 deadline) public {
        vm.assume(outputAmount > 0 && outputAmount < 1000 * 10 ** 18);
        vm.assume(deadline > block.timestamp);

        vm.startPrank(user);
        // Assume some initial deposit has been made
        pool.deposit(100 * 10 ** 18, 100 * 10 ** 18, 100 * 10 ** 18, uint64(block.timestamp + 1 hours));
        try pool.swapExactOutput(weth, poolToken, outputAmount, deadline) {
            // Add additional checks and assertions here
        } catch (bytes memory) {
            // Handle reverts
        }
        vm.stopPrank();
    }
}
