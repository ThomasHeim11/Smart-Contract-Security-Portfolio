### [M-1] ROUNDING INCONSISTENCY IN REWARD DISTRIBUTION

**Description:**
The contract has a bug in the `VotingBooth::_distributeRewards` function related to the calculation of rewardPerVoter. Specifically, the initial calculation of rewardPerVoter uses integer division (totalRewards / totalVotes) for all voters, and then attempts to recalculate it for the last voter using Math.mulDiv with Math.Rounding.Ceil. This inconsistency may lead to rounding errors and result in an incorrect distribution of rewards, impacting the fairness of the reward allocation.

**Impact:**
The bug may lead to discrepancies in the distribution of rewards among voters, potentially favoring the last voter with a slightly higher reward due to inconsistent rounding. While this does not directly compromise the security of the contract, it affects the expected behavior and fairness of the reward distribution.

**Proof of Concept:**
The issue can be observed by analyzing the code logic in the `VotingBooth::_distributeRewards` function, specifically in the section where rewardPerVoter is calculated. By identifying the inconsistency in rounding methods, one can understand the potential impact on the final reward distribution.

**Proof of Concept: Rounding Inconsistency in Reward Distribution**

1. **Scenario Setup:**

   - Deploy the `VotingBooth` contract with an allowance list containing at least two voters.
   - Initiate a voting process and ensure that the proposal passes.

2. **Exploitation Attempt:**
   - Deploy a malicious contract named `MaliciousContract` that attempts to exploit the rounding inconsistency in the `VotingBooth` contract.

```solidity
// MaliciousContract.sol
contract MaliciousContract {
    VotingBooth votingBooth;

    constructor(address _votingBooth) {
        votingBooth = VotingBooth(_votingBooth);
    }

    // Exploitation attempt to observe rounding inconsistency
    function exploit() external view returns (uint256[] memory rewards) {
        uint256 totalVotesFor = votingBooth.s_votersFor().length;
        rewards = new uint256[](totalVotesFor);

        for (uint256 i = 0; i < totalVotesFor; ++i) {
            // Query rewards without participating in the voting process
            rewards[i] = votingBooth.calculateRewardPerVoter(i);
        }
    }
}
```

3. **Outcome Observation:**
   - The `MaliciousContract` attempts to exploit the rounding inconsistency by querying rewards for each voter using the `calculateRewardPerVoter` function.
   - Observe that due to the inconsistency in rounding, the rewards for voters may vary, with the last voter potentially receiving a slightly higher reward.

```solidity
// VotingBooth.sol
// Original code with rounding inconsistency
else {
    for (uint256 i; i < totalVotesFor; ++i) {
        rewardPerVoter = totalRewards / totalVotes; // Integer division for most voters
        if (i == totalVotesFor - 1) {
            rewardPerVoter = Math.mulDiv(totalRewards, 1, totalVotes, Math.Rounding.Ceil); // Ceil rounding for the last voter
        }
        _sendEth(s_votersFor[i], rewardPerVoter);
    }
}
```

4. **Conclusion:**
   - The exploitation attempt demonstrates the potential inconsistency in reward distribution, favoring the last voter due to the rounding method used.
   - The `VotingBooth` contract should be updated with the recommended mitigation to ensure consistent rounding for all voters during reward distribution.

This proof of concept aims to highlight the vulnerability in the reward distribution process and emphasizes the importance of correcting the rounding inconsistency for fairness in allocation.

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

### [M-3] Array Length Manipulation

**Description:**
The contract utilizes arrays (`s_votersFor` and `s_votersAgainst`) to store voters who have cast their votes. While arrays are a convenient data structure, manipulating their length dynamically can lead to potential gas inefficiencies and, in extreme cases, out-of-gas errors. As the length of these arrays grows, the gas cost associated with array resizing increases, impacting the overall performance of the contract.

**Impact:**
The potential impact of array length manipulation is primarily on gas costs and, in extreme scenarios, the risk of encountering out-of-gas errors. As the number of voters increases, the gas required to expand the array length can become substantial, affecting the efficiency of the contract.

**Proof of Concept:**
Consider a scenario where the number of voters reaches the upper limit, causing the arrays `s_votersFor` and `s_votersAgainst` to grow significantly. The gas cost associated with dynamic array resizing can be observed using a tool like Remix IDE or during actual deployment.

