# MyCut - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Precision Errors and Array Inconsistencies in closePot Function Lead to Misallocation of Rewards in Pot.sol](#H-01)




# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #23

### Dates: Aug 29th, 2024 - Sep 5th, 2024

[See more contest details here](https://codehawks.cyfrin.io/c/2024-08-MyCut)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 1
- Medium: 0
- Low: 0


# High Risk Findings

## <a id='H-01'></a>H-01. Precision Errors and Array Inconsistencies in closePot Function Lead to Misallocation of Rewards in Pot.sol            

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-08-MyCut/s/75
<img width="1012" alt="image" src="https://github.com/user-attachments/assets/fedd8a2c-c9b2-43c3-aa04-c62e625a630b" />

## Summary

During the testing phase of the Pot smart contract, critical discrepancies were identified in the reward distribution among claimants and the contract owner. The root of these issues was traced to precision errors in mathematical calculations and inconsistent array referencing. Post-refactoring, these issues were resolved, confirming the presence of significant bugs in the original implementation. This detailed report outlines the identified vulnerabilities, provides a proof of concept (PoC) test case, and offers recommendations to prevent future occurrences of such vulnerabilities.

## Vulnerability Details

### Precision Errors in Division

* **Issue:** The function originally calculated `managerCut` as `remainingRewards / managerCutPercent`. This integer division could lead to significant truncation errors since Solidity does not handle fractional values.
* **Example:** If `remainingRewards` were 1,000 and `managerCutPercent` were 11, the calculation `1000 / 11` would result in 90, discarding the fractional part entirely.

### Inconsistent Array Referencing

* **Issue:** The for-loop iterated over `claimants` while the calculation of `claimantCut` used `i_players.length`. This discrepancy could lead to an out-of-bounds error or fail to distribute rewards correctly if the lengths of `claimants` and `i_players` differed.

## Impact

### Precision Errors in Division

* **Severity:** Medium
* **Impact:** The truncation of fractional values during division leads to inaccurate reward distributions. Specifically, the owner (`managerCut`) and players (`claimantCut`) might receive less than their intended share, resulting in financial discrepancies.

### Inconsistent Array Referencing

* **Severity:** Low to Medium
* **Impact:** Using differing arrays for calculations and iteration can lead to mismatched reward distributions or potential out-of-bounds errors, causing incomplete or erroneous payouts to claimants.

## Poc

* Add PotTest.sol to the test folder:

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Pot} from "../src/Pot.sol";
import {ERC20Mock} from "./ERC20Mock.sol";

contract PotTest is Test {
    Pot pot;
    ERC20Mock token;

    address owner = address(0x1);
    address player1 = address(0x2);
    address player2 = address(0x3);

    function setUp() public {
        token = new ERC20Mock("Test Token", "TTK", address(this), 0);

        address[] memory players = new address[](2);
        players[0] = player1;
        players[1] = player2;

        uint256[] memory rewards = new uint256[](2);
        rewards[0] = 50;
        rewards[1] = 50;

        vm.prank(owner);
        pot = new Pot(players, rewards, token, 100 * 10 ** 18);

        token.mint(address(pot), 100 * 10 ** 18);
    }

    function testDivisionPrecision() public {
        vm.warp(block.timestamp + 90 days);

        uint256 ownerInitialBalance = token.balanceOf(owner);
        uint256 player1InitialBalance = token.balanceOf(player1);
        uint256 player2InitialBalance = token.balanceOf(player2);

        console.log("Initial owner balance: ", ownerInitialBalance);
        console.log("Initial player1 balance: ", player1InitialBalance);
        console.log("Initial player2 balance: ", player2InitialBalance);

        vm.prank(owner);
        pot.closePot();

        uint256 ownerFinalBalance = token.balanceOf(owner);
        uint256 player1FinalBalance = token.balanceOf(player1);
        uint256 player2FinalBalance = token.balanceOf(player2);

        console.log("Final owner balance: ", ownerFinalBalance);
        console.log("Final player1 balance: ", player1FinalBalance);
        console.log("Final player2 balance: ", player2FinalBalance);

        uint256 expectedManagerCut = 10 * 10 ** 18;
        uint256 expectedPlayerCut = 45 * 10 ** 18;

        assertEq(ownerFinalBalance - ownerInitialBalance, expectedManagerCut, "Owner balance mismatch");
        assertEq(player1FinalBalance - player1InitialBalance, expectedPlayerCut, "Player1 balance mismatch");
        assertEq(player2FinalBalance - player2InitialBalance, expectedPlayerCut, "Player2 balance mismatch");
    }
}

```

* Run: `forge test --match-contract PotTest -vvv`
* Failure Details:

  ```Solidity
  [FAIL. Reason: Player1 balance mismatch: 0 != 45000000000000000000] testDivisionPrecision() (gas: 78674)

  ```

  #### Logs:

  ```Solidity
  Initial owner balance: 0
  Initial player1 balance: 0
  Initial player2 balance: 0
  Final owner balance: 10000000000000000000
  Final player1 balance: 0
  Final player2 balance: 0
  ```

## Tools Used 

* Foundry 

## Recommendations

Refactored closePot Function

```diff
function closePot() external onlyOwner {
    require(block.timestamp - i_deployedAt >= 90 days, "Pot is still open for claim");

    if (remainingRewards > 0) {
        uint256 managerCut = (remainingRewards * managerCutPercent) / 100;
        i_token.transfer(msg.sender, managerCut);

        uint256 totalClaimantRewards = remainingRewards - managerCut;
        uint256 claimantCut = totalClaimantRewards / i_players.length;

        for (uint256 i = 0; i < i_players.length; i++) {
            _transferReward(i_players[i], claimantCut);
        }
    }
}

```

* Run ' forge test --match-contract PotTest -vvv' again.
* You will now see it passing the test :
  #### Test Results:
  ##### **Passed:**
  ```Solidity
  [PASS] testDivisionPrecision() (gas: 125145)

  ```

  ##### Logs:
  ```Solidity
  Initial owner balance: 0
  Initial player1 balance: 0
  Initial player2 balance: 0
  Final owner balance: 10000000000000000000
  Final player1 balance: 45000000000000000000
  Final player2 balance: 4500000000000000000

  ```



    





