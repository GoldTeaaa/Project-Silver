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
    address ATTACKER = makeAddr("ATTACKER");

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

    function testBurnSilverSuccess() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 200);

        vm.prank(USER);
        bool success = i_silverERC20.burn(USER, 150);
        assertTrue(success);
        assertEq(i_silverERC20.balanceOf(USER), 50);
    }

    function testCannotBurnMoreThanBalance() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 100);

        vm.prank(USER);
        vm.expectRevert(SilverERC20.SilverERC20__InsufficientBalance.selector);
        i_silverERC20.burn(USER, 200);
    }

    function testCannotBurnIfNotOwner() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 100);

        vm.prank(ATTACKER);
        vm.expectRevert(SilverERC20.SilverERC20__UnauthorizedBurn.selector);
        i_silverERC20.burn(USER, 50);
    }

    function testCannotBurnZeroAmount() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 100);

        vm.prank(USER);
        vm.expectRevert(SilverERC20.SilverERC20__AmountMustBeGreaterThanZero.selector);
        i_silverERC20.burn(USER, 0);
    }

    function testCannotBurnFromZeroAddress() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 100);

        vm.prank(USER);
        vm.expectRevert(SilverERC20.SilverERC20__UnauthorizedBurn.selector);
        i_silverERC20.burn(address(0), 50);
    }
}
