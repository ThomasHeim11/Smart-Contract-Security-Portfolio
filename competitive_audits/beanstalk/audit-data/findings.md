# High

### [H-1] ROUNDING INCONSISTENCY IN REWARD DISTRIBUTION

## Summary

The smart contract under review, located in contracts/depot/Depot.sol, exhibits a vulnerability related to the usage of delegatecall within a loop. This practice may lead to multiple accreditations of the same msg.value amount, posing potential risks to the consistency of reward distribution.

### Vulnerability Details

The issue is identified in the code snippet at line 62:

```solidity
(bool success, bytes memory result) = address(this).delegatecall(data[i]);
```

The delegatecall operation is used within a loop without adequate consideration for msg.value, possibly leading to unintended multiple accreditations of the same amount.

## Impact

The impact of this vulnerability could result in incorrect reward distribution or unintended fund allocation. It may lead to financial losses and unexpected behavior in the contract.

## Tools Used

Manual code review

## Recommendation

Review and Restructure Code Logic: Evaluate the necessity of using delegatecall in a loop and ensure that the logic is sound. Consider whether delegatecall should be used outside of the loop or if an alternative approach is more suitable.

Implement Safeguards: If delegatecall within a loop is necessary, implement safeguards to ensure that msg.value is only processed once per loop iteration. Use flags or other mechanisms to track processed values and prevent unintended multiple accreditations.

### [H-2] Unrestricted ETH Transfer Vulnerability in UnwrapAndSendETH Contract

## Summary

The UnwrapAndSendETH contract is designed to unwrap WETH (Wrapped Ether) and send the equivalent amount of ETH to a specified address. However, it contains a vulnerability that allows an attacker to withdraw ETH to arbitrary destinations.

## Vulnerability Details

In the unwrapAndSendETH function, the contract checks the WETH balance and then proceeds to withdraw and transfer the entire balance to the specified address (to) using the call function. The use of call without proper access controls or checks allows any user to invoke this function and receive Ether, potentially leading to unauthorized fund transfers.

