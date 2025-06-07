// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "lib/forge-std/src/Script.sol";
import {SilverTradeEngine} from "../src/engine/SilverTradeEngine.sol";
import {deployToken} from "../script/deployToken.s.sol";
import {SilverERC20} from "../src/token/SilverERC20.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {MockStableCoin} from "../src/token/MockStableCoin.sol";

contract deployEngine is Script {
    address constant silverPriceFeedAddress = 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea;

    function run() public returns (SilverTradeEngine) {
        SilverERC20 silverERC20;
        SilverNFT silverNFT;
        MockStableCoin mockStableCoin;

        deployToken tokenAddresses = new deployToken();
        (silverERC20, silverNFT, mockStableCoin) = tokenAddresses.run();

        address silverERC20Address = address(silverERC20);
        address silverNFTAddress = address(silverNFT);
        address mockStableCoinAddres = address(mockStableCoin);

        vm.startBroadcast();
        SilverTradeEngine tradeEngine =
            new SilverTradeEngine(silverERC20Address, silverNFTAddress, mockStableCoinAddres, silverPriceFeedAddress);
        vm.stopBroadcast();
        return tradeEngine;
    }
}
