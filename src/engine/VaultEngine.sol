// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISilverNFT} from "src/interface/ISilverNFT.sol";

contract VaultEngine {
    error VaultEngine__MintNftFailed();
    
    ISilverNFT i_silverNFT;

    enum VaultStatus {
        Available,
        Redeemed
    }

    struct SilverMetadata {
        string id;
        uint256 weight;
        uint256 purity;
        string redeemLocation;
        VaultStatus status;
    }

    mapping(uint256 tokenId => SilverMetadata) private s_silverMetadata;

    constructor(address SilverNFT){
        i_silverNFT = ISilverNFT(SilverNFT);
    }

    function registerBar(string memory _id, uint256 _weight, uint256 _purity, string memory _redeemLocation) public{
        uint256 tokenId = _hashIdToUInt(_id);
        
        bool success = i_silverNFT.mintNft(tokenId);
        if(!success){
            revert VaultEngine__MintNftFailed();
        }

        s_silverMetadata[tokenId] = SilverMetadata({
            id: _id,
            weight: _weight,
            purity: _purity,
            redeemLocation: _redeemLocation,
            status: VaultStatus.Available
        });
    }

    function getSilverMetadata(uint256 tokenId)
        external
        view
        returns (string memory, uint256, uint256, string memory)
    {
        return (
            s_silverMetadata[tokenId].id,
            s_silverMetadata[tokenId].weight,
            s_silverMetadata[tokenId].purity,
            s_silverMetadata[tokenId].redeemLocation
        );
    }

    function _hashIdToUInt(string memory _id) public pure returns (uint256) {
        return uint256(keccak256(bytes(_id)));
    }
}