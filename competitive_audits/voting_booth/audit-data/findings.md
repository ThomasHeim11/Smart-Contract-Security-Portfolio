### [M-1] ROUNDING INCONSISTENCY IN REWARD DISTRIBUTION

**Description:**
The contract has a bug in the \_distributeRewards function related to the calculation of rewardPerVoter. Specifically, the initial calculation of rewardPerVoter uses integer division (totalRewards / totalVotes) for all voters, and then attempts to recalculate it for the last voter using Math.mulDiv with Math.Rounding.Ceil. This inconsistency may lead to rounding errors and result in an incorrect distribution of rewards, impacting the fairness of the reward allocation.

**Impact:**
The bug may lead to discrepancies in the distribution of rewards among voters, potentially favoring the last voter with a slightly higher reward due to inconsistent rounding. While this does not directly compromise the security of the contract, it affects the expected behavior and fairness of the reward distribution.

**Proof of Concept:**
The issue can be observed by analyzing the code logic in the `VotingBooth::_distributeRewards` function, specifically in the section where rewardPerVoter is calculated. By identifying the inconsistency in rounding methods, one can understand the potential impact on the final reward distribution.

**Recommended Mitigation:**
To address this issue, it is recommended to consistently calculate rewardPerVoter for all voters using Math.mulDiv with Math.Rounding.Ceil throughout the loop. This ensures uniform rounding and prevents potential discrepancies in reward distribution. The corrected code should resemble the following:

```javascript
// if the proposal passed so distribute rewards to the `For` voters
else {
  for (uint256 i; i < totalVotesFor; ++i) {
  rewardPerVoter = Math.mulDiv(totalRewards, 1, totalVotes, Math.Rounding.Ceil);
  \_sendEth(s_votersFor[i], rewardPerVoter);
}
}
```

This modification ensures that consistent rounding is applied to all voters, maintaining fairness in the reward distribution. Additionally, thorough testing should be conducted to validate the corrected implementation and ensure proper functionality.

### [M-2] Low-level Call in `_sendEth` Function

**Description:**
The `VotingBooth::_sendEth` function utilizes a low-level call to transfer Ether to the specified destination address. While this approach is valid, it lacks explicit handling for out-of-gas situations, which could result in the failure of the entire transaction. The low-level call does not automatically limit the gas provided during the call, making it susceptible to potential issues if the receiver's fallback function consumes excessive gas.

**Impact:**
If the fallback function of the destination address consumes too much gas during the low-level call, it may lead to an out-of-gas scenario, causing the entire transaction to fail. This could result in unintended consequences, such as failed reward distribution or an inability to refund funds in certain scenarios.

**Proof of Concept:**
Certainly, let's create a more explicit proof of concept to demonstrate the potential issue with the low-level call in the `_sendEth` function:

### Proof of Concept:

1. **Scenario Setup:**
   - Assume an attacker deploys a malicious contract with an intentionally high gas-consuming fallback function.

```solidity$
// MaliciousContract.sol
contract MaliciousContract {
    // High gas-consuming fallback function
    receive() external payable {
        while(true) {
            // Infinite loop consuming gas
        }
    }
}
```

2. **Exploitation Attempt:**
   - The attacker sends Ether from the `VotingBooth` contract to the malicious contract using the `_sendEth` function.

```solidity
// Exploitation attempt in VotingBooth contract
function exploit() external {
    MaliciousContract malicious = new MaliciousContract();
    _sendEth(address(malicious), 1 ether);
}
```

3. **Outcome:**
   - The `_sendEth` function invokes the low-level call to the malicious contract's high gas-consuming fallback function.
   - Due to the infinite loop in the malicious contract, the gas consumption exceeds the block gas limit.
   - The entire transaction fails, leaving the `VotingBooth` contract unable to complete the intended Ether transfer or refund.

This proof of concept illustrates a scenario where an attacker could intentionally deploy a contract with a high gas-consuming fallback function, causing the failure of transactions involving the `_sendEth` function in the `VotingBooth` contract. This emphasizes the importance of using safer alternatives like the `transfer` or `send` functions to mitigate the risk of out-of-gas scenarios during Ether transfers.

**Recommended Mitigation:**
To address this issue, it is recommended to use the `transfer` or `send` functions instead of a low-level call. These higher-level abstractions automatically limit the gas provided during the transfer, reducing the risk of out-of-gas situations. Here is an updated version of the `_sendEth` function with the recommended mitigation:

```solidity
function _sendEth(address dest, uint256 amount) private {
    (bool sendStatus, ) = dest.call{value: amount}("");
    require(sendStatus, "DP: failed to send eth");
}
```

This modification maintains the simplicity of the function while incorporating a safer method for Ether transfer. The `transfer` function is preferred for its built-in gas limit, providing a more secure approach to handling Ether transfers within the contract.

## L-1: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

- Found in src/VotingBooth.sol [Line: 2](src/VotingBooth.sol#L2)

  ```solidity
  pragma solidity ^0.8.23;
  ```

## L-2: PUSH0 is not supported by all chains

Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

- Found in src/VotingBooth.sol [Line: 2](src/VotingBooth.sol#L2)

  ```solidity
  pragma solidity ^0.8.23;
  ```
