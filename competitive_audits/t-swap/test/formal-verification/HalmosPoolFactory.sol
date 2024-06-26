// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/PoolFactory.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PoolFactoryTest is Test {
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

    function checkCreatePool() public {
        address poolAddress = factory.createPool(address(tokenA));

        // Property 1: Ensure pool creation is successful and retrievable
        assertEq(address(factory.getPool(address(tokenA))), poolAddress);

        // Property 2: Ensure token retrieval from pool address is correct
        assertEq(factory.getToken(poolAddress), address(tokenA));
    }

    function checkCantCreatePoolIfExists() public {
        // Attempt to create the pool twice and expect a revert
        factory.createPool(address(tokenA));

        // Property 3: Verify revert when trying to create an existing pool
        expectRevert(abi.encodeWithSelector(PoolFactory.PoolFactory__PoolAlreadyExists.selector, address(tokenA)));
        factory.createPool(address(tokenA));
    }

    // Utility functions

    function assertEq(address a, address b) internal pure override {
        assert(a == b);
    }

    function expectRevert(bytes memory data) internal {
        bool success;
        bytes memory returndata;
        (success, returndata) = address(factory).call(data);
        assert(!success);
    }
}
