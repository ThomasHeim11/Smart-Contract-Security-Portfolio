# High Issues

## H-1: Arbitrary `from` passed to `transferFrom` (or `safeTransferFrom`) in DepositTokenLibrary.sol

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

## M-1: Centralization Risk for trusted owners in Size.sol

## Impact

The contracts identified in src/Size.sol utilize role-based access control (RBAC) through OpenZeppelin's AccessControlUpgradeable library. Roles such as DEFAULT_ADMIN_ROLE, BORROW_RATE_UPDATER_ROLE, PAUSER_ROLE, and KEEPER_ROLE are assigned specific privileged functionalities. While RBAC enhances security by restricting access to critical functions, it introduces centralization risks as these roles are entrusted with significant control over contract operations.

Centralization Risk: Owners assigned roles (DEFAULT_ADMIN_ROLE, BORROW_RATE_UPDATER_ROLE, PAUSER_ROLE, KEEPER_ROLE) have the authority to perform critical administrative tasks. Malicious actions or errors by these privileged accounts can lead to unauthorized changes, fund drainage, or disruption of contract operations.

## Proof of Concept

- Found in src/Size.sol [Line: 107](src/Size.sol#L107)

  ```solidity
      function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
  ```

- Found in src/Size.sol [Line: 113](src/Size.sol#L113)

  ```solidity
          onlyRole(DEFAULT_ADMIN_ROLE)
  ```

- Found in src/Size.sol [Line: 123](src/Size.sol#L123)

  ```solidity
          onlyRole(BORROW_RATE_UPDATER_ROLE)
  ```

- Found in src/Size.sol [Line: 132](src/Size.sol#L132)

  ```solidity
      function pause() public override(ISizeAdmin) onlyRole(PAUSER_ROLE) {
  ```

- Found in src/Size.sol [Line: 137](src/Size.sol#L137)

  ```solidity
      function unpause() public override(ISizeAdmin) onlyRole(PAUSER_ROLE) {
  ```

- Found in src/Size.sol [Line: 234](src/Size.sol#L234)

  ```solidity
          onlyRole(KEEPER_ROLE)
  ```

## Tools Used

Manual review

## Recommended Mitigation Steps

To mitigate the centralization risks associated with role-based access control:

- Minimize Role Scope: Review and limit the functionalities assigned to each role (DEFAULT_ADMIN_ROLE, BORROW_RATE_UPDATER_ROLE, PAUSER_ROLE, KEEPER_ROLE) to essential administrative tasks only.

- Multi-Sig or Time-Lock: Implement multi-signature schemes or time-locked transactions for critical operations to require multiple approvals or delays, reducing the impact of single-point vulnerabilities.

## M-2: Centralization Risk for trusted owners in NonTransferrableScaledToken.sol

## Impact

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

## Proof of Concept

- Found in src/token/NonTransferrableScaledToken.sol [Line: 42](src/token/NonTransferrableScaledToken.sol#L42)

  ```solidity
      function mint(address, uint256) external view override onlyOwner {
  ```

- Found in src/token/NonTransferrableScaledToken.sol [Line: 50](src/token/NonTransferrableScaledToken.sol#L50)

  ```solidity
      function mintScaled(address to, uint256 scaledAmount) external onlyOwner {
  ```

- Found in src/token/NonTransferrableScaledToken.sol [Line: 56](src/token/NonTransferrableScaledToken.sol#L56)

  ```solidity
      function burn(address, uint256) external view override onlyOwner {
  ```

- Found in src/token/NonTransferrableScaledToken.sol [Line: 64](src/token/NonTransferrableScaledToken.sol#L64)

  ```solidity
      function burnScaled(address from, uint256 scaledAmount) external onlyOwner {
  ```

- Found in src/token/NonTransferrableScaledToken.sol [Line: 76](src/token/NonTransferrableScaledToken.sol#L76)

  ```solidity
      function transferFrom(address from, address to, uint256 value) public virtual override onlyOwner returns (bool) {
  ```

## Tools Used

Manual Review

## Recommended Mitigation Steps

Correct Function Visibility: Ensure functions intended to modify state are properly declared with the external or public visibility modifier where necessary (mint, burn functions).

Modifier Consistency: Verify that functions using the onlyOwner modifier are consistently applied and do not inadvertently allow unauthorized access.

## M-3: Centralization Risk for trusted owners in NonTransferrableToken.sol

## Impact

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

## Proof of Concept

- Found in src/token/NonTransferrableToken.sol [Line: 14](src/token/NonTransferrableToken.sol#L14)

  ```solidity
  contract NonTransferrableToken is Ownable, ERC20 {
  ```

- Found in src/token/NonTransferrableToken.sol [Line: 29](src/token/NonTransferrableToken.sol#L29)

  ```solidity
      function mint(address to, uint256 value) external virtual onlyOwner {
  ```

- Found in src/token/NonTransferrableToken.sol [Line: 33](src/token/NonTransferrableToken.sol#L33)

  ```solidity
      function burn(address from, uint256 value) external virtual onlyOwner {
  ```

- Found in src/token/NonTransferrableToken.sol [Line: 37](src/token/NonTransferrableToken.sol#L37)

  ```solidity
      function transferFrom(address from, address to, uint256 value) public virtual override onlyOwner returns (bool) {
  ```

- Found in src/token/NonTransferrableToken.sol [Line: 42](src/token/NonTransferrableToken.sol#L42)

  ```solidity
      function transfer(address to, uint256 value) public virtual override onlyOwner returns (bool) {
  ```

## Tools Used

Manual review

## Recommended Mitigation Steps

- Role-Based Access Control (RBAC): Implement a more granular access control mechanism beyond sole ownership, such as role-based permissions.

- Multi-Signature Approval: Consider implementing multi-signature approval mechanisms for critical operations to require consensus among multiple parties.

## M-4 Using ERC721::\_mint() Can Be Dangerous in NonTransferrableScaledToken.sol

## Impact

Using ERC721::\_mint() can mint ERC721 tokens to addresses which don't support ERC721 tokens. Use \_safeMint() instead of \_mint() for ERC721.

## Proof of Concept

- Found in src/token/NonTransferrableScaledToken.sol [Line: 51](src/token/NonTransferrableScaledToken.sol#L51)

  ```solidity
          _mint(to, scaledAmount);
  ```

- Description: Calls \_mint(to, scaledAmount) to mint tokens to the specified address (to).
- Impact: \_mint() does not perform checks to ensure that the recipient address (to) supports ERC721 tokens, potentially leading to unintended behavior or loss of tokens.

- Found in src/token/NonTransferrableScaledToken.sol [Line: 80](src/token/NonTransferrableScaledToken.sol#L80)

  ```solidity
          _mint(to, scaledAmount);
  ```

- Description: Also uses \_mint(to, scaledAmount) within a transfer operation, similarly exposing the risk.
- Impact: This operation could also lead to unintended minting to addresses that do not support ERC721.

## Tools Used

Manual Review

## Recommended Mitigation Steps

Switch to \_safeMint(): Replace all instances of \_mint() with \_safeMint() in ERC721 token minting operations. \_safeMint() performs additional checks to ensure the recipient address is ERC721-compatible.

## M-4 Using ERC721::\_mint() Can Be Dangerous in NonTransferrableToken.sol

## Impact

Using \_mint() without verifying the recipient can handle ERC721 tokens may lead to scenarios where tokens are minted to addresses that do not support ERC721, rendering the tokens inaccessible and potentially causing loss of value.

## Proof of Concept

- Code Reference: This would be a representation of an ERC721 token minting function that uses \_mint() instead of \_safeMint().
- Found in src/token/NonTransferrableToken.sol [Line: 42](src/token/NonTransferrableToken.sol#L42)

  ```solidity
      function transfer(address to, uint256 value) public virtual override onlyOwner returns (bool) {
  ```

## Tools Used

Manuel Review

## Recommended Mitigation Steps

To mitigate this issue, replace any usage of \_mint() with \_safeMint() to ensure that the recipient address can handle ERC721 tokens:

- 1 Use \_safeMint():
  Replace \_mint(to, tokenId) with \_safeMint(to, tokenId) in all minting functions.

```javascript
function mintToken(address to, uint256 tokenId) external onlyOwner {
    _safeMint(to, tokenId); // This ensures `to` can handle ERC721 tokens
}
```

- 2 Contract Interface Implementation:
- Ensure that recipient contracts implement the IERC721Receiver interface to handle safe transfers of ERC721 tokens.

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

## L-2 Unsafe ERC20 Operations should not be used

ERC20 functions may not behave as expected. For example: return values are not always meaningful. It is recommended to use OpenZeppelin's SafeERC20 library.

- Found in src/libraries/actions/BuyCreditMarket.sol [Line: 195](src/libraries/actions/BuyCreditMarket.sol#L195)

  ```solidity
          state.data.borrowAToken.transferFrom(msg.sender, borrower, cashAmountIn - fees);
  ```

- Found in src/libraries/actions/BuyCreditMarket.sol [Line: 196](src/libraries/actions/BuyCreditMarket.sol#L196)

  ```solidity
          state.data.borrowAToken.transferFrom(msg.sender, state.feeConfig.feeRecipient, fees);
  ```

- Found in src/libraries/actions/Claim.sol [Line: 56](src/libraries/actions/Claim.sol#L56)

  ```solidity
          state.data.borrowAToken.transferFrom(address(this), creditPosition.lender, claimAmount);
  ```

- Found in src/libraries/actions/Compensate.sol [Line: 152](src/libraries/actions/Compensate.sol#L152)

  ```solidity
              state.data.collateralToken.transferFrom(
  ```

- Found in src/libraries/actions/Liquidate.sol [Line: 118](src/libraries/actions/Liquidate.sol#L118)

  ```solidity
          state.data.borrowAToken.transferFrom(msg.sender, address(this), debtPosition.futureValue);
  ```

- Found in src/libraries/actions/Liquidate.sol [Line: 119](src/libraries/actions/Liquidate.sol#L119)

  ```solidity
          state.data.collateralToken.transferFrom(debtPosition.borrower, msg.sender, liquidatorProfitCollateralToken);
  ```

- Found in src/libraries/actions/Liquidate.sol [Line: 120](src/libraries/actions/Liquidate.sol#L120)

  ```solidity
          state.data.collateralToken.transferFrom(
  ```

- Found in src/libraries/actions/LiquidateWithReplacement.sol [Line: 161](src/libraries/actions/LiquidateWithReplacement.sol#L161)

  ```solidity
          state.data.borrowAToken.transferFrom(address(this), params.borrower, issuanceValue);
  ```

- Found in src/libraries/actions/LiquidateWithReplacement.sol [Line: 162](src/libraries/actions/LiquidateWithReplacement.sol#L162)

  ```solidity
          state.data.borrowAToken.transferFrom(address(this), state.feeConfig.feeRecipient, liquidatorProfitBorrowToken);
  ```

- Found in src/libraries/actions/Repay.sol [Line: 49](src/libraries/actions/Repay.sol#L49)

  ```solidity
          state.data.borrowAToken.transferFrom(msg.sender, address(this), debtPosition.futureValue);
  ```

- Found in src/libraries/actions/SelfLiquidate.sol [Line: 70](src/libraries/actions/SelfLiquidate.sol#L70)

  ```solidity
          state.data.collateralToken.transferFrom(debtPosition.borrower, msg.sender, assignedCollateral);
  ```

- Found in src/libraries/actions/SellCreditMarket.sol [Line: 201](src/libraries/actions/SellCreditMarket.sol#L201)

  ```solidity
          state.data.borrowAToken.transferFrom(params.lender, msg.sender, cashAmountOut);
  ```

- Found in src/libraries/actions/SellCreditMarket.sol [Line: 202](src/libraries/actions/SellCreditMarket.sol#L202)

  ```solidity
          state.data.borrowAToken.transferFrom(params.lender, state.feeConfig.feeRecipient, fees);
  ```
