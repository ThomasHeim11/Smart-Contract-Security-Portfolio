<<<<<<< HEAD
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

=======
<p align="center">
<img src="https://res.cloudinary.com/droqoz7lg/image/upload/v1702567649/company/ydt7bez1iimfl3ykarih.png" width="400" alt="VotingBooth">
<br/>

# Contest Details

### Prize Pool

- High - 100xp
- Medium - 20xp
- Low - 2xp

- Starts: December 15, Noon UTC
- Ends: December 22, Noon UTC 


## Stats

- nSLOC: 80
- Complexity Score: 67


# Table of Contents
- [Contest Details](#contest-details)
    - [Prize Pool](#prize-pool)
  - [Stats](#stats)
- [Table of Contents](#table-of-contents)
- [Context](#context)
- [About](#about)
  - [Hint](#hint)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Audit Scope Details](#audit-scope-details)
  - [Compatibilities](#compatibilities)
  - [Roles](#roles)
  - [Known Issues](#known-issues)


# Context 

This is a special rendition of CodeHawks First Flights, as this contract is a simplified version of a real contract which was audited by Cyfrin in a private audit and contained the same bug! Thanks to [Dacian](https://twitter.com/DevDacian) for creating this First Flight! 

Your mission, should you choose to accept it, is to find that bug!

# About 

This contract allows the creator to invite a select group of people to vote on something and provides an eth reward to the `for` voters if the proposal passes, otherwise refunds the reward to the creator. The creator of the contract is considered "Trusted".

This contract has been intentionally simplified to remove much of the extra complexity in order to help you find the particular bug without other distractions. Please read the comments carefully as they note specific findings that are excluded as the implementation has been purposefully kept simple to help you focus on finding the harder to find and more interesting bug.

This contract intentionally has no time-out period for the voting to complete; lack of a time-out period resulting in voting never completing is not a valid finding as this has been intentionally omitted to simplify the codebase.

## Hint

Cats are fuzzy. 

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/Cyfrin/2023-12-Voting-Booth
cd 2023-12-Voting-Booth
make
```

Or optionally, you can run:
```
forge install
forge build
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

- Commit Hash: 5b9554656d53baa2086ab7c74faf8bdeaf81a8b7
- In Scope:

```
./src/
#-- VotingBooth.sol
```

## Compatibilities

- Solc Version: 0.8.23
- Chain(s) to deploy contract to: 
  - Arbitrum
- Tokens
  - None

## Roles

- `creator` - Deployer of the protocol, they are a trusted used who will receive the funds if a vote fails. 
- `AllowedVoters` - A list of addresses that are allowed to vote on proposals.

## Known Issues

- This contract intentionally has no time-out period for the voting to complete; lack of a time-out period resulting in voting never completing is not a valid finding as this has been intentionally omitted to simplify the codebase.
>>>>>>> 72ce745 (update voting booth)
