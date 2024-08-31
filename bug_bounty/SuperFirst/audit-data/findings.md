Comming soon...

# High

## H-1 Vulnerability in Random Number Generation Using Weak PRNG in SuperFirst.getRand Function

## Bug Description

The function `SuperFirst.getRand(uint256 _blockNumber, uint256 _salt, address _player)` in the provided code snippet uses a weak pseudo-random number generator (PRNG). The randomness is derived from `blockhash`, `_salt`, and `_player`, which can be influenced by miners. This approach to generating random numbers is considered insecure because miners can manipulate the blockhash to gain an advantage.

## Impact

The use of a weak PRNG in the `getRand` function poses a significant security risk. Miners can influence the outcome by controlling or predicting the `blockhash` used in the calculation, leading to potential manipulation of game mechanics or any other application relying on this randomness. This can result in unfair advantages and compromise the integrity of the system.

## Risk Breakdown

- **Difficulty to Exploit**: Easy
- **Weakness**: Weak PRNG due to reliance on `blockhash`, which can be influenced by miners.
- **Remedy Vulnerability Scoring System 1.0 Score**: 9.0 (High Severity)

## Recommendation

To mitigate this issue, avoid using `blockhash`, `block.timestamp`, or any other block-related values for randomness. Instead, implement a more secure source of randomness such as Chainlink VRF (Verifiable Random Function). Chainlink VRF provides cryptographic guarantees that the randomness is tamper-proof, as it is generated and verified in a decentralized manner.

## References

