// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/token/Deployer.sol";

contract DeploymentManager {
    address public lastDeployed;

    function deployERC721(string memory name, string memory symbol) public {
        lastDeployed = Deployer.deployERC721Bridgeable(name, symbol); // Alice deploys here
    }

    function deployERC1155(string memory uri) public {
        lastDeployed = Deployer.deployERC1155Bridgeable(uri); // Bob deploys here
    }
}
