// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISilverNFT is IERC721 {
    function mintNft(string memory _id, uint256 _weight, uint256 _purity, string memory _redeemLocation) external;
    function getSilverMetadata(uint256 tokenId) external view returns (string memory, uint256, uint256, string memory);
}
