// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SilverTradeEngine} from "src/engine/SilverTradeEngine.sol";
import {SilverERC20} from "src/token/SilverERC20.sol";
import {SilverNFT} from "src/token/SilverNFT.sol";
import {MockStableCoin} from "src/token/MockStableCoin.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract deployToken is Script {
    uint256 constant INITIAL_SUPPLY = 10 ** 18;

    function run() public returns (SilverERC20, SilverNFT, MockStableCoin) {
        vm.startBroadcast();
        SilverNFT silverNFT = new SilverNFT();
        SilverERC20 silverERC20 = new SilverERC20();
        MockStableCoin stableCoin = new MockStableCoin(INITIAL_SUPPLY);
        vm.stopBroadcast();

        return (silverERC20, silverNFT, stableCoin);
    }
}
