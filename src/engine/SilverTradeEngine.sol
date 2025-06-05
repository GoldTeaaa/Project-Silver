// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISilverERC20} from "src/interface/ISilverERC20.sol";
import {ISilverNFT} from "src/interface/ISilverNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SilverTradeEngine {
    ISilverERC20 immutable i_silverERC20;
    ISilverNFT immutable i_silverNFT;
    IERC20 immutable i_mockStableCoin;

    constructor(address SilverERC20, address SilverNFT, address MockStableCoin){
        i_silverERC20 = ISilverERC20(SilverERC20);
        i_silverNFT = ISilverNFT(SilverNFT);
        i_mockStableCoin = IERC20(MockStableCoin);
    }

    /*//////////////////////////////////////////////////////////////
                              BUY SECTION
    //////////////////////////////////////////////////////////////*/
    function buySilver(uint256 amount) external {
        //check the stablecoin amount payed
        //
    }

    /*//////////////////////////////////////////////////////////////
                             REDEEM SECTION
    //////////////////////////////////////////////////////////////*/
    // To redeem the ERC20 ownership to NFT
    function redeemSilver() external {}

    /*//////////////////////////////////////////////////////////////
                       TRANSFEROWNERSHIP SECTION
    //////////////////////////////////////////////////////////////*/

    // To transfer ownership, no payment required
    // purely transfer ownership
    function TransferOwnership() external {}

    /*//////////////////////////////////////////////////////////////
                          SELL SILVER SECTION
    //////////////////////////////////////////////////////////////*/
    function sellSilver(uint256 amount) external {}

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              VIEW SECTION
    //////////////////////////////////////////////////////////////*/
}
