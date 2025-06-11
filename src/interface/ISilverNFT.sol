// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISilverNFT is IERC721 {
    function mintNft(uint256 tokenId) external returns (bool);
    function transfer(address from, address to, uint256 id) external returns (bool);
}
