// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISilverNFT} from "src/interface/ISilverNFT.sol";
import {ISilverERC20} from "src/interface/ISilverERC20.sol";
import {IdUtils} from "src/utils/IdUtils.sol";

contract VaultEngine {
    using IdUtils for string;

    error VaultEngine__MintNftFailed();
    error VaultEngine__MintNftFailedBecauseNotEnoughFractionalSilverWeight(uint256);
    error VaultEngine__WeightCanOnlyBeOneFiveTenOrFifty(uint256);
    error VaultEngine__RedeemCallerMustBeFromVault(address);

    ISilverNFT i_silverNFT;
    ISilverERC20 i_silverERC20;

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

    event TransferredNFT(address indexed from, address indexed to, uint256 indexed tokenId);

    mapping(uint256 tokenId => SilverMetadata) private s_silverMetadata;
    mapping(string location => mapping(uint256 weight => uint256[] tokenId)) private
        s_availableTokensByLocationAndWeight;

    modifier redeemMustBeFromVault(address sender) {
        if (sender != address(this)) {
            revert VaultEngine__RedeemCallerMustBeFromVault(sender);
        }
        _;
    }

    constructor(address SilverNftAddress ) {
        i_silverNFT = ISilverNFT(SilverNftAddress);
    }

    /**
     * @notice Weight fractional can only be 1, 5, 10 and 50
     */
    function registerBar(string memory _id, uint256 _weight, uint256 _purity, string memory _redeemLocation)
        public /* addRole */
    {
        if (_weight != 1 && _weight != 5 && _weight != 10 && _weight != 50) {
            revert VaultEngine__WeightCanOnlyBeOneFiveTenOrFifty(_weight);
        }

        //tokenId checks done in mintNft
        uint256 tokenId = _id._hashIdToUint();

        bool success = i_silverNFT.mintNft(tokenId);
        if (!success) {
            revert VaultEngine__MintNftFailed();
        }
        i_silverNFT.safeTransferFrom(msg.sender, address(this), tokenId);

        s_silverMetadata[tokenId] = SilverMetadata({
            id: _id,
            weight: _weight,
            purity: _purity,
            redeemLocation: _redeemLocation,
            status: VaultStatus.Available
        });

        s_availableTokensByLocationAndWeight[_redeemLocation][_weight].push(tokenId);
    }

    /**
     * @dev [WARNING!] Revert if the fractional doesnt match the amountToRedeem, not production safe!
     * @dev use greedy algorithm to redeem
     */
    function redeemFromVault(uint256 amountToRedeem, string calldata location)
        external
        redeemMustBeFromVault(msg.sender)
        returns (bool)
    {
        //Select how many NFT to be redeemed
        //check the stock in the location
        //check if the silver available
        uint256[4] memory weights = [uint256(50), 10, 5, 1];
        uint256 remaining = amountToRedeem;
        uint256 weightIndex = 0;

        while (weightIndex < weights.length && remaining > 0) {
            uint256 weight = weights[weightIndex];
            uint256[] storage pool = s_availableTokensByLocationAndWeight[location][weight];

            while (remaining >= weight && pool.length > 0) {
                uint256 tokenId = pool[pool.length - 1];
                //Remove the used tokenId from the temporary pool
                pool.pop();

                // Update status
                s_silverMetadata[tokenId].status = VaultStatus.Redeemed;

                // Transfer to redeemer
                i_silverNFT.safeTransferFrom(address(this), msg.sender, tokenId);
                emit TransferredNFT(address(this), msg.sender, tokenId);
                remaining -= weight;
            }

            weightIndex++;
        }

        if (remaining != 0) {
            revert VaultEngine__MintNftFailedBecauseNotEnoughFractionalSilverWeight(remaining);
        }

        return true;
    }

    function getSilverNftMetadata(uint256 tokenId)
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
}
