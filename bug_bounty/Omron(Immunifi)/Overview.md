## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| contracts/OmronDeposit.sol | [object Promise] |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **OmronDeposit** | Implementation | Ownable, ReentrancyGuard, Pausable |||
| └ | <Constructor> | Public ❗️ | 🛑  | Ownable |
| └ | addWhitelistedToken | External ❗️ | 🛑  | onlyOwner |
| └ | setWithdrawalsEnabled | External ❗️ | 🛑  | onlyOwner |
| └ | pause | External ❗️ | 🛑  | onlyOwner |
| └ | unpause | External ❗️ | 🛑  | onlyOwner |
| └ | getUserInfo | External ❗️ |   |NO❗️ |
| └ | getAllWhitelistedTokens | External ❗️ |   |NO❗️ |
| └ | calculatePoints | External ❗️ |   |NO❗️ |
| └ | tokenBalance | External ❗️ |   |NO❗️ |
| └ | deposit | External ❗️ | 🛑  | nonReentrant whenNotPaused |
| └ | withdraw | External ❗️ | 🛑  | nonReentrant whenWithdrawalsEnabled |
| └ | _updatePoints | Private 🔐 | 🛑  | |
| └ | _adjustAmountToPoints | Private 🔐 |   | |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
