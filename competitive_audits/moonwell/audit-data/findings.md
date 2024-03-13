# High

### [H-1] Unchecked Math Operations in MErc20DelegateFixer.sol

## Summary

The provided Solidity smart contract, MErc20DelegateFixer, exhibits a high-severity vulnerability due to unchecked math operations, particularly in the getCashPrior function. This vulnerability may lead to arithmetic overflow or underflow, posing a significant risk to the integrity of financial calculations within the contract.

## Vulnerability Details

The critical vulnerability lie 134 in the following line of code within the getCashPrior function:

```javascript
return EIP20Interface(underlying).balanceOf(address(this)) + badDebt;
```

The addition operation lacks proper overflow and underflow checks, creating a scenario where unexpected behavior and potential financial loss can occur

## Impact

Exploiting this vulnerability could have severe consequences, including the manipulation of cash calculations, loss of funds, or even a denial-of-service attack. The getCashPrior function plays a crucial role in determining the available cash in the market, and an unchecked addition operation significantly jeopardizes the accuracy of this calculation.

## Tools Used

The vulnerability was identified through manual code review.

## Recommendations

1.Immediate Patching: Prioritize an urgent update to the contract code by implementing proper overflow and underflow checks in the vulnerable line of code.
Example:

```javascript
return SafeMath.add(
  EIP20Interface(underlying).balanceOf(address(this)),
  badDebt
);
```

2. Use SafeMath Library or Solidity Built-in Checks: Incorporate the OpenZeppelin SafeMath library or leverage the built-in overflow and underflow checks available in Solidity versions >=0.6.0 and <0.8.0 to ensure secure arithmetic operations.

3. Upgrade to the Latest Solidity Version: Consider upgrading the Solidity version to the latest stable release to benefit from improved language features, security enhancements, and bug fixes.

# Low

### [L-1] Unsafe ABI Encodings in MIP-M17.sol

## Summary

The code exhibits potential security concerns related to the use of unsafe ABI encodings, specifically abi.encodeWithSignature and abi.encodeWithSelector. These practices are error-prone and may result in vulnerabilities due to lack of type safety and typo sensitivity.

## Vulnerability Details

The vulnerable code sections involve the use of abi.encodeWithSignature in the \_pushAction function calls within the \_build function. These calls are used to upgrade implementations of MErc20Delegate contracts and perform other actions.

## Impact

The lack of type safety in ABI encodings can lead to runtime errors, vulnerabilities, and unexpected behavior. Additionally, typo-sensitive functions like abi.encodeWithSignature can introduce risks if the function signatures are not accurately represented, potentially causing unintended consequences.

## Tools Used

Manual review

## Recommendations

1.Replace Unsafe ABI Encodings:
Consider replacing the usage of abi.encodeWithSignature with abi.encodeCall. The latter provides type safety and checks whether the supplied values match the expected types of the called function. This can significantly reduce the risk of runtime errors and vulnerabilities.

2.Use Constants for Function Signatures:
When working with function signatures, consider defining constants for the function signatures to avoid typos and enhance code readability. This practice can contribute to a safer and more maintainable codebase.
