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

**Recommended Mitigation:**
