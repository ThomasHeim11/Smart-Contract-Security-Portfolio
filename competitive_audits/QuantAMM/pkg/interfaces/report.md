# Aderyn Analysis Report

This report was generated by [Aderyn](https://github.com/Cyfrin/aderyn), a static analysis tool built by [Cyfrin](https://cyfrin.io), a blockchain security company. This report is not a substitute for manual audit or security review. It should not be relied upon for any purpose other than to assist in the identification of potential security vulnerabilities.
# Table of Contents

- [Summary](#summary)
  - [Files Summary](#files-summary)
  - [Files Details](#files-details)
  - [Issue Summary](#issue-summary)
- [Low Issues](#low-issues)
  - [L-1: Solidity pragma should be specific, not wide](#l-1-solidity-pragma-should-be-specific-not-wide)
  - [L-2: PUSH0 is not supported by all chains](#l-2-push0-is-not-supported-by-all-chains)
- [NC Issues](#nc-issues)
  - [NC-1: Functions not used internally could be marked external](#nc-1-functions-not-used-internally-could-be-marked-external)
  - [NC-2: Event is missing `indexed` fields](#nc-2-event-is-missing-indexed-fields)


# Summary

## Files Summary

| Key | Value |
| --- | --- |
| .sol Files | 41 |
| Total nSLOC | 1848 |


## Files Details

| Filepath | nSLOC |
| --- | --- |
| contracts/pool-gyro/IGyro2CLPPool.sol | 11 |
| contracts/pool-quantamm/IQuantAMMWeightedPool.sol | 62 |
| contracts/pool-quantamm/IUpdateRule.sol | 19 |
| contracts/pool-quantamm/IUpdateWeightRunner.sol | 72 |
| contracts/pool-quantamm/OracleWrapper.sol | 11 |
| contracts/pool-stable/IStablePool.sol | 41 |
| contracts/pool-utils/IPoolInfo.sol | 21 |
| contracts/pool-weighted/IWeightedPool.sol | 22 |
| contracts/solidity-utils/helpers/IAuthentication.sol | 5 |
| contracts/solidity-utils/helpers/IPoolVersion.sol | 4 |
| contracts/solidity-utils/helpers/IRateProvider.sol | 4 |
| contracts/solidity-utils/helpers/IVersion.sol | 4 |
| contracts/solidity-utils/misc/IWETH.sol | 6 |
| contracts/test/IStdMedusaCheats.sol | 34 |
| contracts/test/IVaultAdminMock.sol | 42 |
| contracts/test/IVaultExtensionMock.sol | 24 |
| contracts/test/IVaultMainMock.sol | 206 |
| contracts/test/IVaultMock.sol | 9 |
| contracts/test/IVaultStorageMock.sol | 10 |
| contracts/vault/IAuthorizer.sol | 4 |
| contracts/vault/IBasePool.sol | 16 |
| contracts/vault/IBasePoolFactory.sol | 18 |
| contracts/vault/IBatchRouter.sol | 61 |
| contracts/vault/IBufferRouter.sol | 30 |
| contracts/vault/ICompositeLiquidityRouter.sol | 73 |
| contracts/vault/IERC20MultiTokenErrors.sol | 4 |
| contracts/vault/IHooks.sol | 73 |
| contracts/vault/IPoolLiquidity.sol | 31 |
| contracts/vault/IProtocolFeeController.sol | 58 |
| contracts/vault/IRouter.sol | 193 |
| contracts/vault/IRouterCommon.sol | 40 |
| contracts/vault/ISwapFeePercentageBounds.sol | 5 |
| contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol | 5 |
| contracts/vault/IVault.sol | 10 |
| contracts/vault/IVaultAdmin.sol | 71 |
| contracts/vault/IVaultErrors.sol | 85 |
| contracts/vault/IVaultEvents.sol | 83 |
| contracts/vault/IVaultExplorer.sol | 91 |
| contracts/vault/IVaultExtension.sol | 92 |
| contracts/vault/IVaultMain.sol | 27 |
| contracts/vault/VaultTypes.sol | 171 |
| **Total** | **1848** |


## Issue Summary

| Category | No. of Issues |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 2 |
| NC | 2 |


# Low Issues

## L-1: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

- Found in contracts/pool-gyro/IGyro2CLPPool.sol [Line: 3](contracts/pool-gyro/IGyro2CLPPool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/pool-quantamm/IQuantAMMWeightedPool.sol [Line: 2](contracts/pool-quantamm/IQuantAMMWeightedPool.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-quantamm/IUpdateRule.sol [Line: 2](contracts/pool-quantamm/IUpdateRule.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-quantamm/IUpdateWeightRunner.sol [Line: 2](contracts/pool-quantamm/IUpdateWeightRunner.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-quantamm/OracleWrapper.sol [Line: 2](contracts/pool-quantamm/OracleWrapper.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-stable/IStablePool.sol [Line: 3](contracts/pool-stable/IStablePool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/pool-utils/IPoolInfo.sol [Line: 3](contracts/pool-utils/IPoolInfo.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/pool-weighted/IWeightedPool.sol [Line: 3](contracts/pool-weighted/IWeightedPool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IAuthentication.sol [Line: 3](contracts/solidity-utils/helpers/IAuthentication.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IPoolVersion.sol [Line: 3](contracts/solidity-utils/helpers/IPoolVersion.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IRateProvider.sol [Line: 3](contracts/solidity-utils/helpers/IRateProvider.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IVersion.sol [Line: 3](contracts/solidity-utils/helpers/IVersion.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/misc/IWETH.sol [Line: 3](contracts/solidity-utils/misc/IWETH.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IStdMedusaCheats.sol [Line: 3](contracts/test/IStdMedusaCheats.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultAdminMock.sol [Line: 3](contracts/test/IVaultAdminMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultExtensionMock.sol [Line: 3](contracts/test/IVaultExtensionMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultMainMock.sol [Line: 3](contracts/test/IVaultMainMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultMock.sol [Line: 3](contracts/test/IVaultMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultStorageMock.sol [Line: 3](contracts/test/IVaultStorageMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IAuthorizer.sol [Line: 3](contracts/vault/IAuthorizer.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBasePool.sol [Line: 3](contracts/vault/IBasePool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBasePoolFactory.sol [Line: 3](contracts/vault/IBasePoolFactory.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBatchRouter.sol [Line: 3](contracts/vault/IBatchRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBufferRouter.sol [Line: 3](contracts/vault/IBufferRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/ICompositeLiquidityRouter.sol [Line: 3](contracts/vault/ICompositeLiquidityRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IERC20MultiTokenErrors.sol [Line: 3](contracts/vault/IERC20MultiTokenErrors.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IHooks.sol [Line: 3](contracts/vault/IHooks.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IPoolLiquidity.sol [Line: 3](contracts/vault/IPoolLiquidity.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 3](contracts/vault/IProtocolFeeController.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IRouter.sol [Line: 3](contracts/vault/IRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IRouterCommon.sol [Line: 3](contracts/vault/IRouterCommon.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/ISwapFeePercentageBounds.sol [Line: 3](contracts/vault/ISwapFeePercentageBounds.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol [Line: 3](contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVault.sol [Line: 3](contracts/vault/IVault.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultAdmin.sol [Line: 3](contracts/vault/IVaultAdmin.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultErrors.sol [Line: 3](contracts/vault/IVaultErrors.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 3](contracts/vault/IVaultEvents.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultExplorer.sol [Line: 3](contracts/vault/IVaultExplorer.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultExtension.sol [Line: 3](contracts/vault/IVaultExtension.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultMain.sol [Line: 3](contracts/vault/IVaultMain.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/VaultTypes.sol [Line: 3](contracts/vault/VaultTypes.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```



## L-2: PUSH0 is not supported by all chains

Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

- Found in contracts/pool-gyro/IGyro2CLPPool.sol [Line: 3](contracts/pool-gyro/IGyro2CLPPool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/pool-quantamm/IQuantAMMWeightedPool.sol [Line: 2](contracts/pool-quantamm/IQuantAMMWeightedPool.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-quantamm/IUpdateRule.sol [Line: 2](contracts/pool-quantamm/IUpdateRule.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-quantamm/IUpdateWeightRunner.sol [Line: 2](contracts/pool-quantamm/IUpdateWeightRunner.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-quantamm/OracleWrapper.sol [Line: 2](contracts/pool-quantamm/OracleWrapper.sol#L2)

	```solidity
	pragma solidity >=0.8.24;
	```

- Found in contracts/pool-stable/IStablePool.sol [Line: 3](contracts/pool-stable/IStablePool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/pool-utils/IPoolInfo.sol [Line: 3](contracts/pool-utils/IPoolInfo.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/pool-weighted/IWeightedPool.sol [Line: 3](contracts/pool-weighted/IWeightedPool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IAuthentication.sol [Line: 3](contracts/solidity-utils/helpers/IAuthentication.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IPoolVersion.sol [Line: 3](contracts/solidity-utils/helpers/IPoolVersion.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IRateProvider.sol [Line: 3](contracts/solidity-utils/helpers/IRateProvider.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/helpers/IVersion.sol [Line: 3](contracts/solidity-utils/helpers/IVersion.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/solidity-utils/misc/IWETH.sol [Line: 3](contracts/solidity-utils/misc/IWETH.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IStdMedusaCheats.sol [Line: 3](contracts/test/IStdMedusaCheats.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultAdminMock.sol [Line: 3](contracts/test/IVaultAdminMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultExtensionMock.sol [Line: 3](contracts/test/IVaultExtensionMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultMainMock.sol [Line: 3](contracts/test/IVaultMainMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultMock.sol [Line: 3](contracts/test/IVaultMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/test/IVaultStorageMock.sol [Line: 3](contracts/test/IVaultStorageMock.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IAuthorizer.sol [Line: 3](contracts/vault/IAuthorizer.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBasePool.sol [Line: 3](contracts/vault/IBasePool.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBasePoolFactory.sol [Line: 3](contracts/vault/IBasePoolFactory.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBatchRouter.sol [Line: 3](contracts/vault/IBatchRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IBufferRouter.sol [Line: 3](contracts/vault/IBufferRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/ICompositeLiquidityRouter.sol [Line: 3](contracts/vault/ICompositeLiquidityRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IERC20MultiTokenErrors.sol [Line: 3](contracts/vault/IERC20MultiTokenErrors.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IHooks.sol [Line: 3](contracts/vault/IHooks.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IPoolLiquidity.sol [Line: 3](contracts/vault/IPoolLiquidity.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 3](contracts/vault/IProtocolFeeController.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IRouter.sol [Line: 3](contracts/vault/IRouter.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IRouterCommon.sol [Line: 3](contracts/vault/IRouterCommon.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/ISwapFeePercentageBounds.sol [Line: 3](contracts/vault/ISwapFeePercentageBounds.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol [Line: 3](contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVault.sol [Line: 3](contracts/vault/IVault.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultAdmin.sol [Line: 3](contracts/vault/IVaultAdmin.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultErrors.sol [Line: 3](contracts/vault/IVaultErrors.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 3](contracts/vault/IVaultEvents.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultExplorer.sol [Line: 3](contracts/vault/IVaultExplorer.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultExtension.sol [Line: 3](contracts/vault/IVaultExtension.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/IVaultMain.sol [Line: 3](contracts/vault/IVaultMain.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```

- Found in contracts/vault/VaultTypes.sol [Line: 3](contracts/vault/VaultTypes.sol#L3)

	```solidity
	pragma solidity ^0.8.24;
	```



# NC Issues

## NC-1: Functions not used internally could be marked external



- Found in contracts/pool-quantamm/OracleWrapper.sol [Line: 15](contracts/pool-quantamm/OracleWrapper.sol#L15)

	```solidity
	    function getData() public view returns (int216 data, uint40 timestamp) {
	```



## NC-2: Event is missing `indexed` fields

Index event fields make the field more quickly accessible to off-chain tools that parse events. However, note that each index field costs extra gas during emission, so it's not necessarily best to index the maximum allowed per event (three fields). Each event should use three indexed fields if there are three or more fields, and gas usage is not particularly of concern for the events in question. If there are fewer than three fields, all of the fields should be indexed.

- Found in contracts/vault/IProtocolFeeController.sol [Line: 15](contracts/vault/IProtocolFeeController.sol#L15)

	```solidity
	    event GlobalProtocolSwapFeePercentageChanged(uint256 swapFeePercentage);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 21](contracts/vault/IProtocolFeeController.sol#L21)

	```solidity
	    event GlobalProtocolYieldFeePercentageChanged(uint256 yieldFeePercentage);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 28](contracts/vault/IProtocolFeeController.sol#L28)

	```solidity
	    event ProtocolSwapFeePercentageChanged(address indexed pool, uint256 swapFeePercentage);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 35](contracts/vault/IProtocolFeeController.sol#L35)

	```solidity
	    event ProtocolYieldFeePercentageChanged(address indexed pool, uint256 yieldFeePercentage);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 42](contracts/vault/IProtocolFeeController.sol#L42)

	```solidity
	    event PoolCreatorSwapFeePercentageChanged(address indexed pool, uint256 poolCreatorSwapFeePercentage);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 49](contracts/vault/IProtocolFeeController.sol#L49)

	```solidity
	    event PoolCreatorYieldFeePercentageChanged(address indexed pool, uint256 poolCreatorYieldFeePercentage);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 61](contracts/vault/IProtocolFeeController.sol#L61)

	```solidity
	    event ProtocolSwapFeeCollected(address indexed pool, IERC20 indexed token, uint256 amount);
	```

- Found in contracts/vault/IProtocolFeeController.sol [Line: 73](contracts/vault/IProtocolFeeController.sol#L73)

	```solidity
	    event ProtocolYieldFeeCollected(address indexed pool, IERC20 indexed token, uint256 amount);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 26](contracts/vault/IVaultEvents.sol#L26)

	```solidity
	    event PoolRegistered(
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 70](contracts/vault/IVaultEvents.sol#L70)

	```solidity
	    event Wrap(
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 84](contracts/vault/IVaultEvents.sol#L84)

	```solidity
	    event Unwrap(
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 131](contracts/vault/IVaultEvents.sol#L131)

	```solidity
	    event VaultPausedStateChanged(bool paused);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 144](contracts/vault/IVaultEvents.sol#L144)

	```solidity
	    event PoolPausedStateChanged(address indexed pool, bool paused);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 150](contracts/vault/IVaultEvents.sol#L150)

	```solidity
	    event SwapFeePercentageChanged(address indexed pool, uint256 swapFeePercentage);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 157](contracts/vault/IVaultEvents.sol#L157)

	```solidity
	    event PoolRecoveryModeStateChanged(address indexed pool, bool recoveryMode);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 165](contracts/vault/IVaultEvents.sol#L165)

	```solidity
	    event AggregateSwapFeePercentageChanged(address indexed pool, uint256 aggregateSwapFeePercentage);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 173](contracts/vault/IVaultEvents.sol#L173)

	```solidity
	    event AggregateYieldFeePercentageChanged(address indexed pool, uint256 aggregateYieldFeePercentage);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 196](contracts/vault/IVaultEvents.sol#L196)

	```solidity
	    event LiquidityAddedToBuffer(
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 213](contracts/vault/IVaultEvents.sol#L213)

	```solidity
	    event BufferSharesMinted(IERC4626 indexed wrappedToken, address indexed to, uint256 issuedShares);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 225](contracts/vault/IVaultEvents.sol#L225)

	```solidity
	    event BufferSharesBurned(IERC4626 indexed wrappedToken, address indexed from, uint256 burnedShares);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 235](contracts/vault/IVaultEvents.sol#L235)

	```solidity
	    event LiquidityRemovedFromBuffer(
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 249](contracts/vault/IVaultEvents.sol#L249)

	```solidity
	    event VaultBuffersPausedStateChanged(bool paused);
	```

- Found in contracts/vault/IVaultEvents.sol [Line: 257](contracts/vault/IVaultEvents.sol#L257)

	```solidity
	    event VaultAuxiliary(address indexed pool, bytes32 indexed eventKey, bytes eventData);
	```



