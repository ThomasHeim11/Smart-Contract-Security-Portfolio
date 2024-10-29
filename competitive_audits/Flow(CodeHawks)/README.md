# Sablier Flow

### Prize Pool

- Total Pool - $20,000
- H/M - $19,000
- Low - $1000

- Starts: October 25, 2024 Noon UTC
- Ends: November 01, 2024 Noon UTC

- nSLOC: 946

[//]: # (contest-details-open)

## What is Flow?

Flow is a debt tracking protocol that tracks tokens owed between two parties, enabling open-ended payment streaming.

A Flow stream is characterized by its **rate per second (rps)**. **Rate per second** is defined as the rate at which tokens are increasing by the second to the recipient. The relationship between the amount owed and time elapsed is linear and can be defined as:

```math
\text{amount owed} = rps \cdot \text{elapsed time}
```

We use 18-decimal fixed-point number to store the **rate per second** and **snapshot debt**, regardless of the decimals of the underlying ERC-20 token of a stream. The objective is to provide accuracy to the amount owed. Let's say you want to stream 1 USDC per second (i.e., `1e6` tokens), the `rps` would be stored as `1e18`. You can read more about it in [TECHNICAL-DOC](https://github.com/sablier-labs/flow/blob/main/TECHNICAL-DOC.md) file.

The Flow protocol can be used in several areas of everyday finance, such as payroll, distributing grants, insurance premiums, loans interest, token ESOPs etc.

[GitHub](https://github.com/sablier-labs/flow)
[Technical Doc](https://github.com/sablier-labs/flow/blob/main/TECHNICAL-DOC.md)
[Diagrams](https://github.com/sablier-labs/flow/blob/main/DIAGRAMS.md)

### Essential Features

1. **Flexible deposit:** A stream can be funded with any amount, at any time, by anyone, in full or in parts.
2. **Flexible duration:** A stream can be created with no specific start or end time. It can run indefinitely.
3. **Pause:** A stream can be paused by the `sender` and can later be restarted without losing track of previously accrued debt.
4. **Refund:** The Unstreamed amount can be refunded back to the sender at any time.
5. **Void:** Voiding a stream implies it cannot be restarted anymore. Voiding an insolvent stream forfeits the uncovered debt. Either party can void a stream at any time.
6. **Withdraw:** it is publicly callable as long as `to` is set to the recipient. However, a stream’s recipient is allowed to withdraw funds to any address.

### Key Definitions

A single contract is used for all the streams. The definitions below will help you understand some terms used throughout the contract (note: these are also defined in [Technical doc](https://github.com/sablier-labs/flow/blob/main/TECHNICAL-DOC.md#core-components)).

- **Stream balance:** Token balance of a stream. It increases when funds are deposited into a stream, and decreases when the sender refunds from it or when a withdrawal happens.
- **Total debt:** The amount of tokens owed to the recipient. This value is further divided into two sub-categories:
  - **Covered debt:** The part of the total debt that covered by the stream balance. This is the same as the **withdrawable amount**, which is an alias.
  - **Uncovered debt:** The part of the total debt that is not covered by the stream balance. This is what the sender owes to the stream.

```math
\text{total debt} = \text{covered debt} + \text{uncovered debt}
```

- **Snapshot debt** and **snapshot time**: Snapshot debt is the total ongoing debt accumulated over time up to the previous snapshot. Snapshot time refers to the UNIX timestamp when each snapshot is created.

```math
\text{total debt} = \text{snapshot debt} + \underbrace{
rps \cdot (\text{block.timestamp} - \text{snapshot time})}_\text{ongoing debt}
```

### Lifecycle of a stream

1. A Flow stream is created with an `rps`, a `sender` and a `recipient` address.
2. During the lifecycle of the stream, all the functions enclosed inside the dotted rectangle (diagram below) can be called any number of times. There are some limitations though, such as `restart` can only be called if the stream is `paused`.
3. Any party can call `void` to terminate it. Only withdraw and refund are allowed on a voided stream.

![Lifecycle of a stream
](https://file.notion.so/f/f/12e6a04a-1b5c-42fe-9099-f204f5b88305/558bf572-514f-458b-b81e-6e16a4a15393/Screenshot_2024-09-26_at_15.06.37.png?table=block&id=10d6105a-d8b6-808d-af33-eceac4927180&spaceId=12e6a04a-1b5c-42fe-9099-f204f5b88305&expirationTimestamp=1729296000000&signature=1xIqRSsWyxxqJv66WUJjaFJtfq3iEbMDlDfZn59QitY&downloadName=Screenshot+2024-09-26+at+15.06.37.png)

For more detailed diagrams, visit [DIAGRAMS](https://github.com/sablier-labs/flow/blob/main/DIAGRAMS.md).

## Actors

1. Protocol Admin: Protocol admin has the ability to set protocol fee, collect protocol revenue, recover surplus tokens and set NFT descriptor. Admin should not be able to change a stream's parameters.
1. Sender: The creator of the stream. Sender has the ability to change rps, pause, restart, void and refund from the stream. Sender can also withdraw from the stream as long as the `to` address is set to the recipient.
1. Recipient: The receiver of the stream. Recipient can withdraw streamed tokens to an external address. Recipient also has the ability to void the stream.
1. Unknown user: Anyone who is not the protocol admin, a sender or a recipient is considered as unknown. Unknown user has the ability to deposit into any stream. They can also withdraw from any stream as long as the `to` address is set to the recipient.

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

All Contracts in `src` are in scope except `interfaces`.

```tree
src/
├── FlowNFTDescriptor.sol
├── SablierFlow.sol
├── abstracts/
│   ├── Adminable.sol
│   ├── Batch.sol
│   ├── NoDelegateCall.sol
│   └── SablierFlowBase.sol
├── libraries/
│   ├── Errors.sol
│   └── Helpers.sol
└── types/
    └── DataTypes.sol
```

## Compatibilities

Flow is expected to work on any EVM based blockchain.

Any ERC-20 token can be used with Flow as long as it adheres to the following assumptions:

1. The total supply of any ERC-20 token remains below $(2^{128} - 1)$, i.e., `type(uint128).max`.
2. The `transfer` and `transferFrom` methods of any ERC-20 token strictly reduce the sender's balance by the transfer amount and increase the recipient's balance by the same amount. In other words, tokens that charge fees on transfers are not supported.
3. An address' ERC-20 balance can only change as a result of a `transfer` call by the sender or a `transferFrom` call by an approved address. This excludes rebase tokens, interest-bearing tokens, and permissioned tokens where the admin can arbitrarily change balances.
4. The token contract does not allow callbacks (e.g., ERC-777 is not supported).

[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

You will need the following software on your machine:

- [Git](https://git-scm.com/downloads)
- [Foundry](https://github.com/foundry-rs/foundry)
- [Node.Js](https://nodejs.org/en/download/)
- [Bun](https://bun.sh/)

Clone the repository:

```shell
$ git clone https://github.com/Cyfrin/2024-10-sablier.git
```

Then, inside the project's directory, run this to install the Node.js dependencies and build the contracts:

```shell
$ bun install
$ forge build
```

To run tests without fork tests:

```shell
$ forge test --nmt testFork
```

To run all tests including fork tests:

Follow the `.env.example` file to create a `.env` file at the root of the repo and
populate it with the appropriate environment values. You need to provide your mnemonic phrase and a few API keys.

```shell
$ forge test
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

- It is assumed that a trust relationship is formed between the sender, recipient, and depositors participating in a stream. The recipient
  depends on the sender to fulfill their obligation to repay any debts incurred by the Flow stream. Likewise, depositors
  trust that the sender will not abuse the refund function to reclaim tokens. If sender is malicious, they can steal deposits from depositors via `refund` function.
- When protocol fee is changed, it applies on the withdrawn amount regardless of whether the debt was accumulated before or after the fee change.
- The `depletionTimeOf` function depends on the stream's rate per second. Therefore, any change in the rate per second
  will result in a new depletion time. Therefore, `depletionTimeOf` should not be trusted by on chain integrators.
- Reorg attack can can change stream's parameters except sender and recipient.
- As explained in the Technical Doc, there could be a minor discrepancy between the actual streamed amount and the expected amount. This is due to rps being an 18-decimal number, while users provide the amount per interval in the UI. If rps had infinite decimals, this discrepancy would not occur

### Previous audit report

https://cantina.xyz/portfolio/0e86d73a-3c3b-4b2b-9be5-9cecd4c7a5ac

**Additional Known issues detected by LightChaser can be found [here](https://github.com/Cyfrin/2024-10-sablier/issues/1).**

[//]: # (known-issues-close)
