# High Issues

## H-1: Arbitrary `from` passed to `transferFrom` (or `safeTransferFrom`) in DepositTokenLibrary.sol ✅

## Impact

The identified issue in DepositTokenLibrary.sol allows an arbitrary address (from parameter) to be used in ERC20's transferFrom calls. This design flaw can lead to potential security vulnerabilities where tokens could be transferred from unintended addresses without proper authorization.

## Proof of Concept

- Found in src/libraries/DepositTokenLibrary.sol [Line: 25](src/libraries/DepositTokenLibrary.sol#L25)

  ```solidity
          underlyingCollateralToken.safeTransferFrom(from, address(this), amount);
  ```

  In the depositUnderlyingCollateralToken function, the from parameter is directly passed to safeTransferFrom without proper validation or authorization checks.

- Found in src/libraries/DepositTokenLibrary.sol [Line: 52](src/libraries/DepositTokenLibrary.sol#L52)

  ```solidity
          state.data.underlyingBorrowToken.safeTransferFrom(from, address(this), amount);
  ```

  Similarly, in the depositUnderlyingBorrowTokenToVariablePool function, the from parameter is used in safeTransferFrom without sufficient validation

## Tools Used

Manual review

## Recommended Mitigation Steps

To mitigate the risk associated with arbitrary from parameters in token transfer functions:

- Use msg.sender for from parameter: Instead of allowing arbitrary addresses, ensure that the msg.sender is used as the from parameter in transferFrom and safeTransferFrom calls. This ensures that tokens can only be transferred by the actual token owner or someone authorized by them.

Example:

```javascript
underlyingCollateralToken.safeTransferFrom(msg.sender, address(this), amount);
```

- Implement access control: If there are specific scenarios where tokens need to be transferred from addresses other than msg.sender, implement additional access control mechanisms to validate the authority and permissions of the caller.

## H-2: Arbitrary `from` passed to `transferFrom` (or `safeTransferFrom`) in Liquidate.sol

## Impact

Detailed description of the impact of this finding.

## Proof of Concept

- Found in src/libraries/actions/Liquidate.sol [Line: 119](src/libraries/actions/Liquidate.sol#L119)

  ```solidity
          state.data.collateralToken.transferFrom(debtPosition.borrower, msg.sender, liquidatorProfitCollateralToken);
  ```

- Found in src/libraries/actions/Liquidate.sol [Line: 120](src/libraries/actions/Liquidate.sol#L120)

  ```solidity
          state.data.collateralToken.transferFrom(
  ```

## Tools Used

Manual review

## Recommended Mitigation Steps

To mitigate this issue, it is recommended to:

- Use msg.sender as the from parameter in ERC20's transferFrom calls whenever possible to ensure that token transfers are initiated only by the caller.
- Implement robust access control mechanisms to validate and authorize token transfers based on the intended user's permissions and roles.
- Conduct thorough testing and audits to ensure the security of all token transfer functionalities within the protocol.

## H-3: Findings Report for Self-Liquidation Vulnerability in SelfLiquidate.sol

## Impact

By allowing an arbitrary address to be used as the from parameter, it means that anyone could potentially transfer tokens from someone else's address without proper authorization. This could lead to unauthorized token transfers and potential loss of funds for the token owner.

This vulnerability can result in unauthorized token transfers, potentially causing financial loss for users whose tokens are transferred without consent. It exposes the protocol to security risks where malicious actors could exploit the ability to transfer tokens from addresses they do not own or control.

## Proof of Concept

- Found in src/libraries/actions/SelfLiquidate.sol [Line: 70](src/libraries/actions/SelfLiquidate.sol#L70)

  ```solidity
          state.data.collateralToken.transferFrom(debtPosition.borrower, msg.sender, assignedCollateral);
  ```

## Tools Used

Manual review

## Recommended Mitigation Steps

- Use msg.sender as the from parameter in ERC20's transferFrom calls whenever possible to ensure that token transfers are initiated only by the caller.

- Implement robust access control mechanisms to validate and authorize token transfers based on the intended user's permissions and roles.

## H-3: Findings Report for Unauthorized Token Transfer Risk in SellCreditMarket.sol

## Impact

Allowing an arbitrary address to be used as the from parameter in the transferFrom function poses a significant security risk. It means that anyone could potentially transfer tokens from someone else's address without proper authorization, leading to unauthorized token transfers and potential loss of funds for the token owner. This vulnerability exposes users to financial risks and undermines the security of the protocol.

## Proof of Concept

- Found in src/libraries/actions/SellCreditMarket.sol [Line: 201](src/libraries/actions/SellCreditMarket.sol#L201)

  ```solidity
          state.data.borrowAToken.transferFrom(params.lender, msg.sender, cashAmountOut);
  ```

- Found in src/libraries/actions/SellCreditMarket.sol [Line: 202](src/libraries/actions/SellCreditMarket.sol#L202)

  ```solidity
          state.data.borrowAToken.transferFrom(params.lender, state.feeConfig.feeRecipient, fees);
  ```

These lines of code allow token transfers from the params.lender address without verifying that the caller has the necessary authorization, creating a potential for misuse and unauthorized transfers.

## Tools Used

Manual review

## Recommended Mitigation Steps

- Use msg.sender as the from parameter in ERC20's transferFrom calls whenever possible to ensure that token transfers are initiated only by the caller.

- Implement robust access control mechanisms to validate and authorize token transfers based on the intended user's permissions and roles.

## H-3: Inability to Withdraw ETH in Size.sol

## Impact

Detailed description of the impact of this finding. The Size contract does not provide a mechanism to withdraw ETH, making it impossible to recover funds sent to it. This can lead to a permanent loss of any ETH accidentally or intentionally sent to the contract.

The lack of a withdrawal function in the Size contract poses a critical risk as it leads to the irreversible loss of any ETH sent to the contract. Users and developers may accidentally send ETH to the contract, which would then be irretrievable due to the absence of a withdrawal mechanism. This can result in significant financial loss and erode trust in the contract's safety and usability.

## Proof of Concept

The Size contract code includes the payable attribute, which allows it to receive ETH. However, there is no corresponding function to withdraw the ETH, leading to potential loss of funds.

## Tools Used

Manual Review

## Recommended Mitigation Steps

Option 1: Remove Payable Attribute
If the contract does not need to handle ETH, remove the payable attribute from the contract functions to prevent accidental ETH transfers.

Option 2: Add Withdrawal Feature
Implement a function that allows authorized users to withdraw ETH from the contract. Below is an example implementation:

```diff
+ /// @notice Withdraw ETH from the contract
+ /// @param recipient The address to receive the withdrawn ETH
+ /// @param amount The amount of ETH to withdraw
+ function withdrawETH(address payable recipient, uint256 amount) + external onlyRole(DEFAULT_ADMIN_ROLE) {
+ require(address(this).balance >= amount, "Insufficient balance");
+ recipient.transfer(amount);
+ }
```

By implementing either of these recommendations, the contract can ensure that funds are not accidentally lost and can be retrieved if necessary. This will enhance the contract's usability and security.

# Medium Issues

# Low Issues

## L-1 Missing Return Statement in approve Function of NonTransferrableToken.sol

## Impact

The approve function in the NonTransferrableToken contract does not contain a return statement, even though the ERC-20 standard expects one. This could potentially lead to unexpected behaviors when interacting with other contracts that rely on the ERC-20 standard.

The absence of an explicit return statement in the approve function can cause interoperability issues with other smart contracts that expect a boolean return value upon calling this function. This may lead to unwanted behaviors, such as transaction failures or incorrect state assumptions, which can affect the usability and reliability of the token in a broader ecosystem.

## Proof of Concept

The approve function is intended to always revert with an error (Errors.NOT_SUPPORTED()), but it does not explicitly return a boolean value as expected by the ERC-20 standard.

## Tools Used

Manual review

## Recommended Mitigation Steps

To comply with the ERC-20 standard and avoid any unintended behaviors, make sure all functions that are expected to return a value explicitly do so. In this case, ensure the approve function has a return statement.

Suggested Code Modifcation

```diff
function approve(address, uint256) public virtual override returns (bool) {
    revert Errors.NOT_SUPPORTED();
+   return false; // Ensure the function explicitly returns a value
}

```