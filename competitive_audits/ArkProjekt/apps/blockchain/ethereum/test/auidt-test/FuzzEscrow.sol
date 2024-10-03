// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/Escrow.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract FuzzEscrowTest is Test {
    StarklaneEscrow escrow;
    TestERC721 token;
    TestERC1155 erc1155;
    address user;
    address attacker;
    uint256 tokenId;
    uint256 erc1155Id = 1;

    function setUp() public {
        user = address(0x1);
        attacker = address(this); // Use the test contract itself as the attacker

        escrow = new StarklaneEscrow();
        token = new TestERC721();
        erc1155 = new TestERC1155();

        // Mint some ERC1155 tokens for user
        erc1155.mint(user, erc1155Id, 10, "0x"); // Mint 10 tokens of id 1 to user
    }

    function testFuzzDepositAndReentrancy(uint256 _tokenId) public {
        tokenId = _tokenId;
        token.mint(user, tokenId);

        // Ensure the token is unique by setting the tokenId to a non-zero value
        vm.assume(tokenId != 0);

        // User mints and deposits the token into the escrow contract
        vm.startPrank(user);
        token.approve(address(escrow), tokenId);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        require(depositIntoEscrow(CollectionType.ERC721, address(token), tokenIds), "depositIntoEscrow failed");
        vm.stopPrank();

        runAttack();

        // Check if the attacker successfully reentered and withdrew the token
        assertEq(token.ownerOf(tokenId), address(this), "Attacker should not own the token after reentrancy attack");

        // Additional checks
        // Check the escrow contract does not hold the token anymore
        assertEq(token.ownerOf(tokenId), address(this), "Escrow contract should not own the token");
        // Verify that the token has not been transferred elsewhere
        assertEq(
            token.ownerOf(tokenId), address(this), "Toke, should be with the attacker after the legitimate transfer"
        );
    }

    function testFuzzERC1155Handling(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 10); // Ensure valid minting amount

        uint256 initialBalance = erc1155.balanceOf(user, erc1155Id);

        vm.startPrank(user);
        erc1155.setApprovalForAll(address(escrow), true);
        erc1155.safeTransferFrom(user, address(escrow), erc1155Id, amount, "0x");
        vm.stopPrank();

        uint256 escrowBalance = erc1155.balanceOf(address(escrow), erc1155Id);
        uint256 userBalance = erc1155.balanceOf(user, erc1155Id);

        // Assert the balances
        assertEq(escrowBalance, amount, "Escrow contract should hold the transferred amount of ERC1155 tokens");
        assertEq(userBalance, initialBalance - amount, "User's balance should be reduced by the transferred amount");
    }

    function runAttack() public {
        // Initiate reentrancy attack by calling withdrawFromEscrow
        require(
            withdrawFromEscrow(CollectionType.ERC721, address(token), attacker, tokenId), "withdrawFromEscrow failed"
        );
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        // Re-enter withdrawFromEscrow while still in the initial withdraw call
        if (token.ownerOf(tokenId) == address(escrow)) {
            withdrawFromEscrow(CollectionType.ERC721, address(token), attacker, tokenId);
        }
        return this.onERC721Received.selector;
    }

    // Helper function to call _depositIntoEscrow
    function depositIntoEscrow(CollectionType collectionType, address collection, uint256[] memory ids)
        public
        returns (bool)
    {
        (bool success, bytes memory result) = address(escrow).call(
            abi.encodeWithSignature("_depositIntoEscrow(uint8,address,uint256[])", collectionType, collection, ids)
        );
        if (!success) {
            emit LogError(result);
        }
        return success;
    }

    // Helper function to call _withdrawFromEscrow
    function withdrawFromEscrow(CollectionType collectionType, address collection, address to, uint256 id)
        public
        returns (bool)
    {
        (bool success, bytes memory result) = address(escrow).call(
            abi.encodeWithSignature(
                "_withdrawFromEscrow(uint8,address,address,uint256)", collectionType, collection, to, id
            )
        );
        if (!success) {
            emit LogError(result);
        }
        return success;
    }

    event LogError(bytes data);
}

// Basic ERC721 contract for testing
contract TestERC721 is ERC721 {
    uint256 private _nextTokenId = 1;

    constructor() ERC721("TestERC721", "TEST") {}

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "http://test.com/token/";
    }
}

// Basic ERC1155 contract for testing
contract TestERC1155 is ERC1155 {
    constructor() ERC1155("http://test.com/token/metadata/{id}.json") {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public {
        _mint(to, id, amount, data);
    }
}
