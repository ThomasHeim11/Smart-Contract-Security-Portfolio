# Christmas Dinner

[//]: # (contest-details-open)

### Details

- Starts: 
- Ends: 

- nSLOC: 129

## About the Project

About

This contract is designed as a modified fund me. It is supposed to sign up participants for a 
social christmas dinner (or any other dinner), while collecting payments for signing up.

We try to address the following problems in the oraganization of such events:

-   **Funding Security**: Organizing a social event is tough, people often say "we will attend" but take forever to pay their share, with our Christmas Dinner Contract we directly "force" the attendees to pay upon signup, so the host can plan properly knowing the total budget after deadline.
-   **Organization**: Through funding security hosts will have a way easier time to arrange the event which fits the given budget. No Backsies.

## Actors


Actors:
- ```Host```: The person doing the organization of the event. Receiver of the funds by the end of ```deadline```. Privilegded Role, which can be handed over to any ```Participant``` by the current ```host```
- ```Participant```: Attendees of the event which provided some sort of funding. ```Participant``` can become new ```Host```, can continue sending money as Generous Donation, can sign up friends and can become ```Funder```.
- ```Funder```: Former Participants which left their funds in the contract as donation, but can not attend the event. ```Funder``` can become ```Participant``` again BEFORE deadline ends.


[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

```
All Contracts in `src` are in scope.
```
```js
src/
├── ChristmasDinner.sol
```

## Compatibilities

```
Compatibilities:
  Blockchains:
      - Ethereum
  Tokens:
      - ETH  
      - WETH
      - WBTC
      - USDC
```


[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

This is a standard Foundry project, to run it use:

```shell
$ forge install
```

```shell
$ forge build
```

### Test

```shell
$ forge test
```

```shell
$ forge coverage
```


[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

We are aware that we do not require a minimum deposit amount to sign up as participant for this contract. We consider it not necessary and rely here on social conventions.

[//]: # (known-issues-close)