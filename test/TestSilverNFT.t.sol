// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {ISilverNFT} from "../src/interface/ISilverNFT.sol";

contract testSilverNft is Test {
    SilverNFT silverNFT;
    ISilverNFT i_silverNFT;

    function setUp() public {
        silverNFT = new SilverNFT();
        i_silverNFT = ISilverNFT(address(silverNFT));
    }
}
