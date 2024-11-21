// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NFTMarketPlaceUUPS is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    struct Sale {
        address seller;
        uint256 price;
        bool isForSale;
    }

    // Mapping to track NFT sales
    mapping(uint256 => Sale) public nftListings;

    // Event declarations
    event TokenCreated(address indexed owner, uint256 indexed tokenId);
    event TokenListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event TokenAcquired(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    uint256 public nextTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("PolarBearNFTUUPS", "PBRU");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://plum-impressive-kingfisher-250.mypinata.cloud/ipfs/QmaiA6cs18QY5F2yNvFkZbcwKefDyZiVfZeNSfebX2aaWK";
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Create a new NFT and assign it to the caller.
     */
    function createToken() public {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(msg.sender, tokenId);

        emit TokenCreated(msg.sender, tokenId);
    }

    /**
     * @dev List an NFT for sale.
     * @param tokenId The ID of the NFT to list.
     * @param price The sale price for the NFT.
     */
    function listToken(uint256 tokenId, uint256 price) public {
        require(
            nftListings[tokenId].isForSale == false,
            "This NFT is already listed for sale"
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(price > 0, "Price must be greater than zero");

        nftListings[tokenId] = Sale(msg.sender, price, true);

        emit TokenListed(msg.sender, tokenId, price);
    }

    /**
     * @dev Purchase an NFT that is listed for sale.
     * @param tokenId The ID of the NFT to purchase.
     */
    function purchaseToken(uint256 tokenId) public payable {
        Sale memory sale = nftListings[tokenId];
        require(sale.isForSale, "This NFT is not for sale");
        require(msg.value == sale.price, "Incorrect value sent");

        address seller = sale.seller;

        // Clear the sale
        delete nftListings[tokenId];

        // Transfer funds to the seller
        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Transfer failed");

        // Transfer NFT to the buyer
        _transfer(seller, msg.sender, tokenId);

        emit TokenAcquired(msg.sender, tokenId, sale.price);
    }

    /**
     * @dev Remove an NFT from sale.
     * @param tokenId The ID of the NFT to delist.
     */
    function removeTokenFromSale(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(nftListings[tokenId].isForSale, "This NFT is not listed for sale");

        delete nftListings[tokenId];
    }

    /**
     * @dev Fetch details of a listed NFT.
     * @param tokenId The ID of the NFT.
     */
    function fetchListingDetails(uint256 tokenId)
        public
        view
        returns (Sale memory)
    {
        return nftListings[tokenId];
    }

    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {
        revert();
    }
}
