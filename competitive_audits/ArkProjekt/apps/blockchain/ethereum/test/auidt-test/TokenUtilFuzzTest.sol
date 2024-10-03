// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../src/token/TokenUtil.sol";
import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract TokenUtilFuzzTest is Test {
    // Dummy ERC721 and ERC1155 tokens for testing
    DummyERC721 private erc721;
    DummyERC1155 private erc1155;

    function setUp() public {
        erc721 = new DummyERC721("Dummy ERC721", "DERC721");
        erc1155 = new DummyERC1155("");
    }

    function testFuzzCallBaseUri(address collection) public {
        // Ensure the address is a contract
        uint256 size;
        assembly {
            size := extcodesize(collection)
        }

        if (size == 0) {
            vm.expectRevert();
            TokenUtil._callBaseUri(collection);
            return;
        }

        bool success;
        string memory result;
        (success, result) = TokenUtil._callBaseUri(collection);

        if (success) {
            emit log_string(result); // Log the result if successful
        }
    }
}

// Ensure the contract implements the required ERC721 interface
contract DummyERC721 is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://dummybaseuri.com/";
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    // Ensure token ID is valid and minted before use
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return super.tokenURI(tokenId);
    }
}

contract DummyERC1155 is ERC1155 {
    constructor(string memory initialUri) ERC1155(initialUri) {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public {
        _mint(to, id, amount, data);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://dummyuri.com/token/", Strings.toString(tokenId)));
    }
}
