## Medium

### [M-1] Using ERC721::\_mint() can be dangerous

## Summary

This report outlines a critical finding identified during the security audit of the smart contract codebase. The finding pertains to the use of the ERC721::\_mint() function, which poses a potential risk to the contract's integrity and the safety of the tokens minted using this method.

## Vulnerability Details

- **Location**: src/TSwapPool.sol, Line: 193
- **Issue**: The smart contract utilizes the ERC721::\_mint() function to mint ERC721 tokens.
- **Description**: The ERC721::\_mint() function is used to mint tokens directly to addresses. However, this method does not check whether the receiving address is capable of handling ERC721 tokens, which could lead to tokens being locked or lost if sent to contracts not designed to interact with ERC721 tokens.

## Impact

The use of ERC721::\_mint() without validating the recipient's ability to handle ERC721 tokens can lead to several adverse outcomes, including but not limited to:

- Loss of tokens: Tokens might be permanently locked in contracts that cannot interact with ERC721 tokens.
- Reduced trust: Users and stakeholders might lose trust in the platform's ability to securely manage assets.
- Operational disruption: The need to address and rectify such issues could lead to operational delays and additional costs.

## Tools Used

The vulnerability was identified through manual code review and analysis.

## Recommendations

- **Immediate Action**: Replace all instances of ERC721::\_mint() with ERC721::\_safeMint() in the smart contract code. The \_safeMint() function includes an additional check to ensure that the recipient address can properly interact with ERC721 tokens, thereby mitigating the risk identified.
