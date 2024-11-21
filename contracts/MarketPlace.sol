// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// Import statements
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract definition
contract NFTMarketPlace is ERC721, Ownable {
    // Structs
    struct Sale {
        address seller;
        uint256 price;
        bool isForSale;
    }

    // State variables
    mapping(uint256 => Sale) public nftListings; // Mapping to track NFT listings
    uint256 public tokenCounter;

    // Events
    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );
    event TokenSold(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    // Constructor
    constructor() ERC721("PolarBearNFT", "PBR") Ownable(msg.sender) {}

    // Internal functions
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://plum-impressive-kingfisher-250.mypinata.cloud/ipfs/QmaiA6cs18QY5F2yNvFkZbcwKefDyZiVfZeNSfebX2aaWK";
    }

    // Public and external functions

    /**
     * @dev Create a new NFT and assign it to the caller.
     */
    function createToken() external {
        uint256 tokenId = tokenCounter;
        tokenCounter++;

        _safeMint(msg.sender, tokenId);
        emit TokenMinted(msg.sender, tokenId);
    }

    /**
     * @dev Put an NFT up for sale.
     * @param tokenId The ID of the NFT to list.
     * @param price The sale price for the NFT.
     */
    function putTokenForSale(uint256 tokenId, uint256 price) external {
        require(
            nftListings[tokenId].isForSale == false,
            "This NFT is already listed for sale"
        );
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(price > 0, "Price must be greater than zero");

        nftListings[tokenId] = Sale(msg.sender, price, true);
        emit TokenListed(msg.sender, tokenId, price);
    }

    /**
     * @dev Purchase a listed NFT.
     * @param tokenId The ID of the NFT to purchase.
     */
    function purchaseToken(uint256 tokenId) external payable {
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

        emit TokenSold(msg.sender, tokenId, sale.price);
    }

    /**
     * @dev Remove an NFT from sale.
     * @param tokenId The ID of the NFT to delist.
     */
    function removeTokenFromSale(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(nftListings[tokenId].isForSale, "This NFT is not listed for sale");

        delete nftListings[tokenId];
    }

    /**
     * @dev Retrieve details of a listed NFT.
     * @param tokenId The ID of the NFT.
     * @return The sale details.
     */
    function fetchListingDetails(uint256 tokenId) external view returns (Sale memory) {
        return nftListings[tokenId];
    }

    // Fallback function
    receive() external payable {
        revert();
    }
}
