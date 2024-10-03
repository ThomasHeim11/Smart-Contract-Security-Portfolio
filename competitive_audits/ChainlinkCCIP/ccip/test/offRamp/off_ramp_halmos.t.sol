// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {ICommitStore} from "../../interfaces/ICommitStore.sol";
import {IPoolV1} from "../../interfaces/IPool.sol";
import {ITokenAdminRegistry} from "../../interfaces/ITokenAdminRegistry.sol";

import {CallWithExactGas} from "../../../shared/call/CallWithExactGas.sol";
import {AggregateRateLimiter} from "../../AggregateRateLimiter.sol";
import {RMN} from "../../RMN.sol";
import {Router} from "../../Router.sol";
import {Client} from "../../libraries/Client.sol";
import {Internal} from "../../libraries/Internal.sol";
import {Pool} from "../../libraries/Pool.sol";
import {RateLimiter} from "../../libraries/RateLimiter.sol";
import {OCR2Abstract} from "../../ocr/OCR2Abstract.sol";
import {EVM2EVMOffRamp} from "../../offRamp/EVM2EVMOffRamp.sol";
import {LockReleaseTokenPool} from "../../pools/LockReleaseTokenPool.sol";
import {TokenPool} from "../../pools/TokenPool.sol";
import {EVM2EVMOffRampHelper} from "../helpers/EVM2EVMOffRampHelper.sol";
import {MaybeRevertingBurnMintTokenPool} from "../helpers/MaybeRevertingBurnMintTokenPool.sol";
import {ConformingReceiver} from "../helpers/receivers/ConformingReceiver.sol";
import {MaybeRevertMessageReceiver} from "../helpers/receivers/MaybeRevertMessageReceiver.sol";
import {MaybeRevertMessageReceiverNo165} from "../helpers/receivers/MaybeRevertMessageReceiverNo165.sol";
import {ReentrancyAbuser} from "../helpers/receivers/ReentrancyAbuser.sol";
import {MockCommitStore} from "../mocks/MockCommitStore.sol";
import {OCR2Base} from "../ocr/OCR2Base.t.sol";
import {OCR2BaseNoChecks} from "../ocr/OCR2BaseNoChecks.t.sol";
import {EVM2EVMOffRampSetup} from "./EVM2EVMOffRampSetup.t.sol";

import {IERC20} from "../../../vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract EVM2EVMOffRamp_constructor is EVM2EVMOffRampSetup {
  function check_Constructor_Success() public {
    EVM2EVMOffRamp.StaticConfig memory staticConfig = EVM2EVMOffRamp.StaticConfig({
      commitStore: address(s_mockCommitStore),
      chainSelector: DEST_CHAIN_SELECTOR,
      sourceChainSelector: SOURCE_CHAIN_SELECTOR,
      onRamp: ON_RAMP_ADDRESS,
      prevOffRamp: address(0),
      rmnProxy: address(s_mockRMN),
      tokenAdminRegistry: address(s_tokenAdminRegistry)
    });
    EVM2EVMOffRamp.DynamicConfig memory dynamicConfig =
      generateDynamicOffRampConfig(address(s_destRouter), address(s_priceRegistry));

    s_offRamp = new EVM2EVMOffRampHelper(staticConfig, getInboundRateLimiterConfig());

    s_offRamp.setOCR2Config(
      s_valid_signers, s_valid_transmitters, s_f, abi.encode(dynamicConfig), s_offchainConfigVersion, abi.encode("")
    );

    // Static config
    EVM2EVMOffRamp.StaticConfig memory gotStaticConfig = s_offRamp.getStaticConfig();
    assert(staticConfig.commitStore == gotStaticConfig.commitStore);
    assert(staticConfig.sourceChainSelector == gotStaticConfig.sourceChainSelector);
    assert(staticConfig.chainSelector == gotStaticConfig.chainSelector);
    assert(staticConfig.onRamp == gotStaticConfig.onRamp);
    assert(staticConfig.prevOffRamp == gotStaticConfig.prevOffRamp);
    assert(staticConfig.tokenAdminRegistry == gotStaticConfig.tokenAdminRegistry);

    // Dynamic config
    EVM2EVMOffRamp.DynamicConfig memory gotDynamicConfig = s_offRamp.getDynamicConfig();
    _assertSameConfig(dynamicConfig, gotDynamicConfig);

    (uint32 configCount, uint32 blockNumber,) = s_offRamp.latestConfigDetails();
    assert(1 == configCount);
    assert(block.number == blockNumber);

    // OffRamp initial values
    assert(
      keccak256(abi.encodePacked("EVM2EVMOffRamp 1.5.0-dev")) == keccak256(abi.encodePacked(s_offRamp.typeAndVersion()))
    );
    assert(OWNER == s_offRamp.owner());
  }

  // Revert
  function check_ZeroOnRampAddress_Revert() public {
    vm.expectRevert(EVM2EVMOffRamp.ZeroAddressNotAllowed.selector);

    s_offRamp = new EVM2EVMOffRampHelper(
      EVM2EVMOffRamp.StaticConfig({
        commitStore: address(s_mockCommitStore),
        chainSelector: DEST_CHAIN_SELECTOR,
        sourceChainSelector: SOURCE_CHAIN_SELECTOR,
        onRamp: ZERO_ADDRESS,
        prevOffRamp: address(0),
        rmnProxy: address(s_mockRMN),
        tokenAdminRegistry: address(s_tokenAdminRegistry)
      }),
      RateLimiter.Config({isEnabled: true, rate: 1e20, capacity: 1e20})
    );
  }
}
