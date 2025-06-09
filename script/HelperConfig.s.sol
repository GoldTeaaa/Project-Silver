// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {SilverERC20} from "src/token/SilverERC20.sol";
import {SilverNFT} from "src/token/SilverNFT.sol";
import {MockStableCoin} from "src/token/MockStableCoin.sol";
import {deployToken} from "script/deployToken.s.sol";
import {MockV3Aggregator} from "test/mockPriceFeed/mockPriceFeed.sol";

contract HelperConfig is Script {
    deployToken tokenDeployer;

    uint256 constant INITIAL_SUPPLY = 1e10;
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
        if(block.chainid == 11_155_111) {
            activeNetworkConfig = sepoliaConfig();
        }else{
            activeNetworkConfig = anvilAndLocalConfig();
        }
    }

    function sepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            silverERC20Address: 0x37335Da66c7162AcE607f369B295998F2d4a8f31,
            silverNFTAddress: 0x6a1605A5dE4aa4822AA914182E044A09B97d0b70,
            mockStableCoinAddress: 0x560c5a5471eA62597CaDAf25918c6E845F72F16f,
            priceFeedAddress: 0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea,
            privKey: vm.envUint("MAIN_SEPOLIA")
        });
    }

    function anvilAndLocalConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
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
