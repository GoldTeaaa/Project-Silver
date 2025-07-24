// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {SilverTradeEngine} from "../src/engine/SilverTradeEngine.sol";
import {VaultEngine} from "../src/engine/VaultEngine.sol";
import {deployToken} from "../script/deployToken.s.sol";
import {SilverERC20} from "../src/token/SilverERC20.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {MockStableCoin} from "../src/token/MockStableCoin.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract deployEngine is Script {
    VaultEngine vaultEngine;
    bytes32 public constant burnerRole = keccak256("BURNER_ROLE");
    address private sepoliaBuyer = 0x5a50d4047228AdBcD696A3B7B1a148D2e7464304;
    uint256 constant PRECISION = 1e18;
    uint256 public initialUserBalance = 10000 * PRECISION;

    function run()
        public
        returns (
            SilverTradeEngine,
            VaultEngine,
            address silverERC20Address,
            address silverNFTAddress,
            address mockStableCoinAddress,
            address priceFeedAddress
        )
    {
        uint256 privKey;
        HelperConfig config = new HelperConfig();
        (
            silverERC20Address,
            silverNFTAddress,
            mockStableCoinAddress,
            priceFeedAddress,
            privKey
        ) = config.activeNetworkConfig();

        vm.startBroadcast(privKey);
        vaultEngine = new VaultEngine(silverNFTAddress);
        SilverTradeEngine tradeEngine = new SilverTradeEngine(
            silverERC20Address, silverNFTAddress, mockStableCoinAddress, priceFeedAddress, address(vaultEngine)
        );
        registerInitialBarSupply();
        SilverERC20(silverERC20Address).grantRole(burnerRole, address(tradeEngine));
        if (block.chainid == 11_155_111 || block.chainid == 300) {
            MockStableCoin(mockStableCoinAddress).transfer(sepoliaBuyer, initialUserBalance);
        }
        vm.stopBroadcast();
        return (tradeEngine, vaultEngine, silverERC20Address, silverNFTAddress, mockStableCoinAddress, priceFeedAddress);
    }

    function registerInitialBarSupply() internal {
        vaultEngine.registerBar("SILV-1", 1, 999, "StoreA");
        vaultEngine.registerBar("SILV-1.2", 1, 999, "StoreA");
        vaultEngine.registerBar("SILV-1.3", 1, 999, "StoreA");
        vaultEngine.registerBar("SILV-5", 5, 999, "StoreA");
        vaultEngine.registerBar("SILV-10", 10, 999, "StoreA");
        vaultEngine.registerBar("SILV-50", 50, 999, "StoreA");
    }
}
