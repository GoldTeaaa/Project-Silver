// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISilverERC20} from "src/interface/ISilverERC20.sol";
import {ISilverNFT} from "src/interface/ISilverNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SilverTradeEngine is ReentrancyGuard{
    error SilverTradeEngine__OraclePriceIsStale(int256);
    error SilverTradeEngine__AmountToBuyNeedMoreThanZero();
    error SilverTradeEngine__ExceedLimitOfMaxPurchase(uint256);
    error SilverTradeEngine__TransferFailed();
    error SilverTradeEngine__StableCoinTransferFailed();
    error SilverTradeEngine__ERC20MintFailed();

    ISilverERC20 immutable i_silverERC20;
    ISilverNFT immutable i_silverNFT;
    IERC20 immutable i_mockStableCoin;
    AggregatorV3Interface immutable i_aggregator;

    int256 constant PRECISION = 10e10;
    uint256 constant MAX_AMOUNT = 1000000;

    constructor(address SilverERC20, address SilverNFT, address MockStableCoin, address silverPriceFeedAddress){
        i_silverERC20 = ISilverERC20(SilverERC20);
        i_silverNFT = ISilverNFT(SilverNFT);
        i_mockStableCoin = IERC20(MockStableCoin);
        i_aggregator = AggregatorV3Interface(silverPriceFeedAddress);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              BUY SECTION
    //////////////////////////////////////////////////////////////*/
    function buySilver(uint256 amountSilverToBuy) external {
        if(amountSilverToBuy == 0){
            revert SilverTradeEngine__AmountToBuyNeedMoreThanZero();
        }
        if(amountSilverToBuy > MAX_AMOUNT){
            revert SilverTradeEngine__ExceedLimitOfMaxPurchase(amountSilverToBuy);
        }
        //pull price from oracle for the silver (DECIMAL IN 8, CORRECT THE PRECISION)
        int256 price = getSilverPrice();
        if(price <= 0){
            revert SilverTradeEngine__OraclePriceIsStale(price);
        }
        //check the stablecoin amount payed
        uint256 amountToPay = amountSilverToBuy * uint256(price);

        bool transferSuccess = i_mockStableCoin.transferFrom(msg.sender, address(this), amountToPay);
        if(!transferSuccess){
            revert SilverTradeEngine__StableCoinTransferFailed();
        }

        bool mintSuccess = i_silverERC20.mint(msg.sender, amountSilverToBuy);
        //mint the erc20 to the user
        if(!mintSuccess){
            revert SilverTradeEngine__ERC20MintFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                             REDEEM SECTION
    //////////////////////////////////////////////////////////////*/
    /**
    @notice Redeem the silver to its physical form
    @notice Burn the ERC20 and mint the NFT as certificate
     */
    function redeemSilver(uint256 amountToRedeem) external {
        //input total silver to redeem
        //check if the vault have stocks, if not then revert
        //burn the redeemer erc20 token
        //mint the nft to the redeemer
    }

    /*//////////////////////////////////////////////////////////////
                       TRANSFEROWNERSHIP SECTION
    //////////////////////////////////////////////////////////////*/

    // To transfer ownership, no payment required
    // purely transfer ownership
    function TransferERC20Ownership() external {

    }

    function TransferNFTOwnership() external {

    }

    /*//////////////////////////////////////////////////////////////
                          SELL SILVER SECTION
    //////////////////////////////////////////////////////////////*/
    function sellERC20Silver(uint256 amount) external {}

    function sellNFTSilver(uint256 amount) external {}

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/
    /**
    @notice silverPrice is in 18 decimals
     */
    function getSilverPrice() internal view returns (int256) {
        (, int256 price,,,) = i_aggregator.latestRoundData();
        int256 silverPrice = (price * PRECISION);
        return silverPrice;
    }


    /*//////////////////////////////////////////////////////////////
                              VIEW SECTION
    //////////////////////////////////////////////////////////////*/
}
