// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISilverNFT is IERC721 {
    function mintNft(uint256 tokenId) external returns (bool);
    function transfer(address to, string memory id) external returns (bool);
    // function mintNft(string memory _id, uint256 _weight, uint256 _purity, string memory _redeemLocation) external returns(bool);
    // function getSilverMetadata(uint256 tokenId) external view returns (string memory, uint256, uint256, string memory);
    // function _hashIdToUInt(string memory _id) external pure returns (uint256);
}
