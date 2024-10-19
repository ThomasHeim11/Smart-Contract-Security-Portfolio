# Omron Smart Contracts

EVM contracts for the Omron network.

## Overview

This project consists of one contract, listed below.

- `OmronDeposit.sol`: A contract allowing deposits of both native and LST ERC-20 tokens for accrual of points.

### Dependencies

- NodeJS (18)

### Install

```console
pnpm install
```

### Deploy to Localhost

```console
pnpm dev
```

### Run Unit Tests

```console
pnpm test
```

### Run Debug on Unit Tests

This is for advanced SC debugging. It will get very loud very quick, be prepared for an onslaught of logs. This uses [`hardhat-tracer`] to fully trace SC calls.

```console
pnpm test:debug
```

### Deploy

```console
pnpm deploy
```

## Actors, Roles and Privileges

### Owner

The owner of the contract is the deployer of the contract. The owner has the following privileges:

- Pause the contract
- Unpause the contract
- Change the owner
- Renounce ownership
- Allow withdrawals of ERC20s and ETH
- Disable withdrawals of ERC20s and ETH

### User (Anyone)

The user of the contract is the depositor of the contract. The user has the following privileges:

- Deposit ERC20s when not paused
- Deposit ETH when not paused
- Withdraw ERC20s when not paused, withdrawals enabled
- Withdraw ETH when not paused, withdrawals enabled
- Access read methods

## Incident Response Process

In the event of any emergency situation within the contract, defined as:

- A security incident occurs
- A critical issue is found

The contract owner shall immediately:

- Pause the contract
- Investigate the issue
- Fix the issue or take necessary steps to mitigate the issue
- Unpause the contract

[`hardhat-tracer`]: https://github.com/zemse/hardhat-tracer "Hardhat Tracer GitHub Repo"
