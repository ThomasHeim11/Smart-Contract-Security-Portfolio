# First Flight #27: Trick or Treat

### Prize Pool

- High - 100 XP
- Medium - 20 XP
- Low - 2 XP

- Starts: October 24, 2024 Noon UTC

- Ends: October, 31 2024 Noon UTC

- nSLOC: 109

[//]: # (contest-details-open)

## About the Project

**SpookySwap** is a Halloween-themed decentralized application where users can participate in a thrilling "Trick or Treat" experience! Swap ETH for special Halloween-themed NFT treats. But beware, you might get tricked! There's a small chance your treat will cost half the price, or you might have to pay double. Collect rare NFTs, trade them with friends, or hold onto them for spooky surprises. Will you be tricked or treated?

### Actors

- **Owner/Admin (Trusted)** - Can add new treats, set treat costs, and withdraw collected fees.
- **User/Participant** - Can swap ETH for Halloween treat NFTs, experience "Trick or Treat", and trade NFTs with others.

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

All Contracts in `src` are in scope.

```js
src/
├── SpookySwap.sol
```
Compatibilities

- Blockchains: EVM Equivalent Chains Only
- Tokens: Native ETH

[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

Clone the repo
```bash
git clone https://github.com/Cyfrin/2024-10-trick-or-treat.git
```
Open in VSCode
```bash
code 2024-10-trick-or-treat/
```

Build and run tests
```bash
forge test
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

- We're aware of the pseudorandom nature of the current implementation. This will be replaced with Chainlink VRF in later builds.

[//]: # (known-issues-close)
