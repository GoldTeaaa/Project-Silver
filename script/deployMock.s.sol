// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "test/mockPriceFeed/mockPriceFeed.sol";

contract DeployMockPriceFeed is Script{
    function run() public{ 
        vm.startBroadcast(vm.envUint("MAIN_SEPOLIA"));
        MockV3Aggregator priceFeed = new MockV3Aggregator(8,30e8);
        vm.stopBroadcast();
    }
}