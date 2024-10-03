// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./DeploymentManager.sol";
import "../../src/token/ERC721Bridgeable.sol";
import "../../../src/token/ERC1155Bridgeable.sol";

contract TestDeploymentManager is Test {
    DeploymentManager deploymentManager;

    function setUp() public {
        deploymentManager = new DeploymentManager();
    }

    function testAliceDeploymentFuzz(string memory name, string memory symbol) public {
        if (bytes(name).length == 0 || bytes(symbol).length == 0) {
            vm.expectRevert("Name or symbol cannot be empty");
            deploymentManager.deployERC721(name, symbol);
            return;
        }

        deploymentManager.deployERC721(name, symbol);
        address aliceLastDeployed = deploymentManager.lastDeployed();
        assertTrue(aliceLastDeployed != address(0), "Alice deployment failed with fuzzed inputs");

        ERC721Bridgeable deployedContract = ERC721Bridgeable(payable(aliceLastDeployed));
        assertEq(deployedContract.name(), name, "ERC721 Name did not match");
        assertEq(deployedContract.symbol(), symbol, "ERC721 Symbol did not match");
    }

    function testBobDeploymentFuzz(string memory uri) public {
        if (bytes(uri).length == 0) {
            vm.expectRevert("URI cannot be empty");
            deploymentManager.deployERC1155(uri);
            return;
        }

        deploymentManager.deployERC1155(uri);
        address bobLastDeployed = deploymentManager.lastDeployed();
        assertTrue(bobLastDeployed != address(0), "Bob deployment failed with fuzzed input");

        ERC1155Bridgeable deployedContract = ERC1155Bridgeable(payable(bobLastDeployed));
        assertEq(deployedContract.uri(0), uri, "ERC1155 URI did not match");
    }

    function testDeploymentOverwritesFuzz(string memory name, string memory symbol, string memory uri) public {
        deploymentManager.deployERC721(name, symbol);
        address aliceLastDeployed = deploymentManager.lastDeployed();

        deploymentManager.deployERC1155(uri);
        address bobLastDeployed = deploymentManager.lastDeployed();

        assertTrue(
            aliceLastDeployed != bobLastDeployed, "Alice's deployment was not overwritten by Bob with fuzzed inputs"
        );
    }

    function testOrderFuzz(string memory name, string memory symbol, string memory uri) public {
        deploymentManager.deployERC721(name, symbol);
        address first = deploymentManager.lastDeployed();

        deploymentManager.deployERC1155(uri);
        address second = deploymentManager.lastDeployed();

        assertTrue(first != second, "Order deployments are not different with fuzzed inputs");

        assertEq(ERC721Bridgeable(payable(first)).name(), name, "ERC721 Name did not match for first deployment");
        assertEq(ERC721Bridgeable(payable(first)).symbol(), symbol, "ERC721 Symbol did not match for first deployment");
        assertEq(ERC1155Bridgeable(payable(second)).uri(0), uri, "ERC1155 URI did not match for second deployment");
    }

    function testReInitializationGuards(string memory name, string memory symbol, string memory uri) public {
        deploymentManager.deployERC721(name, symbol);
        address firstDeployAddress = deploymentManager.lastDeployed();
        ERC721Bridgeable firstDeployed = ERC721Bridgeable(payable(firstDeployAddress));

        vm.expectRevert("Already init");
        firstDeployed.initialize(abi.encode(name, symbol));

        deploymentManager.deployERC1155(uri);
        address secondDeployAddress = deploymentManager.lastDeployed();
        ERC1155Bridgeable secondDeployed = ERC1155Bridgeable(payable(secondDeployAddress));

        vm.expectRevert("Already init");
        secondDeployed.initialize(abi.encode(uri));
    }

    function testLoadAndInitializeFuzz(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 numDeployments
    ) public {
        for (uint256 i = 0; i < numDeployments; i++) {
            if (i % 2 == 0) {
                if (bytes(name).length == 0 || bytes(symbol).length == 0) {
                    continue;
                }
                deploymentManager.deployERC721(name, symbol);
                address dep = deploymentManager.lastDeployed();
                ERC721Bridgeable deployedContract = ERC721Bridgeable(payable(dep));
                assertEq(deployedContract.name(), name, "ERC721 Name did not match");
                assertEq(deployedContract.symbol(), symbol, "ERC721 Symbol did not match");
            } else {
                if (bytes(uri).length == 0) {
                    continue;
                }
                deploymentManager.deployERC1155(uri);
                address dep = deploymentManager.lastDeployed();
                ERC1155Bridgeable deployedContract = ERC1155Bridgeable(payable(dep));
                assertEq(deployedContract.uri(0), uri, "ERC1155 URI did not match");
            }
        }
    }

    function testNegativeCases() public {
        vm.expectRevert("Name or symbol cannot be empty");
        deploymentManager.deployERC721("", "");

        vm.expectRevert("URI cannot be empty");
        deploymentManager.deployERC1155("");
    }
}
