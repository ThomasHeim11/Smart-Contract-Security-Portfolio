// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IBurnMintERC20} from "../../../shared/token/ERC20/IBurnMintERC20.sol";
import {IPoolV1} from "../../interfaces/IPool.sol";
import {ITokenMessenger} from "../../pools/USDC/ITokenMessenger.sol";

import {BurnMintERC677} from "../../../shared/token/ERC677/BurnMintERC677.sol";
import {Router} from "../../Router.sol";
import {Internal} from "../../libraries/Internal.sol";
import {Pool} from "../../libraries/Pool.sol";
import {RateLimiter} from "../../libraries/RateLimiter.sol";
import {TokenPool} from "../../pools/TokenPool.sol";
import {USDCTokenPool} from "../../pools/USDC/USDCTokenPool.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {USDCTokenPoolHelper} from "../helpers/USDCTokenPoolHelper.sol";
import {MockE2EUSDCTransmitter} from "../mocks/MockE2EUSDCTransmitter.sol";
import {MockUSDCTokenMessenger} from "../mocks/MockUSDCTokenMessenger.sol";

import {IERC165} from "../../../vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol";

contract USDCTokenPoolSetup is BaseTest {
  IBurnMintERC20 internal s_token;
  MockUSDCTokenMessenger internal s_mockUSDC;
  MockE2EUSDCTransmitter internal s_mockUSDCTransmitter;

  struct USDCMessage {
    uint32 version;
    uint32 sourceDomain;
    uint32 destinationDomain;
    uint64 nonce;
    bytes32 sender;
    bytes32 recipient;
    bytes32 destinationCaller;
    bytes messageBody;
  }

  uint32 internal constant SOURCE_DOMAIN_IDENTIFIER = 0x02020202;
  uint32 internal constant DEST_DOMAIN_IDENTIFIER = 0;

  bytes32 internal constant SOURCE_CHAIN_TOKEN_SENDER = bytes32(uint256(uint160(0x01111111221)));
  address internal constant SOURCE_CHAIN_USDC_POOL = address(0x23789765456789);
  address internal constant DEST_CHAIN_USDC_POOL = address(0x987384873458734);
  address internal constant DEST_CHAIN_USDC_TOKEN = address(0x23598918358198766);

  address internal s_routerAllowedOnRamp = address(3456);
  address internal s_routerAllowedOffRamp = address(234);
  Router internal s_router;

  USDCTokenPoolHelper internal s_usdcTokenPool;
  USDCTokenPoolHelper internal s_usdcTokenPoolWithAllowList;
  address[] internal s_allowedList;

  function setUp() public virtual override {
    BaseTest.setUp();
    BurnMintERC677 usdcToken = new BurnMintERC677("LINK", "LNK", 18, 0);
    s_token = usdcToken;
    deal(address(s_token), OWNER, type(uint256).max);
    check_setUpRamps();

    s_mockUSDCTransmitter = new MockE2EUSDCTransmitter(0, DEST_DOMAIN_IDENTIFIER, address(s_token));
    s_mockUSDC = new MockUSDCTokenMessenger(0, address(s_mockUSDCTransmitter));

    usdcToken.grantMintAndBurnRoles(address(s_mockUSDCTransmitter));

    s_usdcTokenPool =
      new USDCTokenPoolHelper(s_mockUSDC, s_token, new address[](0), address(s_mockRMN), address(s_router));
    usdcToken.grantMintAndBurnRoles(address(s_mockUSDC));

    s_allowedList.push(USER_1);
    s_usdcTokenPoolWithAllowList =
      new USDCTokenPoolHelper(s_mockUSDC, s_token, s_allowedList, address(s_mockRMN), address(s_router));

    TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](2);
    chainUpdates[0] = TokenPool.ChainUpdate({
      remoteChainSelector: SOURCE_CHAIN_SELECTOR,
      remotePoolAddress: abi.encode(SOURCE_CHAIN_USDC_POOL),
      remoteTokenAddress: abi.encode(address(s_token)),
      allowed: true,
      outboundRateLimiterConfig: getOutboundRateLimiterConfig(),
      inboundRateLimiterConfig: getInboundRateLimiterConfig()
    });
    chainUpdates[1] = TokenPool.ChainUpdate({
      remoteChainSelector: DEST_CHAIN_SELECTOR,
      remotePoolAddress: abi.encode(DEST_CHAIN_USDC_POOL),
      remoteTokenAddress: abi.encode(DEST_CHAIN_USDC_TOKEN),
      allowed: true,
      outboundRateLimiterConfig: getOutboundRateLimiterConfig(),
      inboundRateLimiterConfig: getInboundRateLimiterConfig()
    });

    s_usdcTokenPool.applyChainUpdates(chainUpdates);
    s_usdcTokenPoolWithAllowList.applyChainUpdates(chainUpdates);

    USDCTokenPool.DomainUpdate[] memory domains = new USDCTokenPool.DomainUpdate[](1);
    domains[0] = USDCTokenPool.DomainUpdate({
      destChainSelector: DEST_CHAIN_SELECTOR,
      domainIdentifier: 9999,
      allowedCaller: keccak256("allowedCaller"),
      enabled: true
    });

    s_usdcTokenPool.setDomains(domains);
    s_usdcTokenPoolWithAllowList.setDomains(domains);
  }

  function check_setUpRamps() internal {
    s_router = new Router(address(s_token), address(s_mockRMN));

    Router.OnRamp[] memory onRampUpdates = new Router.OnRamp[](1);
    onRampUpdates[0] = Router.OnRamp({destChainSelector: DEST_CHAIN_SELECTOR, onRamp: s_routerAllowedOnRamp});
    Router.OffRamp[] memory offRampUpdates = new Router.OffRamp[](1);
    address[] memory offRamps = new address[](1);
    offRamps[0] = s_routerAllowedOffRamp;
    offRampUpdates[0] = Router.OffRamp({sourceChainSelector: SOURCE_CHAIN_SELECTOR, offRamp: offRamps[0]});

    s_router.applyRampUpdates(onRampUpdates, new Router.OffRamp[](0), offRampUpdates);
  }

  function check_generateUSDCMessage(USDCMessage memory usdcMessage) internal pure returns (bytes memory) {
    return abi.encodePacked(
      usdcMessage.version,
      usdcMessage.sourceDomain,
      usdcMessage.destinationDomain,
      usdcMessage.nonce,
      usdcMessage.sender,
      usdcMessage.recipient,
      usdcMessage.destinationCaller,
      usdcMessage.messageBody
    );
  }
}

