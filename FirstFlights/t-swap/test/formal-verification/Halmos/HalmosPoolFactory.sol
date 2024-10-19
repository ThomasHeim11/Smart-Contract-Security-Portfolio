// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { PoolFactory } from "../../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PoolFactoryFormalVerification is Test {
    PoolFactory factory;
    ERC20Mock mockWeth;
    ERC20Mock tokenA;
    ERC20Mock tokenB;

    function setUp() public {
        mockWeth = new ERC20Mock();
        factory = new PoolFactory(address(mockWeth));
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
    }

    // Invariant: After creating a pool, the pool address should match the token address.
    function checkCreatePool() public {
        address poolAddress = factory.createPool(address(tokenA));
        assert(poolAddress == factory.getPool(address(tokenA)));
        assert(address(tokenA) == factory.getToken(poolAddress));
    }

    // Invariant: Creating a pool for the same token twice should revert.
    function checkCantCreatePoolIfExists() public {
        // Ensure the initial state by creating a pool for tokenA
        address poolAddress1 = factory.createPool(address(tokenA));
        assert(poolAddress1 == factory.getPool(address(tokenA)));

        // Try creating a pool for the same tokenA again and expect a revert
        (bool success,) = address(factory).call(abi.encodeWithSelector(factory.createPool.selector, address(tokenA)));
        assert(!success); // This should revert, so success should be false
    }
}