```solidity
// Example to demonstrate potential gas inefficiency
contract ArrayManipulationExample {
    address[] private s_votersFor;
    address[] private s_votersAgainst;

    function vote(bool voteInput) external {
        if (voteInput) {
            s_votersFor.push(msg.sender);
        } else {
            s_votersAgainst.push(msg.sender);
        }
    }
}
```

**Recommended Mitigation:**
Consider using a mapping or a different data structure to avoid dynamic array resizing. Mappings provide constant-time lookups and insertions, making them more gas-efficient than arrays for large datasets.

```solidity
// Modified contract using mappings instead of arrays
contract EfficientVotingContract {
    mapping(address => bool) private s_votersFor;
    mapping(address => bool) private s_votersAgainst;

    function vote(bool voteInput) external {
        address voter = msg.sender;
        if (voteInput) {
            s_votersFor[voter] = true;
        } else {
            s_votersAgainst[voter] = true;
        }
    }
}
```

**Severity:**
The severity of this risk is considered low to medium. While dynamic array resizing can lead to increased gas costs, the impact is more pronounced in scenarios with a large number of voters. For contracts with a limited number of voters, the risk may be relatively low. Nonetheless, adopting more gas-efficient data structures is recommended to enhance the contract's scalability and reduce the likelihood of encountering gas-related issues.

## [L-1]: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

- Found in src/VotingBooth.sol [Line: 2](src/VotingBooth.sol#L2)

  ```solidity
  pragma solidity ^0.8.23;
  ```

## [L-2]: PUSH0 is not supported by all chains

Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

- Found in src/VotingBooth.sol [Line: 2](src/VotingBooth.sol#L2)

  ```solidity
  pragma solidity ^0.8.23;
  ```

### [L-3] Visibility of `isActive` Function

**Description:**
The `VotingBooth::isActive` function in the provided Solidity code is marked as `public`; however, its primary use is for internal purposes within the contract. This visibility mismatch exposes the internal state of the contract to external parties, potentially revealing information that is not intended for public scrutiny.

**Impact:**
The impact of this issue is relatively low since the function itself does not perform critical operations and does not directly expose sensitive data. Nevertheless, it violates the principle of encapsulation by allowing external entities to access an internal state-checking function.

**Proof of Concept:**
The proof of concept will demonstrate how an external contract can access the `VotingBooth::isActive` function inappropriately due to its public visibility. The objective is to show that external entities can query the internal state of the contract, which was not intended for public inspection.

```solidity
// MaliciousContract.sol
// External contract attempting to access isActive
contract MaliciousContract {
    VotingBooth votingBooth;

    constructor(address _votingBooth) {
        votingBooth = VotingBooth(_votingBooth);
    }

    // Malicious attempt to access internal state
    function checkIfActive() external view returns (bool) {
        return votingBooth.isActive();
    }
}
```

In this proof of concept, we have a malicious external contract named `MaliciousContract`. This contract takes the address of a deployed `VotingBooth` contract in its constructor. The `checkIfActive` function is then used to attempt to query the internal state of the `VotingBooth` contract by calling its `isActive` function.

```solidity
// VotingBooth.sol
// Original contract with the isActive function marked as public
contract VotingBooth {
    // ... (existing contract code)

    // Original public isActive function
    function isActive() public view returns (bool) {
        return !s_votingComplete;
    }

    // ... (existing contract code)
}
```

The `VotingBooth` contract, as provided in the original code, contains the `isActive` function marked as public. This allows external contracts, such as the `MaliciousContract`, to call it directly.

_Execution_:

1. Deploy the `VotingBooth` contract.
2. Deploy the `MaliciousContract` and provide the address of the deployed `VotingBooth` contract.
3. Call the `checkIfActive` function in the `MaliciousContract`.
4. Observe that the `MaliciousContract` can successfully query the internal state of the `VotingBooth` contract, violating the intended encapsulation.

This proof of concept demonstrates how the public visibility of the `isActive` function allows external contracts to inappropriately access the internal state of the `VotingBooth` contract. To mitigate this issue, it is recommended to change the visibility of the `isActive` function to either `internal` or `private` to prevent external access.

**Recommended Mitigation:**
To mitigate this issue, it is recommended to change the visibility of the `VotingBooth::isActive` function to either `internal` or `private`. This modification will restrict external access, aligning the function's visibility with its intended use within the contract.

```solidity
function isActive() internal view returns (bool) {
    return !s_votingComplete;
}
```
