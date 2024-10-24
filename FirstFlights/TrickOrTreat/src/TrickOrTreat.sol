// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Import OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SpookySwap is ERC721URIStorage, Ownable(msg.sender), ReentrancyGuard {
    uint256 public nextTokenId;
    mapping(string => Treat) public treatList;
    string[] public treatNames;

    struct Treat {
        string name;
        uint256 cost; // Cost in ETH (in wei) to get one treat
        string metadataURI; // URI for the NFT metadata
    }

    // Mappings to handle pending NFTs in case of double price (trick)
    mapping(uint256 => address) public pendingNFTs; // tokenId => buyer address
    mapping(uint256 => uint256) public pendingNFTsAmountPaid; // tokenId => amount paid
    mapping(uint256 => string) public tokenIdToTreatName; // tokenId => treat name

    event TreatAdded(string name, uint256 cost, string metadataURI);
    event Swapped(address indexed user, string treatName, uint256 tokenId);
    event FeeWithdrawn(address owner, uint256 amount);

    constructor(Treat[] memory treats) ERC721("SpookyTreats", "SPKY") {
        nextTokenId = 1;

        for (uint256 i = 0; i < treats.length; i++) {
            addTreat(treats[i].name, treats[i].cost, treats[i].metadataURI);
        }
    }
    //@audit exploit???

    function addTreat(string memory _name, uint256 _rate, string memory _metadataURI) public onlyOwner {
        treatList[_name] = Treat(_name, _rate, _metadataURI);
        treatNames.push(_name);
        emit TreatAdded(_name, _rate, _metadataURI);
    }

    function setTreatCost(string memory _treatName, uint256 _cost) public onlyOwner {
        require(treatList[_treatName].cost > 0, "Treat must cost something.");
        treatList[_treatName].cost = _cost;
    }

    function trickOrTreat(string memory _treatName) public payable nonReentrant {
        Treat memory treat = treatList[_treatName];
        require(treat.cost > 0, "Treat cost not set.");

        uint256 costMultiplierNumerator = 1;
        uint256 costMultiplierDenominator = 1;
        //@audit can be hacked
        // Generate a pseudo-random number between 1 and 1000
        uint256 random =
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nextTokenId, block.prevrandao))) % 1000 + 1;

        if (random == 1) {
            // 1/1000 chance of half price (treat)
            costMultiplierNumerator = 1;
            costMultiplierDenominator = 2;
        } else if (random == 2) {
            // 1/1000 chance of double price (trick)
            costMultiplierNumerator = 2;
            costMultiplierDenominator = 1;
        }
        // Else, normal price (multiplier remains 1/1)

        uint256 requiredCost = (treat.cost * costMultiplierNumerator) / costMultiplierDenominator;

        if (costMultiplierNumerator == 2 && costMultiplierDenominator == 1) {
            // Double price case (trick)
            if (msg.value >= requiredCost) {
                // User sent enough ETH
                mintTreat(msg.sender, treat);
            } else {
                // User didn't send enough ETH
                // Mint NFT to contract and store pending purchase
                uint256 tokenId = nextTokenId;
                _mint(address(this), tokenId);
                _setTokenURI(tokenId, treat.metadataURI);
                nextTokenId += 1;

                pendingNFTs[tokenId] = msg.sender;
                pendingNFTsAmountPaid[tokenId] = msg.value;
                tokenIdToTreatName[tokenId] = _treatName;

                emit Swapped(msg.sender, _treatName, tokenId);

                // User needs to call fellForTrick() to finish the transaction
            }
        } else {
            // Normal price or half price
            require(msg.value >= requiredCost, "Insufficient ETH sent for treat");
            mintTreat(msg.sender, treat);
        }

        // Refund excess ETH if any
        if (msg.value > requiredCost) {
            uint256 refund = msg.value - requiredCost;
            (bool refundSuccess,) = msg.sender.call{value: refund}("");
            require(refundSuccess, "Refund failed");
        }
    }
    //@audit no safeguard. exploit.
    // Internal function to mint the NFT to the user

    function mintTreat(address recipient, Treat memory treat) internal {
        uint256 tokenId = nextTokenId;
        _mint(recipient, tokenId);
        _setTokenURI(tokenId, treat.metadataURI);
        nextTokenId += 1;

        emit Swapped(recipient, treat.name, tokenId);
    }
    //@audit can this be exploited?
    // Function for users to complete their purchase if they didn't pay enough during a trick

    function resolveTrick(uint256 tokenId) public payable nonReentrant {
        require(pendingNFTs[tokenId] == msg.sender, "Not authorized to complete purchase");

        string memory treatName = tokenIdToTreatName[tokenId];
        Treat memory treat = treatList[treatName];

        uint256 requiredCost = treat.cost * 2; // Double price
        uint256 amountPaid = pendingNFTsAmountPaid[tokenId];
        uint256 totalPaid = amountPaid + msg.value;

        require(totalPaid >= requiredCost, "Insufficient ETH sent to complete purchase");

        // Transfer the NFT to the buyer
        _transfer(address(this), msg.sender, tokenId);

        // Clean up storage
        delete pendingNFTs[tokenId];
        delete pendingNFTsAmountPaid[tokenId];
        delete tokenIdToTreatName[tokenId];

        // Refund excess ETH if any
        if (totalPaid > requiredCost) {
            uint256 refund = totalPaid - requiredCost;
            (bool refundSuccess,) = msg.sender.call{value: refund}("");
            require(refundSuccess, "Refund failed");
        }
    }
    //@audit can hacker steal all fees?

    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit FeeWithdrawn(owner(), balance);
    }

    function getTreats() public view returns (string[] memory) {
        return treatNames;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
    }
}
