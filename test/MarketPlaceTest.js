const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketPlace", function () {
  let NFTMarketPlace, nftMarketPlace, owner, addr1, addr2;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    NFTMarketPlace = await ethers.getContractFactory("NFTMarketPlace");
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the contract
    nftMarketPlace = await NFTMarketPlace.deploy();
  });

  it("should mint an NFT", async function () {
    await nftMarketPlace.connect(addr1).createToken();
    expect(await nftMarketPlace.ownerOf(0)).to.equal(addr1.address);
  });

  it("Should list a token for sale", async function () {
    // Mint a token
    await nftMarketPlace.connect(addr1).createToken();

    // List it for sale with price in Wei
    const priceInWei = "1000000000000000000"; // 1 Ether in Wei
    await nftMarketPlace.connect(addr1).putTokenForSale(0, priceInWei);

    // Fetch listing details
    const listing = await nftMarketPlace.fetchListingDetails(0);

    // Assertions
    expect(listing.seller).to.equal(addr1.address); // Check seller
    expect(listing.price.toString()).to.equal(priceInWei); // Check price
    expect(listing.isForSale).to.be.true; // Check sale status
});


it("Should purchase a listed token", async function () {
    // Mint a token
    await nftMarketPlace.connect(addr1).createToken();

    // List the token for sale with price in Wei
    const priceInWei = "1000000000000000000"; // 1 Ether in Wei
    await nftMarketPlace.connect(addr1).putTokenForSale(0, priceInWei);

    // Purchase the token
    await nftMarketPlace.connect(addr2).purchaseToken(0, { value: priceInWei });

    // Assertions
    expect(await nftMarketPlace.ownerOf(0)).to.equal(addr2.address); // Check ownership transfer
    const listing = await nftMarketPlace.fetchListingDetails(0);
    expect(listing.isForSale).to.be.false; // Check sale status
});

it("Should remove a token from sale", async function () {
    await nftMarketPlace.connect(addr1).createToken();

    // List the token for sale (1 Ether = 1000000000000000000 Wei)
    const priceInWei = "1000000000000000000"; // 1 Ether in Wei
    await nftMarketPlace.connect(addr1).putTokenForSale(0, priceInWei);

    // Remove the token from sale
    await nftMarketPlace.connect(addr1).removeTokenFromSale(0);

    // Check if the token is no longer for sale
    const listing = await nftMarketPlace.fetchListingDetails(0);
    expect(listing.isForSale).to.be.false;
});


it("Should revert if purchase price is incorrect", async function () {
    await nftMarketPlace.connect(addr1).createToken();

    // List the token for sale (1 Ether = 1000000000000000000 Wei)
    const priceInWei = "1000000000000000000"; // 1 Ether in Wei
    await nftMarketPlace.connect(addr1).putTokenForSale(0, priceInWei);

    // Try purchasing the token with less than the required value (0.5 Ether = 500000000000000000 Wei)
    const incorrectValue = "500000000000000000"; // 0.5 Ether in Wei
    await expect(
        nftMarketPlace.connect(addr2).purchaseToken(0, { value: incorrectValue })
    ).to.be.revertedWith("Incorrect value sent");
});

it("Should not allow non-owners to remove a token from sale", async function () {
    await nftMarketPlace.connect(addr1).createToken();

    // List the token for sale (1 Ether = 1000000000000000000 Wei)
    const priceInWei = "1000000000000000000"; // 1 Ether in Wei
    await nftMarketPlace.connect(addr1).putTokenForSale(0, priceInWei);

    // Try to remove the token from sale by a non-owner (addr2)
    await expect(
        nftMarketPlace.connect(addr2).removeTokenFromSale(0)
    ).to.be.revertedWith("You are not the owner of this NFT");
});

});
