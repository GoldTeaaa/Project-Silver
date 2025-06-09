// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "lib/forge-std/src/Script.sol";
import {SilverTradeEngine} from "../src/engine/SilverTradeEngine.sol";
import {VaultEngine} from "../src/engine/VaultEngine.sol";
import {deployToken} from "../script/deployToken.s.sol";
import {SilverERC20} from "../src/token/SilverERC20.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {MockStableCoin} from "../src/token/MockStableCoin.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract deployEngine is Script {
    function run()
        public
        returns (
            SilverTradeEngine,
            VaultEngine,
            address ,
            address ,
            address ,
            address 
        )
    {
        HelperConfig config = new HelperConfig();
        (
            address silverERC20Address,
            address silverNFTAddress,
            address mockStableCoinAddress,
            address priceFeedAddress,
            uint256 privKey
        ) = config.activeNetworkConfig();

        vm.startBroadcast(privKey);
        SilverTradeEngine tradeEngine =
            new SilverTradeEngine(silverERC20Address, silverNFTAddress, mockStableCoinAddress, priceFeedAddress);
        VaultEngine vaultEngine = new VaultEngine(silverNFTAddress);
        vm.stopBroadcast();
        return (tradeEngine, vaultEngine, silverERC20Address, silverNFTAddress, mockStableCoinAddress, priceFeedAddress);
    }
}
