// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Books.sol";

contract BooksTest is Test {
    Books public books;
    address public admin;
    address public minter;
    address public recipient;
    uint256[] public tokenId;
    string public tokenURI = "https://example.com/token";
    uint256[] public amount;
    string public baseURI = "https://example.com/base/";

    function setUp() public {
        admin = address(0x1);
        minter = address(0x2);
        recipient = address(0x3);

        books = new Books(admin, "Book", "BOOK", admin, 1000);

        // Grant MINTER_ROLE to minter address
        books.grantRole(books.MINTER_ROLE(), minter);

        tokenId = new uint256[](2);
        amount = new uint256[](2);

        // Mint tokens with IDs 0 and 1 to ensure they exist
        vm.prank(minter);
        books.mintTo(recipient, type(uint256).max, tokenURI, 10);

        vm.prank(minter);
        books.mintTo(recipient, type(uint256).max, tokenURI, 10);
    }

    function testMintTo() public {
        uint256 singleAmount = 5; // Define the amount to mint

        vm.prank(minter);
        books.mintTo(recipient, 0, tokenURI, singleAmount);

        // Verify minting
        assertEq(books.balanceOf(recipient, 0), singleAmount);
        assertEq(books.nextTokenIdToMint(), 2);
    }

    function testBatchMintTo() public {
        tokenId[0] = 0;
        tokenId[1] = 1;
        amount[0] = 5;
        amount[1] = 15;

        vm.prank(minter);
        books.batchMintTo(recipient, tokenId, amount, baseURI);

        // Verify minting
        assertEq(books.balanceOf(recipient, 0), 5);
        assertEq(books.balanceOf(recipient, 1), 15);
        assertEq(books.nextTokenIdToMint(), 2);
    }

    function testBurn() public {
        uint256 burnAmount = 5; // Define the amount to mint and burn

        vm.prank(minter);
        books.mintTo(recipient, 1, tokenURI, burnAmount);

        vm.prank(minter);
        books.burn(recipient, 1, burnAmount);

        // Verify burning
        assertEq(books.balanceOf(recipient, 1), 0);
    }

    function testBatchBurn() public {
        tokenId[0] = 0;
        tokenId[1] = 1;
        amount[0] = 5;
        amount[1] = 15;

        // Mint tokens to be burned
        vm.prank(minter);
        books.mintTo(recipient, 0, tokenURI, 5);
        vm.prank(minter);
        books.mintTo(recipient, 1, tokenURI, 15);

        vm.prank(minter);
        books.burnBatch(recipient, tokenId, amount);

        // Verify burning
        assertEq(books.balanceOf(recipient, 1), 0);
        assertEq(books.balanceOf(recipient, 2), 0);
    }

    function testTransferRestriction() public {
        // Attempt to transfer tokens should revert
        vm.prank(recipient);
        vm.expectRevert("Transfers are disabled");
        books.safeTransferFrom(recipient, address(0x4), 1, 1, "");
    }
}


