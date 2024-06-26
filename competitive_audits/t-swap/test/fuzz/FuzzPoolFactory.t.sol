// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "ds-test/test.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import "forge-std/Vm.sol";
import "forge-std/Test.sol";

contract MockERC20 {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}

contract PoolFactoryTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);
    PoolFactory poolFactory;
    address wethToken = address(new MockERC20("WETH"));

    function setUp() public {
        poolFactory = new PoolFactory(wethToken);
    }

    function testCreatePool(address tokenAddress) public {
        vm.assume(tokenAddress != address(0) && tokenAddress != wethToken);
        MockERC20 token = new MockERC20("Test Token");
        address poolAddress = poolFactory.createPool(address(token));
        assertTrue(poolAddress != address(0));
        assertEq(poolFactory.getPool(address(token)), poolAddress);
    }

    function testFailCreatePoolExistingToken(address tokenAddress) public {
        vm.assume(tokenAddress != address(0) && tokenAddress != wethToken);
        MockERC20 token = new MockERC20("Test Token");
        poolFactory.createPool(address(token));
        poolFactory.createPool(address(token)); // This should fail
    }

    function testGetPool(address tokenAddress) public {
        vm.assume(tokenAddress != address(0) && tokenAddress != wethToken);
        MockERC20 token = new MockERC20("Test Token");
        address poolAddress = poolFactory.createPool(address(token));
        assertEq(poolFactory.getPool(address(token)), poolAddress);
    }

    function testGetToken(address tokenAddress) public {
        vm.assume(tokenAddress != address(0) && tokenAddress != wethToken);
        MockERC20 token = new MockERC20("Test Token");
        address poolAddress = poolFactory.createPool(address(token));
        assertEq(poolFactory.getToken(poolAddress), address(token));
    }

    function testGetWethToken() public {
        assertEq(poolFactory.getWethToken(), wethToken);
    }
}
