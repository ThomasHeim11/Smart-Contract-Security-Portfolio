// // File: test/StarklaneMessagingTest.sol

// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/StarklaneMessaging.sol";
// import "starknet/IStarknetMessaging.sol";

// contract StarklaneMessagingTest is Test {
//     StarklaneMessaging messaging;
//     IStarknetMessaging starknetMessaging;

//     function setUp() public {
//         messaging = new StarklaneMessaging();
//         messaging.transferOwnership(address(this));
//         starknetMessaging = IStarknetMessaging(0xYourStarknetMessagingAddress);
//     }

//     function fuzz_test_MixedUsageConflict(bytes32 msgHash, snaddress fromL2Address, uint256[] memory request) public {
//         // Add msg hash for auto withdrawal
//         messaging.addMessageHashForAutoWithdraw(uint256(msgHash));

//         // Attempt consuming the message via Starknet which should revert
//         try messaging.consumeMessageStarknet(starknetMessaging, fromL2Address, request) {
//             fail(); // This should not happen
//         } catch Error(string memory reason) {
//             assertEq(reason, "WithdrawMethodError");
//         }
//     }
// }
