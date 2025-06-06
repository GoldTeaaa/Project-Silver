// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SilverNFT is ERC721 {
    error SilverNFT__TokenAlreadyMinted(uint256 tokenId);
    error SilverNFT__NoIdInputted();

    constructor() ERC721("SilverNFT", "SNFT") {}

    /**
     * use encoding or hash for the id
     */
    function mintNft(uint256 tokenId)
        external returns (bool)/* onlyRole */
    {
        if (tokenId == 0) {
            revert SilverNFT__NoIdInputted();
        }

        // If tokenId already have an owner, it already minted
        if (_ownerOf(tokenId) != address(0)) {
            revert SilverNFT__TokenAlreadyMinted(tokenId);
        }

        _mint(msg.sender, tokenId);
        return true;
    }
}
