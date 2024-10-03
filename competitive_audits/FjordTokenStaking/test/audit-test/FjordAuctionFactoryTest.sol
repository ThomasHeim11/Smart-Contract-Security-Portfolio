// // SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity >=0.8.0;

// import "forge-std/Test.sol";
// import "../../src/FjordAuctionFactory.sol";
// import "./MockERC20.sol";

// contract AuctionFactoryTest is Test {
//     AuctionFactory factory;
//     MockERC20 mockToken;
//     MaliciousReentrant malicious;

//     function setUp() public {
//         mockToken = new MockERC20("Mock Token", "MTK", 18);
//         factory = new AuctionFactory(address(mockToken)); // Ensure correct instantiation with required parameter
//         malicious = new MaliciousReentrant(address(factory));
//     }

//     function testCreateAuction() public {
//         // Mint mock tokens to this contract
//         mockToken.mint(address(this), 1000e18);

//         // Approve the factory to spend tokens
//         mockToken.approve(address(factory), 1000e18);

//         // Set the context to the contract owner before calling the function
//         vm.prank(factory.owner());
//         factory.createAuction(address(mockToken), 1 weeks, 1000e18, keccak256("salt"));

//         // Check balances
//         assertEq(mockToken.balanceOf(address(factory)), 0);
//         // Capture the auction address from events or directly from storage if possible
//         // Adjust this assertion as needed to assert the final balance of the auction contract
//     }

//     function testFuzzCreateAuction(address token, uint256 totalTokens) public {
//         // Skip invalid addresses and zero token amount
//         if (totalTokens == 0 || !isContract(token)) return;

//         // Check if the implements ERC20 interface
//         try MockERC20(token).totalSupply() { }
//         catch {
//             return; // Token doesn't implement MockERC20 correctly
//         }

//         MockERC20 fuzzedMockToken = MockERC20(token);

//         // Try to mint tokens, if minting fails, skip the address
//         try fuzzedMockToken.mint(address(this), totalTokens) { }
//         catch {
//             return; // Minting failed, likely unsupported method
//         }

//         // Approve the factory to spend tokens
//         try fuzzedMockToken.approve(address(factory), totalTokens) returns (bool approved) {
//             if (!approved) return; // Approval failed
//         } catch {
//             return; // Approval failed
//         }

//         // Set the context to the contract owner before calling the function
//         vm.prank(factory.owner());
//         try factory.createAuction(address(fuzzedMockToken), 1 weeks, totalTokens, keccak256("salt"))
//         {
//             // Check balances
//             assertEq(fuzzedMockToken.balanceOf(address(factory)), 0);
//             // Capture the auction address from events or directly from storage if possible
//             // Adjust this assertion as needed to assert the final balance of the auction contract
//         } catch {
//             // Handle potential reverts from createAuction
//             return;
//         }
//     }

//     function testReentrancyAttack() public {
//         // Mint and approve mock tokens for malicious contract
//         mockToken.mint(address(malicious), 1000e18);
//         mockToken.approve(address(factory), 1000e18);

//         // Perform reentrancy attack
//         vm.expectRevert(); // Expect reentrancy protection to prevent reentrancy attack
//         malicious.attack();

//         // Assert expected state to ensure no harm done
//         assertEq(mockToken.balanceOf(address(factory)), 0);
//     }

//     // Utility function to check if an address is a contract
//     function isContract(address addr) internal view returns (bool) {
//         uint256 size;
//         assembly {
//             size := extcodesize(addr)
//         }
//         return size > 0;
//     }
// }

// contract MaliciousReentrant {
//     AuctionFactory factory;

//     constructor(address _factory) {
//         factory = AuctionFactory(_factory);
//     }

//     fallback() external payable {
//         // Attempt reentry
//         factory.createAuction(address(this), 1 weeks, 1e18, keccak256("salt"));
//     }

//     function attack() public {
//         // Initiate the attack
//         factory.createAuction(address(this), 1 weeks, 1e18, keccak256("salt"));
//     }
// }
