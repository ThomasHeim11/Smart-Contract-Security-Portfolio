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
