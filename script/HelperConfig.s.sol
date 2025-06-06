// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract HelperConfig is Script{
    function getPrivKey() public view returns (uint256){
        return vm.envUint("ANVIL_PRIVATE_KEY_1");
    }
}