<<<<<<< HEAD
# Thunder Loan

<br/>
<p align="center">
<img src="./thunder-loan.svg" width="700" alt="thunder-loans">
</p>
<br/>


*A flash loan protocol based on [Aave](https://aave.com/) and [Compound](https://compound.finance/).*

You can learn more about how [Aave works](https://www.youtube.com/watch?v=dTCwssZ116A) at a high level from [this video](https://www.youtube.com/watch?v=dTCwssZ116A).


- [Thunder Loan](#thunder-loan)
- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Audit Scope Details](#audit-scope-details)
  - [Roles](#roles)
  - [Known Issues](#known-issues)

# About 

The ⚡️ThunderLoan⚡️ protocol is meant to do the following:

1. Give users a way to create flash loans
2. Give liquidity providers a way to earn money off their capital

Liquidity providers can `deposit` assets into `ThunderLoan` and be given `AssetTokens` in return. These `AssetTokens` gain interest over time depending on how often people take out flash loans!

What is a flash loan? 

A flash loan is a loan that exists for exactly 1 transaction. A user can borrow any amount of assets from the protocol as long as they pay it back in the same transaction. If they don't pay it back, the transaction reverts and the loan is cancelled.

Users additionally have to pay a small fee to the protocol depending on how much money they borrow. To calculate the fee, we're using the famous on-chain TSwap price oracle.

We are planning to upgrade from the current `ThunderLoan` contract to the `ThunderLoanUpgraded` contract. Please include this upgrade in scope of a security review. 

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/Cyfrin/6-thunder-loan-audit
cd 6-thunder-loan-audit
make 
```

# Usage

## Testing

```
forge test
```

### Test Coverage

```
forge coverage
```

and for coverage based testing: 

```
forge coverage --report debug
```

# Audit Scope Details

- Commit Hash: 8803f851f6b37e99eab2e94b4690c8b70e26b3f6
- In Scope:
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
- Solc Version: 0.8.20
- Chain(s) to deploy contract to: Ethereum
- ERC20s:
  - USDC 
  - DAI
  - LINK
  - WETH

## Roles

- Owner: The owner of the protocol who has the power to upgrade the implementation. 
- Liquidity Provider: A user who deposits assets into the protocol to earn interest. 
- User: A user who takes out flash loans from the protocol.

## Known Issues

- We are aware that `getCalculatedFee` can result in 0 fees for very small flash loans. We are OK with that. There is some small rounding errors when it comes to low fees
- We are aware that the first depositor gets an unfair advantage in assetToken distribution. We will be making a large initial deposit to mitigate this, and this is a known issue
- We are aware that "weird" ERC20s break the protocol, including fee-on-transfer, rebasing, and ERC-777 tokens. The owner will vet any additional tokens before adding them to the protocol. 
=======
# Smart Contract Security Portfolio 🛡️

![Smart Contract Security](https://github.com/ThomasHeim11/Smart-Contract-Security-Portfolio/assets/106417552/8d43c6a1-d4b4-4af0-b8bf-eeb50f19e430)

## Overview 🌐

Greetings! I extend a warm welcome to my **Smart Contract Security Portfolio** – a manifestation of my unwavering commitment to enhancing the security standards of decentralized applications. As a seasoned blockchain developer, I've made this repository to highlight my proficiency in smart contract audits and proactive vulnerability management, coupled with engaging bounty programs.

## Key Highlights 🚀

### 1. **Smart Contract Audits 🕵️‍♂️**

Delve into this repository to discover detailed smart contract audits, showcasing my skills in conducting thorough security assessments. These audits are designed to ensure that smart contracts have the highest security standards, effectively mitigating risks and potential vulnerabilities.

### 2. **Bug Bounty Program 🐛💰**

I actively engage in bug bounties to gain practical experience, fostering responsible disclosure and showcasing a commitment to continuously improving security practices. Explore the tangible results within this portfolio – where security isn't just a priority but an ongoing and collaborative journey.

## Contributions Welcome 🤝

If you're interested in potential collaboration or have any inquiries, feel free to connect with me on [LinkedIn](https://www.linkedin.com/in/thomas-heim11/).

## Stay Connected 🌐

Stay in the loop with the latest developments and connect with me on LinkedIn:

- [Thomas Heim](https://www.linkedin.com/in/thomas-heim11/)
>>>>>>> origin/master
