// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISilverNFT} from "src/interface/ISilverNFT.sol";
import {ISilverERC20} from "src/interface/ISilverERC20.sol";
import {IdUtils} from "src/utils/IdUtils.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";

contract VaultEngine is AccessControl, Test {
    using IdUtils for string;

    error VaultEngine__MintNftFailed();
    error VaultEngine__MintNftFailedBecauseNotEnoughSilverStock(uint256);
    error VaultEngine__WeightCanOnlyBeOneFiveTenOrFifty(uint256);
    error VaultEngine__RedeemCallerMustBeFromVault(address);
    error VaultEngine__GrantRoleFailed();
    error VaultEngine__LocationHaveZeroSilverToRedeem(string);

    ISilverNFT i_silverNFT;
    ISilverERC20 i_silverERC20;

    bytes32 private vaultAdminRole = keccak256("VAULT_ADMIN_ROLE");

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

    mapping(string location => mapping(uint256 weight => uint256[] tokenId)) private
        s_availableTokensByLocationAndWeight;
    mapping(uint256 tokenId => SilverMetadata) private s_silverMetadata;

    uint256[4] weights = [50, 10, 5, 1];

    event TransferredNFT(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor(address SilverNftAddress) {
        i_silverNFT = ISilverNFT(SilverNftAddress);

        bool successGrantRole = _grantRole(vaultAdminRole, msg.sender);
        if (!successGrantRole) {
            revert VaultEngine__GrantRoleFailed();
        }
    }

    /**
     * @notice Weight fractional can only be 1, 5, 10 and 50
     *  @notice The mint NFT owner by default is this contract, not the EOA
     */
    function registerBar(string memory _id, uint256 _weight, uint256 _purity, string memory _redeemLocation)
        public
        onlyRole(vaultAdminRole)
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
    function redeemFromVault(address receiver, uint256 amountToRedeem, string calldata location) external returns (bool) {
        //Select how many NFT to be redeemed
        //check the stock in the location
        bool haveStocks = checkIfStoreLocationHaveStock(location);
        if (!haveStocks) {
            revert VaultEngine__LocationHaveZeroSilverToRedeem(location);
        }
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
                i_silverNFT.safeTransferFrom(address(this), receiver, tokenId);
                emit TransferredNFT(address(this), receiver, tokenId);
                remaining -= weight;
            }

            weightIndex++;
        }
        if (remaining != 0) {
            revert VaultEngine__MintNftFailedBecauseNotEnoughSilverStock(remaining);
        }

        return true;
    }

    function getSilverNftMetadata(uint256 tokenId) external view returns (SilverMetadata memory) {
        return s_silverMetadata[tokenId];
    }

    function checkIfStoreLocationHaveStock(string calldata location) internal view returns (bool) {
        for(uint256 i=0; i<weights.length; i++) {
            if (s_availableTokensByLocationAndWeight[location][weights[i]].length > 0) {
                return true;
            }
        }
        return false;
    }
}