- [Crytic Slither Detector Documentation: Weak PRNG](https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG)
- [Chainlink VRF](https://docs.chain.link/vrf/v2/introduction)

## Proof Of Concept

### Vulnerable Code

```javascript
function getRand(uint256 _blockNumber, uint256 _salt, address _player) internal view returns (uint256) {
    require(block.number > _blockNumber, "Block number is out of range");
    if (_blockNumber + 250 < block.number) {
        return 0;
    }
    return (uint256(keccak256(abi.encodePacked((blockhash(_blockNumber)), _salt, _player))) % numberOfBoxes) + 1;
}
```

### Exploit Scenario

- Setup: Eve is a miner and a player in a game that uses the getRand function to determine rewards.
- Action: Eve calls a function that uses getRand to generate a random number for determining rewards.
- Manipulation: As a miner, Eve can influence the blockhash by re-ordering the block containing her transaction.
- Outcome: By controlling the blockhash, Eve can predict or manipulate the random number to gain an unfair advantage, thereby compromising the fairness of the game.

### Secure Code Example Using Chainlink VRF v2

```javascript
// Import Chainlink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract SecureRandom is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    )
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        s_owner = msg.sender;
    }

    function requestRandomWords() external onlyOwner {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        s_randomWords = randomWords;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}

```

This secure implementation uses Chainlink VRF v2 to ensure that the random number generated is verifiable and tamper-proof, thereby maintaining the integrity and fairness of the application.

# Medium

## M-1 Reentrancy Vulnerability Discovered in SuperFirst.play(uint256) Function in Context.sol

## Bug Description

The `SuperFirst.play(uint256)` function in `Context.sol` contains a reentrancy vulnerability. The function makes external calls to `address(address(bankrollContract)).sendValue(msg.value)` and `distributeReward(msg.sender)`, which in turn calls `bankrollContract.sendFTN(_player, totalWin)`. Following these external calls, the function modifies the state variable `bets[msg.sender]` by pushing a new `Bet` object into it. This sequence allows for potential reentrancy attacks as the state update happens after the external calls.

## Impact

An attacker could exploit this reentrancy vulnerability to repeatedly call the `play` function before the state is updated, potentially allowing the attacker to drain funds or manipulate the contract’s state to their advantage.

## Risk Breakdown

- **Difficulty to Exploit:** Easy
- **Weakness:** Reentrancy
- **Remedy Vulnerability Scoring System 1.0 Score:** TBD
- **Severity:** Medium
- **Confidence:** Medium

## Recommendation

Apply the check-effects-interactions pattern by updating the state variables before making any external calls. This approach ensures that the contract’s state is not left in a vulnerable position where it can be exploited through reentrant calls.

## References

- [Slither Documentation on Reentrancy Vulnerabilities](https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1)
- [Solidity Documentation on Reentrancy](https://soliditylang.org/docs/v0.8.0/security-considerations.html#reentrancy)

## Proof Of Concept

The vulnerability can be illustrated with the following code snippet:

```solidity
function play(uint256 _boxNumber) external payable {
    // External calls that can be exploited
    address(address(bankrollContract)).sendValue(msg.value);
    distributeReward(msg.sender);  // This internally calls bankrollContract.sendFTN(_player, totalWin)

    // State variable update after external calls
    bets[msg.sender].push(Bet(block.number, msg.value, _boxNumber, salt, msg.sender));
}
```

An attacker can create a contract that re-enters the play function before the state update to manipulate the contract’s state or drain funds.

### Exploit Scenario

- The attacker calls play function from a contract.
- The play function sends Ether and calls distributeReward.
- Before the state variable bets is updated, the attacker’s contract re-enters play.
- The state is manipulated or funds are drained by repeating the process.

## M-2 Centralization Risk in SuperFirst Contract Due to Privileged Owner Controls

## Bug Description

The contract SuperFirst in Context.sol exhibits centralization risks due to the significant control and privileged rights assigned to its owner. The owner is entrusted with executing critical administrative tasks which include renouncing ownership, transferring ownership, withdrawing funds, setting crucial parameters, and more. This centralization necessitates absolute trust in the owner to act in the best interest of all stakeholders and to not engage in malicious activities or mismanagement of funds.

## Impact

The centralization of control in the hands of a single owner poses several risks:

- Malicious Updates: The owner has the ability to modify contract parameters or transfer ownership to a malicious entity.
- Fund Drainage: The owner can withdraw significant funds from the contract, potentially leading to financial losses for other users.
- Operational Dependence: The contract's functioning and security are highly dependent on the integrity and availability of the owner.

## Risk Breakdown

Difficulty to Exploit: Easy
Weakness: Centralization of administrative control
Remedy Vulnerability Scoring System 1.0 Score: Medium

## Recommendation

To mitigate centralization risks, consider the following recommendations:

- Implement a multi-signature (multisig) wallet to distribute control among multiple trusted parties.
- Introduce time-lock mechanisms for critical functions to allow users to react to potentially malicious actions.
- Adopt a decentralized governance model where key decisions require community approval.

## References

https://arxiv.org/abs/2312.06510

## Proof Of Concept

The centralization risks were identified in the following lines:

```javascript
// src/Context.sol#69
function renounceOwnership() public virtual onlyOwner {
    //...
}

// src/Context.sol#77
function transferOwnership(address newOwner) public virtual onlyOwner {
    //...
}

// src/Context.sol#534
contract SuperFirst is Ownable, ReentrancyGuard {
    //...
}

// src/Context.sol#591
function withdrawFTN(uint256 _amount) external onlyOwner {
    //...
}

// src/Context.sol#601
function setBankrollContract(IBankroll _bankrollContract) external onlyOwner {
    //...
}

// src/Context.sol#610
function setMinBet(uint256 _minBet) external onlyOwner notZero(_minBet) {
    //...
}

// src/Context.sol#618
function setMaxBet(uint256 _maxBet) external onlyOwner notZero(_maxBet) {
    //...
}

// src/Context.sol#626
function setWinCoefficient(uint256 _winCoefficient) external onlyOwner notZero(_winCoefficient) {
    //...
}

// src/Context.sol#634
function setNumberOfBoxes(uint256 _numberOfBoxes) external onlyOwner notZero(_numberOfBoxes) {
    //...
}
```

These lines of code illustrate the extensive privileges granted to the owner, highlighting the centralization risk inherent in the contract's design.
