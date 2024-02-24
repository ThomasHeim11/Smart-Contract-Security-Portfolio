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