(contracts/pipeline/junctions/UnwrapAndSendETH.sol#27-35)

```java
(bool success, ) = to.call{value: address(this).balance}(new bytes(0));

```

## Impact

This vulnerability poses a severe risk as it allows arbitrary users to drain the Ether balance of the contract. Malicious actors can exploit this vulnerability to perform unauthorized fund transfers, leading to financial losses for the contract owner and users relying on the proper functioning of the contract.

## Tools Used

The vulnerability was identified using the Slither static analysis tool, specifically leveraging the "functions-that-send-ether-to-arbitrary-destinations" detector. Slither highlighted the potential risk associated with the use of the call function in the specified contract.

## Recommendations

To mitigate this vulnerability, it is recommended to implement proper access controls in the unwrapAndSendETH function. Consider incorporating a permission system or requiring specific authorization from designated addresses before allowing the transfer of Ether.

### [H-3] Reused Oracle Instance Vulnerability in Oracle Contract

## Summary

The Oracle contract in the provided codebase exhibits a high-severity vulnerability related to the reuse of an Oracle. This vulnerability may lead to inaccurate tracking of Delta B in available pools, potentially impacting the reliability of the system.

## Vulnerability Details

The Oracle contract lacks a clear separation of concerns in terms of tracking the Delta B in available pools. Specifically, the contract seems to be reusing the same Oracle instance across different functionalities or components of the system. This reuse may introduce inconsistencies and unintended side effects in the tracking mechanism, as there is no apparent isolation or scoping of the Oracle's state.

(contracts/beanstalk/sun/SeasonFacet/Oracle.sol#17-27)

```javascript
function stepOracle() internal returns (int256 deltaB) {
    deltaB = LibWellMinting.capture(C.BEAN_ETH_WELL);
    s.season.timestamp = block.timestamp;
}
```

## Impact

The impact of this vulnerability is significant as it can result in inaccurate calculations and tracking of Delta B. If the same Oracle instance is shared among different functionalities, changes in one part of the system may unintentionally affect the Oracle's state, leading to incorrect data and potentially disrupting the intended behavior of the contract.

## Tools Used

Manual review.

## Recommendations

To address this vulnerability, it is recommended to refactor the Oracle contract to ensure proper scoping and isolation of Oracle instances. Each functionality or component of the system that relies on the Oracle should have its own dedicated instance to prevent unintended interactions.

### [H-4] Unchecked Transfer Vulnerability in LibWellConvert.sol

## Summary

The code snippet provided contains a high-severity vulnerability related to an unchecked transfer in the \_wellAddLiquidityTowardsPeg function within the LibWellConvert library. The contract fails to verify the return value of the C.bean().transfer operation, introducing a potential security risk.

## Vulnerability Details

In the \_wellAddLiquidityTowardsPeg function, the C.bean().transfer(well, beansConverted) operation is performed without checking the return value for success or failure. This unchecked transfer can lead to vulnerabilities where the function continues execution even if the transfer fails, allowing an attacker to manipulate the state of the contract without proper detection.

(contracts/libraries/Convert/LibWellConvert.sol#194-207)

```javascript
function _wellAddLiquidityTowardsPeg(
    uint256 beans,
    uint256 minLP,
    address well
) internal returns (uint256 lp, uint256 beansConverted) {
    (uint256 maxBeans, ) = _beansToPeg(well);
    require(maxBeans > 0, "Convert: P must be >= 1.");
    beansConverted = beans > maxBeans ? maxBeans : beans;
    C.bean().transfer(well, beansConverted);
    lp = IWell(well).sync(
        address(this),
        minLP
    );
}
```

## Impact

The impact of this vulnerability is significant as it allows an attacker to exploit the unchecked transfer, potentially causing loss of funds or manipulation of the contract's state. If the C.bean().transfer operation fails, the function proceeds without reverting, leading to unexpected behavior and a potential security breach.

## Tools Used

Manual review and slither.

## Recommendations

To mitigate this vulnerability, it is strongly recommended to check the return value of the C.bean().transfer operation and handle potential failure conditions appropriately. Consider using SafeERC20 or implementing a manual check to ensure that the transfer was successful before proceeding with further operations. This practice is crucial for maintaining the integrity and security of the contract, preventing unauthorized state changes or fund losses.

### [H-5] Uninitialized State Variable Vulnerability in SeasonGettersFacet.sol

## Summary

The SeasonGettersFacet contract in the provided codebase exposes a high-risk vulnerability due to the uninitialized state variable s. This variable is never initialized within the contract, yet it is utilized extensively across various functions, potentially leading to unexpected behavior or vulnerabilities in the system.

## Vulnerability Details

The s state variable in the SeasonGettersFacet contract is utilized in numerous functions without being initialized anywhere within the contract. This lack of initialization poses a significant risk as it may lead to inconsistencies or errors when accessing data stored in this variable.

```javascript
AppStorage internal s;
```

Slither output with location in the SeasonGettersFacet.sol where the variable 's' is used:

    - SeasonGettersFacet.season() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#35-37)
    - SeasonGettersFacet.paused() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#42-44)
    - SeasonGettersFacet.time() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#49-51)
    - SeasonGettersFacet.abovePeg() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#56-58)
    - SeasonGettersFacet.sunriseBlock() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#63-65)
    - SeasonGettersFacet.weather() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#70-72)
    - SeasonGettersFacet.rain() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#77-79)
    - SeasonGettersFacet.plentyPerRoot(uint32) (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#84-86)
    - SeasonGettersFacet.wellOracleSnapshot(address) (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#112-114)
    - SeasonGettersFacet.getSeedGauge() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#137-139)
    - SeasonGettersFacet.getAverageGrownStalkPerBdvPerSeason() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#146-148)
    - SeasonGettersFacet.getBeanToMaxLpGpPerBdvRatio() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#154-156)
    - SeasonGettersFacet.getBeanToMaxLpGpPerBdvRatioScaled() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#162-164)
    - SeasonGettersFacet.getGaugePointsPerBdvForWell(address) (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#182-190)
    - SeasonGettersFacet.getGrownStalkIssuedPerSeason() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#210-219)
    - SeasonGettersFacet.getGrownStalkIssuedPerGp() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#224-238)
    - SeasonGettersFacet.getPodRate() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#243-246)
    - SeasonGettersFacet.getDeltaPodDemand() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#260-264)
    - SeasonGettersFacet.getWeightedTwaLiquidityForWell(address) (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#281-285)
    - SeasonGettersFacet.getGaugePoints(address) (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#312-314)
    - SeasonGettersFacet.getSopWell() (contracts/beanstalk/sun/SeasonFacet/SeasonGettersFacet.sol#322-324)

## Impact

The impact of this vulnerability is severe as it can result in undefined behavior or errors when accessing data stored in the uninitialized s state variable. Depending on the specific context and usage of s within the contract functions, this vulnerability may lead to unexpected outcomes, potential security breaches, or system malfunctions.

## Tools Used

Manual review and slither.

## Recommendations

To mitigate this vulnerability, it is crucial to initialize all state variables properly before accessing or utilizing them within the contract functions. Consider reviewing the contract's initialization logic and ensuring that all state variables are initialized to appropriate values or references before being accessed or utilized within the contract functions.

### [H-6] Reentrancy Vulnerabilitie in Silo.sol

## Summary

Medium-severity reentrancy vulnerability in the \_claimPlenty function of the Silo contract. The vulnerability arises from an external call to sopToken.safeTransfer preceding the modification of state variables, potentially exposing the contract to reentrancy attacks.

## Vulnerability Details

The vulnerability stems from the sequence of operations in the \_claimPlenty function, where tokens are transferred using sopToken.safeTransfer before deleting s.a[account].sop.plenty. This order of operations opens up the possibility of reentrancy attacks, as external calls can be manipulated to re-enter the function before the delete operation is completed.

Code Snippet:(contracts/beanstalk/silo/SiloFacet/Silo.sol#154-164)

```javascript
function _claimPlenty(address account) internal {
    // Plenty is earned in the form of the sop token.
    uint256 plenty = s.a[account].sop.plenty;
    IWell well = IWell(s.sopWell);
    IERC20[] memory tokens = well.tokens();
    IERC20 sopToken = tokens[0] != C.bean() ? tokens[0] : tokens[1];
    sopToken.safeTransfer(account, plenty);
    delete s.a[account].sop.plenty;

    emit ClaimPlenty(account, address(sopToken), plenty);
}

```

Exploit Scenario
An attacker owning a malicious contract could exploit this vulnerability by triggering a reentrancy attack through a fallback function:

```javascript
function fallback() external {
    // Re-enter the vulnerable contract
    vulnerableContract.claimPlenty(msg.sender);
}

```

If the sopToken.safeTransfer call in \_claimPlenty triggers the attacker's fallback function, it could potentially re-enter the vulnerable contract before the delete operation, leading to unexpected state manipulation.

## Impact

The impact of this vulnerability is substantial, warranting a "High" severity rating. A successful exploitation of the reentrancy vulnerability in the \_claimPlenty function could lead to severe consequences. An attacker could manipulate the contract's state during execution, potentially resulting in unauthorized access to funds, unexpected contract behavior, or even a complete compromise of the contract's integrity. Considering the financial nature of the transactions involved, the potential for significant loss is high.

## Tools Used

Manual review and slither.

## Recommendations

Apply Check-Effects-Interactions Pattern: Modify the \_claimPlenty function to follow the "check-effects-interactions" pattern, ensuring that state modifications occur before any external calls. Specifically, consider deleting s.a[account].sop.plenty before executing sopToken.safeTransfer.

### [H-7] Locked Ether Vulnerability in MigrationFacet.sol

## Summary

The MigrationFacet.sol contract has been identified with a potential vulnerability related to locked Ether. The contract contains a payable function (mowAndMigrate) without a corresponding withdrawal mechanism, leading to a risk of permanently locking any Ether sent to the contract.

## Vulnerability Details

The vulnerable contract's mowAndMigrate function is designed to handle migrations of deposits but lacks a proper withdrawal mechanism for any Ether sent to it. This violates best practices for secure contract design.

## Impact

The impact of this vulnerability is the permanent loss of Ether sent to the contract through the mowAndMigrate function. Users sending Ether to this function risk having their funds irreversibly locked within the contract.

## Tools Used

Manual review and slither.

## Recommendations

To address this issue, it is recommended to implement a withdrawal mechanism within the MigrationFacet.sol contract, allowing users to retrieve any Ether sent to the contract.

###[H-8] Reentrancy Vulnerability in BeanstalkERC20.sol

## Summary

High-severity reentrancy vulnerability in the gm function of the SeasonFacet contract. The vulnerability arises from external calls made within the function, specifically to calcCaseIdandUpdate, followed by state variable modifications in stepSun. This sequence of operations could potentially allow for reentrancy attacks.

## Vulnerability Details

The vulnerability involves external calls within the gm function, where calculations and state modifications occur. External calls to calcCaseIdandUpdate are followed by modifications to state variables in stepSun. This pattern could enable reentrancy attacks if the called contracts re-enter the SeasonFacet contract before state modifications are completed.

Code snippet:(contracts/beanstalk/sun/SeasonFacet/SeasonFacet.sol#44-57)

```javascript
function gm(address account, LibTransfer.To mode) public payable returns (uint256) {
    uint256 initialGasLeft = gasleft();

    require(!s.paused, "Season: Paused.");
    require(seasonTime() > s.season.current, "Season: Still current Season.");
    uint32 season = stepSeason();
    int256 deltaB = stepOracle();
    uint256 caseId = calcCaseIdandUpdate(deltaB);
    LibGerminate.endTotalGermination(season, LibWhitelistedTokens.getWhitelistedTokens());
    LibGauge.stepGauge();
    stepSun(deltaB, caseId);

    return incentivize(account, initialGasLeft, mode);
}

```

Exploit Scenario
An attacker could exploit this vulnerability by triggering a reentrancy attack through a fallback function in a malicious contract. If the external calls within gm trigger the attacker's fallback function, they could potentially re-enter the SeasonFacet contract before state modifications are completed, leading to unexpected behavior.

## Impact

The impact of this vulnerability is assessed as high. Successful exploitation could enable reentrancy attacks, allowing an attacker to manipulate the contract's state and exploit unintended behaviors.

## Tools Used

Manual review and slither.

## Recommendations

Apply Check-Effects-Interactions Pattern: Ensure that state modifications are performed before any external calls to prevent reentrancy attacks. Review the sequence of operations in the gm function to ensure that state modifications occur before any external calls.

Use ReentrancyGuard: Consider implementing the ReentrancyGuard pattern in the gm function and other relevant functions to prevent reentrancy attacks. This pattern can help mitigate the risk of reentrancy vulnerabilities by ensuring that functions are not re-entered recursively.

### [H-9] Reentrancy Vulnerability in Weather.sol

## Summary

High-risk reentrancy vulnerability in the sop function of the Weather contract. The vulnerability arises from external calls made within the function before modifying state variables. This sequence of operations could potentially allow for reentrancy attacks.

## Vulnerability Details

The vulnerability occurs in the sop function, where external calls are made to various functions such as C.bean().mint, C.bean().approve, and IWell(sopWell).swapFrom. These calls are followed by modifications to state variables in the rewardSop function. This pattern could enable reentrancy attacks if the called contracts re-enter the Weather contract before state modifications are completed.

Code snippet: (contracts/beanstalk/sun/SeasonFacet/Weather.sol#181-213)

```Javascript
function sop() private {
    // calculate the beans from a sop.
    // sop beans uses the min of the current and instantaneous reserves of the sop well,
    // rather than the twaReserves in order to get bean back to peg.
    address sopWell = s.sopWell;
    (uint256 newBeans, IERC20 sopToken) = calculateSop(sopWell);
    if (newBeans == 0) return;

    uint256 sopBeans = uint256(newBeans);
    uint256 newHarvestable;

    // Pay off remaining Pods if any exist.
    if (s.f.harvestable < s.r.pods) {
        newHarvestable = s.r.pods - s.f.harvestable;
        s.f.harvestable = s.f.harvestable.add(newHarvestable);
        C.bean().mint(address(this), newHarvestable.add(sopBeans));
    } else {
        C.bean().mint(address(this), sopBeans);
    }

    // Approve and Swap Beans for the non-bean token of the SOP well.
    C.bean().approve(sopWell, sopBeans);
    uint256 amountOut = IWell(sopWell).swapFrom(
        C.bean(),
        sopToken,
        sopBeans,
        0,
        address(this),
        type(uint256).max
    );
    rewardSop(amountOut);
    emit SeasonOfPlenty(s.season.current, sopWell, address(sopToken), amountOut, newHarvestable);
}

```

## Impact

The impact of this vulnerability is assessed as high. Successful exploitation could enable reentrancy attacks, allowing an attacker to manipulate the contract's state and exploit unintended behaviors.

## Tools Used

The vulnerability was detected using the Slither tool, specifically its reentrancy vulnerability detection feature.

## Recommendations

Apply Check-Effects-Interactions Pattern: Ensure that state modifications are performed before any external calls to prevent reentrancy attacks. Review the sequence of operations in the sop function to ensure that state modifications occur before any external calls.

Use ReentrancyGuard: Consider implementing the ReentrancyGuard pattern in the sop function and other relevant functions to prevent reentrancy attacks. This pattern can help mitigate the risk of reentrancy vulnerabilities by ensuring that functions are not re-entered recursively.

### [H-10] Reentrancy Vulnerability in Sun.sol

## Summary

A high-risk reentrancy vulnerability in the stepSun function of the Sun contract. The vulnerability occurs due to an external call to rewardBeans before modifying state variables. This sequence of operations could potentially allow for reentrancy attacks.

## Vulnerability Details

The vulnerability is present in the stepSun function, where an external call is made to rewardBeans(uint256(deltaB)). This call is followed by modifications to state variables in the setSoilAbovePeg function. This pattern could enable reentrancy attacks if the called contracts re-enter the Sun contract before state modifications are completed.

```javascript
function stepSun(int256 deltaB, uint256 caseId) internal {
    uint256 newSupply = uint256(deltaB).mul(C.SUPPLY_MULTIPLIER);
    uint256 newHarvestable = rewardBeans(uint256(deltaB));

    setSoilAbovePeg(newHarvestable, caseId);
}

function rewardBeans(uint256 deltaB) internal returns (uint256) {
    uint256 newSupply = uint256(deltaB).mul(C.SUPPLY_MULTIPLIER);
    C.bean().mint(address(this), newSupply);
    return newSupply;
}

function setSoilAbovePeg(uint256 amount, uint256 caseId) internal {
    s.f.soil = amount.toUint128();
    s.season.abovePeg = true;
}

```

## Impact

The impact of this vulnerability is assessed as high. Successful exploitation could enable reentrancy attacks, allowing an attacker to manipulate the contract's state and exploit unintended behaviors.

## Tools Used

Manual review and slither.

## Recommendations

To mitigate the identified reentrancy vulnerability, the following recommendations are proposed:

Apply Check-Effects-Interactions Pattern: Ensure that state modifications are performed before any external calls to prevent reentrancy attacks. Review the sequence of operations in the stepSun function to ensure that state modifications occur before any external calls.

Use ReentrancyGuard: Consider implementing the ReentrancyGuard pattern in the stepSun function and other relevant functions to prevent reentrancy attacks. This pattern can help mitigate the risk of reentrancy vulnerabilities by ensuring that functions are not re-entered recursively.

# Medium

### [M-1] Using ERC721::\_mint() can be dangerous

## Summary

The contract `BeanstalkERC20.sol` contains a vulnerability where the `_mint()` function from the ERC721 standard is used to mint tokens. This can lead to tokens being minted to addresses that do not support ERC721 tokens. The safer alternative `_safeMint()` function should be used instead to prevent potential issues.

## Vulnerability Details

Found in contracts/tokens/ERC20/BeanstalkERC20.sol:

```solidity
// Line 53
_mint(to, amount);
```

The \_mint() function is called to mint tokens to the specified address without considering whether the recipient address supports ERC721 tokens. This can result in tokens being minted to addresses that are not designed to handle ERC721 tokens, leading to potential interoperability issues or loss of tokens.

## Impact

The impact of this vulnerability is significant as it can result in tokens being sent to addresses that are not compatible with ERC721 tokens. This can lead to loss of tokens or interoperability issues, affecting the functionality and usability of the tokens.

## Tools Used

The identification of this vulnerability was done through code review.

## Recommendations

Replace \_mint() with \_safeMint(): Use the \_safeMint() function instead of \_mint() to mint ERC721 tokens. \_safeMint() includes additional checks to ensure that tokens are only minted to addresses that support ERC721 tokens, reducing the risk of interoperability issues.

### [M-2] Division Before Multiplication Vulnerability in Sun.sol

## Summary

The contract Sun.sol has instances of the "Divide before multiply" vulnerability, where division is performed before multiplication. This pattern can lead to precision loss due to Solidity's integer division truncation. The affected functions include Sun.rewardToFertilizer and Sun.setSoilAbovePeg.

## Vulnerability Details

Instance 1: Sun.rewardToFertilizer (contracts/beanstalk/sun/SeasonFacet/Sun.sol#109-149)
Code Snippet:

```javascript
// Sun.sol#117
newBpf = maxNewFertilized.div(s.activeFertilizer);

// Sun.sol#147
newFertilized = newFertilized.add(newBpf.mul(s.activeFertilizer));
```

Description: In the Sun.rewardToFertilizer function, division is performed before multiplication, leading to potential precision loss.

Instance 2: Sun.rewardToFertilizer (contracts/beanstalk/sun/SeasonFacet/Sun.sol#109-149)
Code Snippet:

```javascript
// Sun.sol#117
newBpf = maxNewFertilized.div(s.activeFertilizer);

// Sun.sol#128
newFertilized = newFertilized.add(newBpf.mul(s.activeFertilizer));
```

Description:
Another instance in the same function where division is performed before multiplication, introducing a risk of precision loss.

Instance 3: Sun.setSoilAbovePeg (contracts/beanstalk/sun/SeasonFacet/Sun.sol#216-224)
Code Snippet:

```javascript
// Sun.sol#217
newSoil = newHarvestable.mul(100).div(100 + s.w.t);

// Sun.sol#221
newSoil = newSoil.mul(SOIL_COEFFICIENT_LOW).div(C.PRECISION);
```

Description:
In the Sun.setSoilAbovePeg function, division is performed before multiplication, potentially leading to precision loss.

Instance 4: Sun.setSoilAbovePeg (contracts/beanstalk/sun/SeasonFacet/Sun.sol#216-224)
Code Snippet:

```javascript
// Sun.sol#219
newSoil = newSoil.mul(SOIL_COEFFICIENT_HIGH).div(C.PRECISION);

// Sun.sol#221
newSoil = newSoil.mul(SOIL_COEFFICIENT_LOW).div(C.PRECISION);
```

Another instance in the same function where division is performed before multiplication, introducing a risk of precision loss.

## Impact

Performing division before multiplication can lead to precision loss, potentially affecting the accuracy of calculations and introducing unexpected behavior in the contract. It may result in incorrect distribution of rewards or misallocation of resources.

## Tools Used

Manual review and slither.

## Recommendations

It's recommended to reorder the arithmetic operations to perform multiplication before division to prevent precision loss. Review and update the relevant calculations in the affected functions accordingly.

# Low

### [L-1] Missing zero address validation UnwrapAndSendETH.sol

## Summary

Missing zero address validation vulnerability in the provided contract. The vulnerability arises from not checking whether the provided address (newOwner) is zero before updating the owner in the updateOwner function.

## Vulnerability Details

The vulnerability is present in the updateOwner function, where the newOwner address is not validated for being the zero address before updating the contract's owner. This could lead to unintended consequences, such as losing ownership of the contract if the updateOwner function is called without specifying a new owner.

Code snippet:

```javascript
contract UnwrapAndSendETH {
    // Other code...

    address public immutable WETH;

    constructor(address wethAddress) {
        // Vulnerability: Missing zero-check
        WETH = wethAddress;
    }

    function unwrapAndSendETH(address to) external {
        uint256 wethBalance = IWETH(WETH).balanceOf(address(this));
        require(wethBalance > 0, "Insufficient WETH");

        // Vulnerability: Missing zero-check
        (bool success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, "Eth transfer Failed.");
    }
}

```

## Impact

The impact of these vulnerabilities is dependent on the context in which the contract is used. If the zero address is unintentionally used as the wethAddress during deployment or if the to address is the zero address during a call to unwrapAndSendETH, it could lead to unexpected behavior, including failed transfers or unintended transfers to the zero address.

## Tools Used

The vulnerability was detected using the Slither tool, specifically its missing zero address validation check.

## Recommendations

To mitigate the identified vulnerabilities, the following recommendations are proposed:

Zero-Check in Constructor: Add a check in the constructor to ensure that the provided wethAddress is not the zero address before assigning it to the WETH state variable.

Zero-Check in unwrapAndSendETH: Add a check in the unwrapAndSendETH function to ensure that the provided to address is not the zero address before initiating the transfer.

Use require or revert: Instead of using throw, consider using require or revert for better readability and to conform with modern Solidity practices.

Example :

```javascript
require(wethAddress != address(0), "Invalid WETH address");
// ...
require(to != address(0), "Invalid 'to' address");
```

### [L-2] Timestamp Vulnerabilities LibChainlinkOracle.sol

## Summary

The contract utilizes block.timestamp for comparisons, which can be manipulated , posing a security risk. Additionally, the use of assembly in the contract is flagged as potentially error-prone.

## Vulnerability Details

The contract LibChainlinkOracle.sol uses block.timestamp for comparisons, which can be manipulated by miners. This introduces a potential security risk, especially when relying on timestamps for critical decisions.

```javascript
// Example from LibChainlinkOracle.sol
function getEthUsdTwap(uint256 timestamp) internal view returns (int256) {
    require(timestamp > 0, "Invalid timestamp");
    require(timestamp <= endTimestamp, "Timestamp exceeds endTimestamp");
    // ...
}

function checkForInvalidTimestampOrAnswer(uint256 timestamp, int256 answer, uint256 currentTimestamp) internal view {
    require(timestamp == 0 || timestamp > currentTimestamp, "Invalid timestamp");
    require(currentTimestamp.sub(timestamp) > CHAINLINK_TIMEOUT, "Timeout exceeded");
    // ...
}

```

## Impact

The impact of relying on block.timestamp for critical decisions is assessed as low.

## Tools Used

The vulnerability was detected using the Slither tool, specifically its timestamp vulnerability detection feature.

## Recommendations

To mitigate the identified vulnerabilities, the following recommendations are proposed:

Avoid Relying on block.timestamp: Consider alternative approaches for generating randomness or making critical decisions that do not rely solely on block.timestamp. Using external oracles or combining multiple sources of randomness can enhance the security of such systems.

Use Secure Timekeeping Mechanisms: If reliance on timestamps is necessary, consider using mechanisms such as block numbers or external oracles that are less susceptible to manipulation by miners.

Avoid Assembly Usage: Given the potential risks associated with assembly, it is recommended to avoid its usage. Use higher-level, more readable constructs in Solidity to reduce the likelihood of introducing errors.

### [L-3] Missing Error Messages in Revert Statements

## Summary

This findings report outlines two low-risk errors identified during the code review:

The revert statement within the calcGaugePoints function on line 199 of LibGauge.sol.
The revert statement within the beanDenominatedValue function on line 449 of LibTokenSilo.sol.

## Vulnerability Details

1. calcGaugePoints function in LibGauge.sol (Line 199):
   In the calcGaugePoints function at line 199 of LibGauge.sol, a revert statement is identified. Further analysis reveals that this revert statement could potentially lead to unexpected behavior or undesired outcomes. A more informative error message and additional context could enhance the clarity of the code.

```javascript
if (data.length == 0) revert();
```

2. beanDenominatedValue function in LibTokenSilo.sol (Line 449):
   In the beanDenominatedValue function at line 449 of LibTokenSilo.sol, a revert statement is identified. Similar to the previous case, providing more context and a detailed error message can aid developers in understanding the reason for the revert.

```javascript
if (result.length < 68) revert();
```

## Impact

Both instances are considered low-risk, as they may not directly compromise the security of the contract. However, the lack of detailed information in the revert statements could hinder debugging efforts and make it challenging for developers to identify the root cause of unexpected conditions.

## Tools Used

The findings were identified through manual code review and analysis. No specific automated tools were used for this assessment.

## Recommendations

Improve Error Messages:
Enhance the revert statements in the calcGaugePoints and beanDenominatedValue functions with informative error messages, providing specific details about the unexpected conditions or reasons for the reverts. This will assist developers in diagnosing issues more effectively.

### [L-4] Unsafe ABI Encoding

## Summary

This findings report highlights instances of unsafe ABI encodings identified within the codebase. The occurrences are found in various contracts, including LibEvaluate.sol, LibGauge.sol, LibTokenSilo.sol, and LibWhitelist.sol. These unsafe ABI encodings pose a risk due to potential errors caused by lack of type safety and vulnerability to typos.

## Vulnerability Details

LibEvaluate.sol (Line 331):
Unsafe ABI encoding is used on line 331 of LibEvaluate.sol.

```javascript
 bytes memory callData = abi.encodeWithSelector(lwSelector);
```

LibGauge.sol (Line 191):
Unsafe ABI encoding is used on line 191 of LibGauge.sol.

```javascript
   bytes memory callData = abi.encodeWithSelector(
```

LibTokenSilo.sol (Line 467, 469):
Unsafe ABI encoding is used on lines 467 and 469 of LibTokenSilo.sol.

```javascript
        callData = abi.encodeWithSelector(selector, amount);
        } else if (encodeType == 0x01) {
            callData = abi.encodeWithSelector(selector, token, amount);
```

LibWhitelist.sol (Line 236, 245):
Unsafe ABI encoding is used on lines 236 and 245 of LibWhitelist.sol.

```javascript
(bool success, ) = address(this).staticcall(abi.encodeWithSelector(selector, 0, 0, 0));


(bool success, ) = address(this).staticcall(abi.encodeWithSelector(selector));

```

## Impact

The usage of unsafe ABI encodings can lead to various risks, including:

Type Mismatch: Inappropriate parameter types passed to function calls can result in unexpected behavior or runtime errors.

Typo Vulnerabilities: Mistakes in function signatures due to typos can lead to unintended function calls or failures.

Security Risks: Lack of type safety and typo vulnerabilities increase the likelihood of contract vulnerabilities and potential exploits.

## Tools Used

The findings were identified through manual code review and analysis. No specific automated tools were used for this assessment.

## Recommendations

Replace with abi.encodeCall:
Consider replacing all instances of unsafe ABI encodings with abi.encodeCall. This method provides type safety by verifying whether the supplied values match the expected types of the called function parameters. It also reduces the risk of errors caused by typos.
