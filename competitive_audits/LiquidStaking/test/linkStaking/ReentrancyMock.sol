// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../contracts/linkStaking/base/Vault.sol"; // Adjust the import path as necessary

contract ReentrancyMock {
    Vault public vault;
    bool public reentered = false;

    constructor(address _vault) {
        vault = Vault(_vault);
    }

    function attack(uint256 _amount) external {
        vault.withdraw(_amount);
    }

    // Fallback function to attempt reentrancy
    fallback() external payable {
        if (!reentered) {
            reentered = true;
            vault.withdraw(1); // Attempt to reenter with a small amount
        }
    }
}
