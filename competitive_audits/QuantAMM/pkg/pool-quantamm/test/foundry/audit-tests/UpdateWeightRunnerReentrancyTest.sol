pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/mock/MockUpdateWeightRunner.sol";
import "../../../contracts/mock/MockQuantAMMBasePool.sol";
import "../../../contracts/mock/mockRules/MockUpdateRule.sol";
import "../../../contracts/mock/MockChainlinkOracles.sol";
import "@balancer-labs/v3-interfaces/contracts/pool-quantamm/IUpdateRule.sol";

contract UpdateWeightRunnerReentrancyTest is Test {
    MockUpdateWeightRunner internal updateWeightRunner;
    MockChainlinkOracle internal chainlinkOracle;
    MockQuantAMMBasePool internal mockPool;
    MockUpdateRule internal mockRule;
    address internal owner;
    address internal addr1;
    address internal addr2;

    uint16 constant UPDATE_INTERVAL = 1800;

    function setUp() public {
        (address ownerLocal, address addr1Local, address addr2Local) = (vm.addr(1), vm.addr(2), vm.addr(3));
        owner = ownerLocal;
        addr1 = addr1Local;
        addr2 = addr2Local;

        // Deploy UpdateWeightRunner contract
        vm.startPrank(owner);
        updateWeightRunner = new MockUpdateWeightRunner(owner, addr2, false);
        vm.stopPrank();

        // Deploy Mock Rule and Pool
        mockRule = new MockUpdateRule(address(updateWeightRunner));
        mockPool = new MockQuantAMMBasePool(UPDATE_INTERVAL, address(updateWeightRunner));
    }

    //@audit
    function testReentrancyCalculateMultiplierAndSetWeightsFromRule() public {
        // Deploy the malicious contract
        MaliciousContract malicious = new MaliciousContract(address(updateWeightRunner), address(mockPool));

        // Set approved actions for the pool
        vm.startPrank(owner);
        updateWeightRunner.setApprovedActionsForPool(address(mockPool), 32);
        vm.stopPrank();

        // Deploy and approve the oracle
        chainlinkOracle = new MockChainlinkOracle(1000, 3600);
        vm.startPrank(owner);
        updateWeightRunner.addOracle(OracleWrapper(chainlinkOracle));
        vm.stopPrank();

        // Set the rule for the pool to be the MaliciousContract instead of mockRule
        address[][] memory oracles = new address[][](1);
        oracles[0] = new address[](1);
        oracles[0][0] = address(chainlinkOracle);

        uint64[] memory lambda = new uint64[](1);
        lambda[0] = 0.0000000005e18;

        vm.startPrank(owner);
        updateWeightRunner.setRuleForPool(
            IQuantAMMWeightedPool.PoolSettings({
                assets: new IERC20[](0),
                rule: IUpdateRule(address(malicious)),
                oracles: oracles,
                updateInterval: 100,
                lambda: lambda,
                epsilonMax: 0.2e18,
                absoluteWeightGuardRail: 0.2e18,
                maxTradeSizeRatio: 0.2e18,
                ruleParameters: new int256[][](0),
                poolManager: addr2
            })
        );
        vm.stopPrank();

        // Fund the contract with ETH
        vm.deal(address(updateWeightRunner), 10 ether);

        // Log funds before the attack
        console.log("Attacker funds before attack:", address(malicious).balance);
        console.log("Smart contract funds before attack:", address(updateWeightRunner).balance);

        // Set up the parameters for the function call
        int256[] memory currentWeights = new int256[](1);
        currentWeights[0] = 1 * 1e18;
        int256[] memory updatedWeights = new int256[](1);
        updatedWeights[0] = 2 * 1e18;
        UpdateWeightRunner.CalculateMuliplierAndSetWeightsLocal memory params = UpdateWeightRunner
            .CalculateMuliplierAndSetWeightsLocal({
            currentWeights: currentWeights,
            updatedWeights: updatedWeights,
            updateInterval: 1 * 1e18,
            absoluteWeightGuardRail18: 1 * 1e18,
            poolAddress: address(mockPool)
        });

        // Attempt to call the function through the malicious contract and expect a reentrancy revert
        vm.expectRevert("ONLYRULECANSETWEIGHTS");
        malicious.callCalculateMultiplierAndSetWeightsFromRule(params);

        // Log funds after the attack
        console.log("Attacker funds after attack:", address(malicious).balance);
        console.log("Smart contract funds after attack:", address(updateWeightRunner).balance);

        // Check if reentrancy was attempted and blocked
        assertEq(address(malicious).balance, 0, "Reentrancy attack should not drain funds");
        assertEq(address(updateWeightRunner).balance, 10 ether, "Smart contract funds should remain intact");
    }
}

// Malicious contract to test reentrancy
contract MaliciousContract {
    UpdateWeightRunner public updateWeightRunner;
    address public mockPool;
    bool private isReentered;

    constructor(address _updateWeightRunner, address _mockPool) {
        updateWeightRunner = UpdateWeightRunner(_updateWeightRunner);
        mockPool = _mockPool; //changed
        isReentered = false;
    }

    function callCalculateMultiplierAndSetWeightsFromRule(
        UpdateWeightRunner.CalculateMuliplierAndSetWeightsLocal memory params
    ) public {
        updateWeightRunner.calculateMultiplierAndSetWeightsFromRule(params);
    }

    // Fallback function to attempt reentrancy
    fallback() external payable {
        // Reenter only once, ensuring the second call triggers the reentrancy guard.
        if (!isReentered && address(updateWeightRunner).balance > 0) {
            isReentered = true;
            UpdateWeightRunner.CalculateMuliplierAndSetWeightsLocal memory params = UpdateWeightRunner
                .CalculateMuliplierAndSetWeightsLocal({
                currentWeights: new int256[](1),
                updatedWeights: new int256[](1),
                updateInterval: 1e18,
                absoluteWeightGuardRail18: 1e18,
                // IMPORTANT: use mockPool, not the UpdateWeightRunner address
                poolAddress: mockPool //changed
            });
            updateWeightRunner.calculateMultiplierAndSetWeightsFromRule(params);
        }
    }
}
