## High

### [H-1] Uninitialized State Variables in the PoolFactory.sol

## Summary

This report summarizes the findings of a security audit conducted on the PoolFactory contract. The main focus is on uninitialized state variables identified by the Slither static analysis tool. The audit highlights the presence of uninitialized mappings `s_pools` and `s_tokens` which are used in multiple functions within the contract.

## Vulnerability Details

### Uninitialized State Variables

#### Description

The following state variables are never initialized and are used in critical functions:

- `s_pools` (src/PoolFactory.sol#27)

  - Used in:
    - `PoolFactory.createPool(address)` (src/PoolFactory.sol#47-58)
    - `PoolFactory.getPool(address)` (src/PoolFactory.sol#63-65)

- `s_tokens` (src/PoolFactory.sol#28)
  - Used in:
    - `PoolFactory.getToken(address)` (src/PoolFactory.sol#67-69)

#### Exploit Scenario

An uninitialized state variable in Solidity is implicitly initialized to zero. In the case of mappings, this means that any key not explicitly set will return zero. This could lead to incorrect assumptions in the logic of the contract and potential vulnerabilities if these mappings are relied upon for critical functionality.

For example, if the `s_pools` mapping is used to verify the existence of a pool, an uninitialized mapping could falsely indicate the non-existence of a pool, leading to the unintended creation of duplicate pools.

## Impact

The impact of uninitialized state variables in the PoolFactory contract is potentially high, as it could lead to:

- Incorrect verification of pool existence, potentially causing the creation of duplicate pools.
- Logical errors in the retrieval of token or pool addresses, affecting the integrity of the pool management system.
- Loss of funds or denial of service if functions relying on these mappings behave unexpectedly.

## Tools Used

- Slither

## Recommendations

To mitigate the risks associated with uninitialized state variables, the following steps are recommended:

1. **Explicit Initialization**: Explicitly initialize all state variables, even if they are meant to start with a zero value. This improves code readability and ensures that no variable is left unintentionally uninitialized.

   ```solidity
   mapping(address => address) private s_pools = {};
   mapping(address => address) private s_tokens = {};
   ```

2. **Initialization in Constructor**: Ensure that any necessary initial state is set up in the contract constructor.

3. **Validation Checks**: Add additional validation checks in functions that rely on these mappings to ensure that they contain the expected values before proceeding with operations.

   ```solidity
   function createPool(address tokenAddress) external returns (address) {
       require(tokenAddress != address(0), "Invalid token address");
       require(s_pools[tokenAddress] == address(0), "Pool already exists");

       // Rest of the function
   }
   ```

---

Reference: [Slither Detector Documentation: Uninitialized State Variables](https://github.com/crytic/slither/wiki/Detector-Documentation#uninitialized-state-variables)

### [H-2]`TSwapPool::deposit` is missing deadline check causing transactions to complete even after the deadline

##Description:
The `deposit` function accepts a deadline parameter, which according to the documentation is "The deadline for the transaction to be completed by". However, this parameter is never used. As a consequence, operationrs that add liquidity to the pool might be executed at unexpected times, in market conditions where the deposit rate is unfavorable.

<!-- MEV attacks -->

## Impact:

Transactions could be sent when market conditions are unfavorable to deposit, even when adding a deadline parameter.

##Proof of Concept:
The `deadline` parameter is unused.

## Recommended Mitigation:

Consider making the following change to the function.

```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint, // LP tokens -> if empty, we can pick 100% (100% == 17 tokens)
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
+      revertIfDeadlinePassed(deadline)
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
```

## Medium

### [M-1] Using ERC721::\_mint() can be dangerous

## Summary

This report outlines a critical finding identified during the security audit of the smart contract codebase. The finding pertains to the use of the ERC721::\_mint() function, which poses a potential risk to the contract's integrity and the safety of the tokens minted using this method.

## Vulnerability Details

- **Location**: src/TSwapPool.sol, Line: 193
- **Issue**: The smart contract utilizes the ERC721::\_mint() function to mint ERC721 tokens.
- **Description**: The ERC721::\_mint() function is used to mint tokens directly to addresses. However, this method does not check whether the receiving address is capable of handling ERC721 tokens, which could lead to tokens being locked or lost if sent to contracts not designed to interact with ERC721 tokens.

## Impact

The use of ERC721::\_mint() without validating the recipient's ability to handle ERC721 tokens can lead to several adverse outcomes, including but not limited to:

- Loss of tokens: Tokens might be permanently locked in contracts that cannot interact with ERC721 tokens.
- Reduced trust: Users and stakeholders might lose trust in the platform's ability to securely manage assets.
- Operational disruption: The need to address and rectify such issues could lead to operational delays and additional costs.

## Tools Used

The vulnerability was identified through manual code review and analysis.

## Recommendations

- **Immediate Action**: Replace all instances of ERC721::\_mint() with ERC721::\_safeMint() in the smart contract code. The \_safeMint() function includes an additional check to ensure that the recipient address can properly interact with ERC721 tokens, thereby mitigating the risk identified.

### [M-2] PUSH0 is not supported by all chains

## Summary

This report addresses a low-severity issue identified in the smart contract codebase, specifically related to the compatibility of the generated bytecode with various Ethereum Virtual Machine (EVM) versions. The core of the issue is the use of Solidity compiler version 0.8.20, which defaults to the Shanghai EVM version, incorporating the PUSH0 opcode in the bytecode.

## Vulnerability Details

- **Affected Files**:
  - `src/PoolFactory.sol` at [Line: 15](src/PoolFactory.sol#L15)
  - `src/TSwapPool.sol` at [Line: 15](src/TSwapPool.sol#L15)
- **Description**: The Solidity compiler version 0.8.20 targets the Shanghai EVM version by default, resulting in the inclusion of the PUSH0 opcode in the compiled bytecode. This opcode may not be supported on all blockchain networks, especially on Layer 2 (L2) chains or those that have not updated to the Shanghai version, potentially leading to deployment failures.

## Impact

The use of the PUSH0 opcode in smart contracts compiled with Solidity 0.8.20 without specifying an appropriate EVM version for the target chain could result in deployment issues on networks that do not support this opcode. This limitation restricts the deployment and functionality of the smart contracts on various blockchain platforms, potentially affecting their interoperability and reach.

## Tools Used

The issue was identified through manual review of the smart contract code and the Solidity compiler documentation.

## Recommendations

- **Immediate Action**: Developers should explicitly specify the target EVM version when compiling smart contracts with Solidity 0.8.20, ensuring compatibility with the intended deployment blockchain network.

### [M-3] Summary Dangerous Strict Equality in TSwapPool.sol

This report analyzes the findings from a Slither scan of the `TSwapPool` smart contract. The scan identified a potential vulnerability related to the use of strict equality for condition checking.

## Vulnerability Details

### Dangerous Strict Equality

- **Location**: `TSwapPool.sol`, lines 80-85
- **Code**: `amount == 0` (line 81)
- **Description**: The function `revertIfZero(uint256)` uses a strict equality check to revert if the provided amount is zero. Strict equality checks (`==`) can be dangerous because they might lead to unexpected behavior, especially in the context of smart contracts where subtle differences in data types or states can occur.
- **Reference**: [Slither Detector Documentation: Dangerous Strict Equalities](https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities)

## Impact

Using a strict equality check for zero in a critical function like `revertIfZero` can potentially lead to unexpected reverts or missed reverts. This can disrupt the normal operation of the contract, affecting the liquidity addition and withdrawal processes, as well as swap operations. If not handled properly, it could lead to loss of funds, user frustration, and loss of trust in the smart contract.

## Tools Used

- **Slither**

## Recommendations

To mitigate the risks associated with strict equality checks, consider the following recommendations:

1. **Type-Safe Comparisons**: Ensure that all comparisons are type-safe and account for potential edge cases. For instance, use safe math libraries to handle comparisons where underflow or overflow could occur.
2. **Error Handling**: Implement robust error handling mechanisms to provide clear and informative messages to users, helping them understand the cause of any issues.

By addressing the identified vulnerability and following these recommendations, the `TSwapPool` contract can be made more secure and reliable for users.

### [M-3] Reentrancy Vulnerability in TSwapPool.sol

## Summary

This report identifies a reentrancy vulnerability in the `TSwapPool` smart contract method `_swap`, detected during a Slither analysis. The vulnerability occurs due to an external call (`outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000)`) being made before emitting the `Swap` event. Reentrancy vulnerabilities can allow an attacker to manipulate contract state by recursively calling back into the contract before the initial call completes.

## Vulnerability Details

### Reentrancy in `_swap` Method

- **Location**: `TSwapPool.sol`, lines 383-412
- **Code**: `outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);` (line 400)
- **Description**: The `_swap` method transfers tokens to `msg.sender` before emitting the `Swap` event. This sequence could potentially enable reentrant attacks where the recipient contract re-enters the `TSwapPool` contract to call its functions again, possibly modifying state in unexpected ways.
- **Reference**: [Slither Detector Documentation: Reentrancy Vulnerabilities](https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3)

## Impact

If exploited, this vulnerability could lead to various attacks such as draining contract funds, manipulating token balances, or disrupting normal contract operations. The ability to call back into the contract before state changes are finalized poses a significant risk to the integrity and security of the `TSwapPool` contract.

## Recommendations

To mitigate the reentrancy vulnerability and enhance the security of the `TSwapPool` contract, consider the following recommendations:

1. **Update State Before External Calls**: Ensure that state modifications are completed before any external calls to avoid potential reentrant behavior.

2. **Use Checks-Effects-Interactions Pattern**: Implement the Checks-Effects-Interactions pattern where state changes are performed first, followed by external calls and event emissions.

By addressing these recommendations, the `TSwapPool` contract can mitigate the risk of reentrancy attacks and strengthen overall security measures.

## Low

### [L-1] Missing Zero-Address Validation in PoolFactory.sol

## Summary

This report examines a vulnerability discovered in the `PoolFactory` smart contract during a Slither analysis. The vulnerability involves a missing zero-address validation check in the constructor function where the `i_wethToken` state variable is initialized.

## Vulnerability Details

### Missing Zero-Address Validation

- **Location**: `PoolFactory.sol`, lines 40-41
- **Code**: `i_wethToken = wethToken;` (line 41)
- **Description**: The constructor `PoolFactory(address)` assigns the `wethToken` directly to `i_wethToken` without validating if `wethToken` is a zero address (`address(0)`). This can lead to unexpected behavior or vulnerabilities if `wethToken` is improperly set or not initialized correctly.
- **Reference**: [Slither Detector Documentation: Missing Zero-Address Validation](https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation)

## Impact

The absence of zero-address validation for `wethToken` in the constructor of `PoolFactory` could potentially allow the initialization of `i_wethToken` with an invalid address. This could lead to errors or unintended behavior when creating pools or interacting with the factory, impacting the reliability and security of the contract.

## Recommendations

To mitigate the risk associated with missing zero-address validation, consider the following recommendations:

1. **Implement Zero-Address Check**: Modify the constructor to include a require statement that validates `wethToken` is not the zero address (`address(0)`).
2. **Use Safe Assignments**: Ensure all state variable assignments and initializations verify inputs to prevent unintended states or vulnerabilities.

By addressing this vulnerability and following these recommendations, the `PoolFactory` contract can be strengthened to enhance security and reliability.
