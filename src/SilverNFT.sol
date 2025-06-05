// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SilverNFT is ERC721 {
    error SilverNFT__TokenAlreadyMinted(uint256 tokenId);
    error SilverNFT__NoIdInputted();

    struct SilverMetadata {
        string Id;
        uint256 weight;
        uint256 purity;
        string redeemLocation;
    }
    /// @dev Mapping of hashed token IDs to their metadata

    mapping(uint256 tokenId => SilverMetadata) private s_silverMetadata;

    constructor() ERC721("SilverNFT", "SNFT") {}

    /**
     * use encoding or hash for the id
     */
    function mintNft(string memory _id, uint256 _weight, uint256 _purity, string memory _redeemLocation)
        external /* onlyRole */
    {
        uint256 tokenId = _hashIdToUInt(_id);
        if (tokenId == 0) {
            revert SilverNFT__NoIdInputted();
        }

        // If tokenId already have an owner, it already minted 
        if (ownerOf(tokenId) != address(0)) {
            revert SilverNFT__TokenAlreadyMinted(tokenId);
        }

        _mint(msg.sender, tokenId);
        s_silverMetadata[tokenId] = SilverMetadata(_id, _weight, _purity, _redeemLocation);
    }

    function getSilverMetadata(uint256 tokenId)
        external
        view
        returns (string memory, uint256, uint256, string memory)
    {
        return (
            s_silverMetadata[tokenId].Id,
            s_silverMetadata[tokenId].weight,
            s_silverMetadata[tokenId].purity,
            s_silverMetadata[tokenId].redeemLocation
        );
    }

    function _hashIdToUInt(string memory _id) internal pure returns (uint256) {
        return uint256(keccak256(bytes(_id)));
    }
}
