// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {ISilverNFT} from "../src/interface/ISilverNFT.sol";
import {IdUtils} from "../src/utils/IdUtils.sol";

contract testSilverNft is Test {
    using IdUtils for string;

    SilverNFT silverNFT;
    ISilverNFT i_silverNFT;
    string silverId = "a1b2c3";
    address admin = makeAddr("admin");
    address buyer = makeAddr("buyer");
    address attacker = makeAddr("attacker");
    uint256 tokenId = silverId._hashIdToUint();

    function setUp() public {
        silverNFT = new SilverNFT();
        i_silverNFT = ISilverNFT(address(silverNFT));
    }

    // sender will be the admin
    function testCanMintNft() public {
        vm.prank(buyer);
        i_silverNFT.mintNft(tokenId);

        assertEq(i_silverNFT.ownerOf(tokenId), buyer);
    }

    function testRevertIfAlreadyMinted() public {
        vm.prank(buyer);
        i_silverNFT.mintNft(tokenId);

        vm.prank(admin);
        vm.expectRevert();
        i_silverNFT.mintNft(tokenId);
    }

    function testRevertIfTokenIdIsZero() public {
        vm.prank(buyer);
        vm.expectRevert(SilverNFT.SilverNFT__NoIdInputted.selector);
        i_silverNFT.mintNft(0);
    }

    function testCanTransfer() public {
        vm.prank(buyer);
        i_silverNFT.mintNft(tokenId);

        vm.prank(buyer);
        bool success = silverNFT.transfer(buyer, admin, tokenId);
        assertTrue(success);
        assertEq(i_silverNFT.ownerOf(tokenId), admin);
    }

    function testRevertIfNotTokenOwnerTransfer() public {
        vm.prank(buyer);
        i_silverNFT.mintNft(tokenId);

        vm.prank(attacker);
        vm.expectRevert();
        silverNFT.transfer(attacker, admin, tokenId);
    }

    function testRevertIfTransferToZeroAddress() public {
        vm.prank(buyer);
        i_silverNFT.mintNft(tokenId);

        vm.prank(buyer);
        vm.expectRevert();
        silverNFT.transfer(buyer, address(0), tokenId);
    }
}
