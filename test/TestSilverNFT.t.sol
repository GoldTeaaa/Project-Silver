// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverNFT} from "../src/SilverNFT.sol";

contract testSilverNft is Test {
    SilverNFT silverNFT;

    function setUp() public {
        silverNFT = new SilverNFT();
    }
}
