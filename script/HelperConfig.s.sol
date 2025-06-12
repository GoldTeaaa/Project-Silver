// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {Script, console} from "lib/forge-std/src/Script.sol";
import {SilverERC20} from "src/token/SilverERC20.sol";
import {SilverNFT} from "src/token/SilverNFT.sol";
import {MockStableCoin} from "src/token/MockStableCoin.sol";
import {deployToken} from "script/deployToken.s.sol";
import {MockV3Aggregator} from "test/mockPriceFeed/mockPriceFeed.sol";

contract HelperConfig is Script {
    deployToken tokenDeployer;

    uint256 constant INITIAL_SUPPLY = 100000e18;
    uint8 constant DECIMALS = 8;
    ///@notice Ley say the silver price per oz is $30
    int256 constant SILVER_PRICE = 30e8;

    struct NetworkConfig {
        address silverERC20Address;
        address silverNFTAddress;
        address mockStableCoinAddress;
        address priceFeedAddress;
        uint256 privKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11_155_111) {
            activeNetworkConfig = sepoliaConfig();
        } else {
            activeNetworkConfig = anvilAndLocalConfig();
        }
    }

    function sepoliaConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast(vm.envUint("MAIN_SEPOLIA"));
        SilverNFT silverNFT = new SilverNFT();
        SilverERC20 silverERC20 = new SilverERC20();
        MockStableCoin stableCoin = new MockStableCoin(INITIAL_SUPPLY);
        vm.stopBroadcast();

        return NetworkConfig({
            silverERC20Address: address(silverERC20),
            silverNFTAddress: address(silverNFT),
            mockStableCoinAddress: address(stableCoin),
            priceFeedAddress: 0x09B2D06C684772a22447Cc260001480228C1695c,
            privKey: vm.envUint("MAIN_SEPOLIA")
        });
    }

    function anvilAndLocalConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast(vm.envUint("ANVIL_PRIVATE_KEY_1"));
        SilverNFT silverNFT = new SilverNFT();
        SilverERC20 silverERC20 = new SilverERC20();
        MockStableCoin stableCoin = new MockStableCoin(INITIAL_SUPPLY);
        MockV3Aggregator priceFeed = new MockV3Aggregator(DECIMALS, SILVER_PRICE);
        vm.stopBroadcast();

        return NetworkConfig({
            silverERC20Address: address(silverERC20),
            silverNFTAddress: address(silverNFT),
            mockStableCoinAddress: address(stableCoin),
            priceFeedAddress: address(priceFeed),
            privKey: vm.envUint("ANVIL_PRIVATE_KEY_1")
        });
    }
}
