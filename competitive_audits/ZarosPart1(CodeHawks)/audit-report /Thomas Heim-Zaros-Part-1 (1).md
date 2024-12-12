# Zaros Part 1 - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)


- ## Low Risk Findings
    - ### [L-01. Storage Collision Due to Lack of Validation for CustomReferralConfiguration::Load function](#L-01)
    - ### [L-02. Locked ETH in TradingAccountBranch.sol](#L-02)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: Zaros

### Dates: Jul 17th, 2024 - Jul 31st, 2024

[See more contest details here](https://codehawks.cyfrin.io/c/2024-07-zaros)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 0
- Medium: 0
- Low: 2

# Low Risk Findings

## <a id='L-01'></a>L-01. Storage Collision Due to Lack of Validation for CustomReferralConfiguration::Load function          

## Proof of Finiding
https://codehawks.cyfrin.io/c/2024-07-zaros/s/458
<img width="1017" alt="image" src="https://github.com/user-attachments/assets/336ad3eb-f3a8-4fe4-be14-e44699c6992c" />


## Summary

The load function computes a storage slot based on the CUSTOM\_REFERRAL\_CONFIGURATION\_DOMAIN and the customReferralCode input. If there are other contracts or libraries using a similar storage slot determination mechanism, this could lead to unexpected storage collisions.

## Vulnerability Details

Code snippet affected:

```javascript
function load(string memory customReferralCode)
    internal
    pure
    returns (Data storage customReferralConfigurationTestnet)
{
    bytes32 slot = keccak256(abi.encode(CUSTOM_REFERRAL_CONFIGURATION_DOMAIN, customReferralCode));

    assembly {
        customReferralConfigurationTestnet.slot := slot
    }
}
```

#### Proof of concept

Copy this code to test folder:

```javascript
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../../src/perpetuals/leaves/CustomReferralConfiguration.sol";

contract FuzzCustomReferralConfigurationTest is Test {
    using CustomReferralConfiguration for *;

    struct Data {
        address referrer;
    }

    function testStorageCollision(bytes32 uniqueSlot, address referrer1, address referrer2) public {
        // Ensure uniqueSlot is non-zero
        require(uniqueSlot != bytes32(0), "uniqueSlot cannot be zero");

        // Store data in a custom slot outside the library function
        Data storage data;
        assembly {
            data.slot := uniqueSlot
        }
        data.referrer = referrer1;

        // Call load from library with a different input that would match the above slot
        string memory randomString = string(abi.encodePacked(uniqueSlot));
        CustomReferralConfiguration.Data storage refData = CustomReferralConfiguration.load(randomString);

        refData.referrer = referrer2;

        assertEq(data.referrer, referrer1, "Expected distinct address in Data");
        assertEq(refData.referrer, referrer2, "Expected distinct address in Custom Referral Data");
    }
```

* Run `forge test --match-contract CustomReferralConfigurationTest -vvv`

Output when running:
`[FAIL. Reason: revert: uniqueSlot cannot be zero; counterexample: calldata=0xc9164d150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018b0000000000000000000000000000000000000000000000000000000000001322 args=[0x0000000000000000000000000000000000000000000000000000000000000000, 0x000000000000000000000000000000000000018b, 0x0000000000000000000000000000000000001322]] testStorageCollision(bytes32,address,address) (runs: 1, μ: 50252, ~: 50252)`

The error message indicates that the test reverted with the message "uniqueSlot cannot be zero". This suggests that the function being tested does not handle the case where uniqueSlot is zero correctly.

## Impact

High
Storage collisions can lead to severe consequences including data corruption and critical vulnerabilities in the contract. Specifically, if the load function generates a slot that overlaps with slots used by other contracts or libraries, it could inadvertently overwrite important data. This could lead to unpredictable behavior, loss of funds, or even complete failure of the contract's logic. In environments with multiple contracts sharing a storage namespace, the risk of such collisions significantly amplifies the potential impact.

## Tools Used

Manual review and Foundry

## Recommendations

Implement a more robust storage slot computation or add additional unique identifiers as described in the initial suggestion.

## <a id='L-02'></a>L-02. Locked ETH in TradingAccountBranch.sol            

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-07-zaros/s/164
<img width="1027" alt="image" src="https://github.com/user-attachments/assets/6cb1de7a-9b8d-446a-8b9b-4585869853d1" />


## Summary

This report details a security vulnerability found within the `TradingAccountBranch` contract of the provided Solidity codebase. The vulnerability pertains to the handling of Ethereum (ETH) payments, specifically instances where ETH can be received but not withdrawn. This issue could potentially allow users to deposit funds into the contract without being able to retrieve them, leading to a loss of funds.

## Vulnerability Details

The vulnerability arises due to the absence of a withdrawal mechanism for ETH in the `TradingAccountBranch` contract. While the contract allows for the deposit of various types of tokens through the `depositMargin` function, there is no corresponding functionality to withdraw these tokens. This limitation applies to ETH as well, despite the contract being marked as `payable`, allowing it to receive ETH.

## Impact

The primary impact of this vulnerability is financial loss for users who deposit ETH into the contract expecting to be able to withdraw it later. Since there is no withdrawal mechanism implemented, users would be unable to retrieve their ETH, rendering the contract unusable for its intended purpose of handling withdrawals alongside deposits.

## Tools Used

The analysis was conducted manually, utilizing standard Solidity knowledge and best practices for smart contract development and auditing.

## Recommendations

To mitigate this vulnerability, one of the following actions should be taken:

1. **Implement a Withdrawal Mechanism**: Add a withdrawal function to the `TradingAccountBranch` contract that allows users to withdraw their ETH along with other supported tokens. This function should ensure that the withdrawal amount does not exceed the user's deposited balance and adhere to any necessary safety checks, such as maintaining minimum margin requirements.

2. **Remove Payable Attribute**: If the intention is to restrict the contract to only accept deposits and not handle withdrawals, the `payable` attribute should be removed. However, this approach limits the contract's utility and may not align with the intended design.

It is crucial to carefully consider the contract's intended use case and choose the most appropriate action to either enable withdrawals or adjust the contract's design accordingly.