contract USDCTokenPool_lockOrBurn is USDCTokenPoolSetup {
  // Base test case, included for PR gas comparisons as fuzz tests are excluded from forge snapshot due to being flaky.
  function check_test_LockOrBurn_Success() public {
    bytes32 receiver = bytes32(uint256(uint160(STRANGER)));
    uint256 amount = 1;
    s_token.transfer(address(s_usdcTokenPool), amount);
    vm.startPrank(s_routerAllowedOnRamp);

    USDCTokenPool.Domain memory expectedDomain = s_usdcTokenPool.getDomain(DEST_CHAIN_SELECTOR);

    vm.expectEmit();
    emit RateLimiter.TokensConsumed(amount);

    vm.expectEmit();
    emit ITokenMessenger.DepositForBurn(
      s_mockUSDC.s_nonce(),
      address(s_token),
      amount,
      address(s_usdcTokenPool),
      expectedDomain.allowedCaller,
      expectedDomain.domainIdentifier,
      s_mockUSDC.DESTINATION_TOKEN_MESSENGER(),
      expectedDomain.allowedCaller
    );

    vm.expectEmit();
    emit TokenPool.Burned(s_routerAllowedOnRamp, amount);

    Pool.LockOrBurnOutV1 memory poolReturnDataV1 = s_usdcTokenPool.lockOrBurn(
      Pool.LockOrBurnInV1({
        originalSender: OWNER,
        receiver: abi.encodePacked(receiver),
        amount: amount,
        remoteChainSelector: DEST_CHAIN_SELECTOR,
        localToken: address(s_token)
      })
    );

    uint64 nonce = abi.decode(poolReturnDataV1.destPoolData, (uint64));
    assert(s_mockUSDC.s_nonce() - 1 == nonce);
  }
}
