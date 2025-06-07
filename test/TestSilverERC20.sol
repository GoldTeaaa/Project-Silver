// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverERC20} from "../src/token/SilverERC20.sol";
import {ISilverERC20} from "../src/interface/ISilverERC20.sol";
import {deployToken} from "../script/deployToken.s.sol";

contract testSilverERC20 is StdCheats, Test {
    SilverERC20 silverERC20;
    ISilverERC20 i_silverERC20;
    deployToken deployer;

    address USER = makeAddr("USER");

    function setUp() public {
        deployer = new deployToken();
        (silverERC20,,) = deployer.run();
        i_silverERC20 = ISilverERC20(address(silverERC20));
    }

    function testMintSilver() public {
        vm.prank(msg.sender);
        i_silverERC20.mint(USER, 100);

        vm.assertEq(i_silverERC20.balanceOf(USER), 100);
    }

    function testCannotMintToEmptyAddress() public {
        vm.expectRevert();
        vm.prank(msg.sender);
        i_silverERC20.mint(address(0), 100);
    }

    function testCannotMintZero() public {
        vm.expectRevert();
        vm.prank(msg.sender);
        i_silverERC20.mint(USER, 0);
    }
}
