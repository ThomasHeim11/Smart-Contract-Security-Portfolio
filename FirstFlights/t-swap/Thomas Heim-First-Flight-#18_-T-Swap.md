# First Flight #18: T-Swap - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01.  Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput` causes protocll to take too many tokens from users, resulting in lost fees](#H-01)
    - ### [H-02.  Lack of slippage protection in `TSwapPool::swapExactOutput` causes users to potentially receive way fewer tokens](#H-02)
    - ### [H-03. TSwapPool::sellPoolTokens` mismatches input and output tokens causing users to receive the incorrect amount of tokens](#H-03)
    - ### [H-04. In `TSwapPool::_swap` the extra tokens given to users after every `swapCount` breaks the protocol invariant of `x * y = k`](#H-04)
- ## Medium Risk Findings
    - ### [M-01.  `TSwapPool::deposit` is missing deadline check causing transactions to complete even after the deadline](#M-01)
- ## Low Risk Findings
    - ### [L-01. `TSwapPool::LiquidityAdded` event has parameters out of order](#L-01)
    - ### [L-02. Default value returned by `TSwapPool::swapExactInput` results in incorrect return value given](#L-02)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #18

### Dates: Jun 20th, 2024 - Jun 27th, 2024

[See more contest details here](https://codehawks.cyfrin.io/c/2024-06-t-swap)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 4
- Medium: 1
- Low: 2


# High Risk Findings

## <a id='H-01'></a>H-01.  Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput` causes protocll to take too many tokens from users, resulting in lost fees            

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/126
<img width="1020" alt="image" src="https://github.com/user-attachments/assets/4c116073-c940-438f-89ec-e8a79eed3609" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L279C1-L294C6

## Description:
The `getInputAmountBasedOnOutput` function is intended to calculate the amount of tokens a user should deposit given an amount of tokens of output tokens. However, the function currently miscalculates the resulting amount. When calculating the fee, it scales the amount by 10_000 instead of 1_000.

## Impact:
Protocol takes more fees than expected from users.

## Recommended Mitigation:

```diff
    function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
-        return ((inputReserves * outputAmount) * 10_000) / ((outputReserves - outputAmount) * 997);
+        return ((inputReserves * outputAmount) * 1_000) / ((outputReserves - outputAmount) * 997);
    }
```
## <a id='H-02'></a>H-02.  Lack of slippage protection in `TSwapPool::swapExactOutput` causes users to potentially receive way fewer tokens  

## Proof of Finding 
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/127
<img width="1005" alt="image" src="https://github.com/user-attachments/assets/69335755-a19d-413e-ac6a-bfa495ce06b2" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L296C1-L322C6

## Description:

The `swapExactOutput` function does not include any sort of slippage protection. This function is similar to what is done in `TSwapPool::swapExactInput`, where the function specifies a `minOutputAmount`, the `swapExactOutput` function should specify a `maxInputAmount`.

## Impact:

If market conditions change before the transaciton processes, the user could get a much worse swap.

## Proof of Concept:

1. The price of 1 WETH right now is 1,000 USDC
2. User inputs a `swapExactOutput` looking for 1 WETH
   1. inputToken = USDC
   2. outputToken = WETH
   3. outputAmount = 1
   4. deadline = whatever
3. The function does not offer a maxInput amount
4. As the transaction is pending in the mempool, the market changes! And the price moves HUGE -> 1 WETH is now 10,000 USDC. 10x more than the user expected
5. The transaction completes, but the user sent the protocol 10,000 USDC instead of the expected 1,000 USDC

## Recommended Mitigation:

We should include a `maxInputAmount` so the user only has to spend up to a specific amount, and can predict how much they will spend on the protocol.

```diff
    function swapExactOutput(
        IERC20 inputToken,
+       uint256 maxInputAmount,
.
.
.
        inputAmount = getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);
+       if(inputAmount > maxInputAmount){
+           revert();
+       }
        _swap(inputToken, inputAmount, outputToken, outputAmount);
```
## <a id='H-03'></a>H-03. TSwapPool::sellPoolTokens` mismatches input and output tokens causing users to receive the incorrect amount of tokens  

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/128
<img width="1013" alt="image" src="https://github.com/user-attachments/assets/a906bce0-50f8-424b-abad-b07c92da3c9b" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L363C1-L373C6

### Description:

The `sellPoolTokens` function is intended to allow users to easily sell pool tokens and receive WETH in exchange. Users indicate how many pool tokens they're willing to sell in the `poolTokenAmount` parameter. However, the function currently miscalculaes the swapped amount.

This is due to the fact that the `swapExactOutput` function is called, whereas the `swapExactInput` function is the one that should be called. Because users specify the exact amount of input tokens, not output.

## Impact:

Users will swap the wrong amount of tokens, which is a severe disruption of protcol functionality.

**Proof of Concept:**

### Proof of Concept:

1. **Setup Environment**: Deploy the `TSwapPool` contract along with a mock `WETH` token contract and a pool token contract on a test blockchain (e.g., Ganache).

2. **Initial State**: Assume the user has `1000` pool tokens and the current exchange rate in the `TSwapPool` contract would ideally allow for swapping these for `50 WETH`.

3. **Perform Swap with Current Implementation**:

   - The user calls `sellPoolTokens` with `1000` pool tokens expecting to receive `50 WETH`.
   - Due to the use of `swapExactOutput`, the contract calculates the amount of WETH to send based on an incorrect assumption about the desired output amount, leading to the user receiving an incorrect amount of WETH (e.g., `45 WETH` instead of `50 WETH`).

4. **Analysis**:

   - By reviewing the transaction details, it's evident that the amount of WETH received by the user does not match the expected amount based on the input pool tokens.
   - This discrepancy confirms that the `sellPoolTokens` function does not handle the token swap as intended, causing users to receive less value than expected.

5. **Conclusion**:
   - The proof of concept demonstrates that the original implementation of `sellPoolTokens` causes users to receive an incorrect amount of WETH due to the misuse of `swapExactOutput`.
## Recommended Mitigation:

Consider changing the implementation to use `swapExactInput` instead of `swapExactOutput`. Note that this would also require changing the `sellPoolTokens` function to accept a new parameter (ie `minWethToReceive` to be passed to `swapExactInput`)

```diff
    function sellPoolTokens(
        uint256 poolTokenAmount,
+       uint256 minWethToReceive,
        ) external returns (uint256 wethAmount) {
-        return swapExactOutput(i_poolToken, i_wethToken, poolTokenAmount, uint64(block.timestamp));
+        return swapExactInput(i_poolToken, poolTokenAmount, i_wethToken, minWethToReceive, uint64(block.timestamp));
    }
```
## <a id='H-04'></a>H-04. In `TSwapPool::_swap` the extra tokens given to users after every `swapCount` breaks the protocol invariant of `x * y = k`   

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/129
<img width="1034" alt="image" src="https://github.com/user-attachments/assets/44859785-8c9e-4366-8538-3bcc1e1a6d2c" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L397C1-L401C10

## Description: The protocol follows a strict invariant of `x * y = k`. Where:

- `x`: The balance of the pool token
- `y`: The balance of WETH
- `k`: The constant product of the two balances

This means, that whenever the balances change in the protocol, the ratio between the two amounts should remain constant, hence the `k`. However, this is broken due to the extra incentive in the `_swap` function. Meaning that over time the protocol funds will be drained.

The follow block of code is responsible for the issue.

```javascript
swap_count++;
if (swap_count >= SWAP_COUNT_MAX) {
  swap_count = 0;
  outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);
}
```

## Impact:

A user could maliciously drain the protocol of funds by doing a lot of swaps and collecting the extra incentive given out by the protocol.

Most simply put, the protocol's core invariant is broken.

## Proof of Concept:

1. A user swaps 10 times, and collects the extra incentive of `1_000_000_000_000_000_000` tokens
2. That user continues to swap untill all the protocol funds are drained

## Proof Of Code

Place the following into `TSwapPool.t.sol`.

```javascript

    function testInvariantBroken() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputWeth = 1e17;

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        poolToken.mint(user, 100e18);
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

        int256 startingY = int256(weth.balanceOf(address(pool)));
        int256 expectedDeltaY = int256(-1) * int256(outputWeth);

        pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(pool));
        int256 actualDeltaY = int256(endingY) - int256(startingY);
        assertEq(actualDeltaY, expectedDeltaY);
    }
```

</details>

## Recommended Mitigation:

Remove the extra incentive mechanism. If you want to keep this in, we should account for the change in the x \* y = k protocol invariant. Or, we should set aside tokens in the same way we do with fees.

```diff
-        swap_count++;
-        // Fee-on-transfer
-        if (swap_count >= SWAP_COUNT_MAX) {
-            swap_count = 0;
-            outputToken.safeTransfer(msg.sender, 1_000_000_000_000_000_000);
-        }
```

    
# Medium Risk Findings

## <a id='M-01'></a>M-01.  `TSwapPool::deposit` is missing deadline check causing transactions to complete even after the deadline
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/125
<img width="1020" alt="image" src="https://github.com/user-attachments/assets/d39d3da9-588b-4502-a764-d4ebd376d2c2" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L120

##Description:
The `deposit` function accepts a deadline parameter, which according to the documentation is "The deadline for the transaction to be completed by". However, this parameter is never used. As a consequence, operationrs that add liquidity to the pool might be executed at unexpected times, in market conditions where the deposit rate is unfavorable.

<!-- MEV attacks -->

## Impact:
Transactions could be sent when market conditions are unfavorable to deposit, even when adding a deadline parameter.

##Proof of Concept:
The `deadline` parameter is unused.

## Recommended Mitigation:
Consider making the following change to the function.

```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint, // LP tokens -> if empty, we can pick 100% (100% == 17 tokens)
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
+      revertIfDeadlinePassed(deadline)
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
```

# Low Risk Findings

## <a id='L-01'></a>L-01. `TSwapPool::LiquidityAdded` event has parameters out of order

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/130
<img width="1009" alt="image" src="https://github.com/user-attachments/assets/2a109dbf-ad82-45ce-8851-08c391dbf494" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L52C1-L56C7

## Description: 
When the `LiquidityAdded` event is emitted in the `TSwapPool::_addLiquidityMintAndTransfer` function, it logs values in an incorrect order. The `poolTokensToDeposit` value should go in the third parameter position, whereas the `wethToDeposit` value should go second.

## Impact:
Event emission is incorrect, leading to off-chain functions potentially malfunctioning.

## Recommended Mitigation:

```diff
- emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+ emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposit);
```
## <a id='L-02'></a>L-02. Default value returned by `TSwapPool::swapExactInput` results in incorrect return value given

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-06-t-swap/s/131
<img width="1011" alt="image" src="https://github.com/user-attachments/assets/7bc99f7d-9889-41b2-9495-3e22a46c0033" />


### Relevant GitHub Links

https://github.com/Cyfrin/2024-06-t-swap/blob/d1783a0ae66f4f43f47cb045e51eca822cd059be/src/TSwapPool.sol#L296C5-L323C1

## Description:

The `swapExactInput` function is expected to return the actual amount of tokens bought by the caller. However, while it declares the named return value `ouput` it is never assigned a value, nor uses an explict return statement.

## Impact:

The return value will always be 0, giving incorrect information to the caller.

## Recommended Mitigation:

```diff
    {
        uint256 inputReserves = inputToken.balanceOf(address(this));
        uint256 outputReserves = outputToken.balanceOf(address(this));

-        uint256 outputAmount = getOutputAmountBasedOnInput(inputAmount, inputReserves, outputReserves);
+        output = getOutputAmountBasedOnInput(inputAmount, inputReserves, outputReserves);

-        if (output < minOutputAmount) {
-            revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
+        if (output < minOutputAmount) {
+            revert TSwapPool__OutputTooLow(outputAmount, minOutputAmount);
        }

-        _swap(inputToken, inputAmount, outputToken, outputAmount);
+        _swap(inputToken, inputAmount, outputToken, output);
    }
```


