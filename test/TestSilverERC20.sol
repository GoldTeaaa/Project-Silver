// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverERC20} from "../src/token/SilverERC20.sol";
import {ISilverERC20} from "../src/interface/ISilverERC20.sol";
import {deployToken} from "../script/deployToken.s.sol";
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract testSilverERC20 is StdCheats, Test, AccessControl{
    SilverERC20 silverERC20;
    ISilverERC20 i_silverERC20;
    deployToken deployer;

    address vaultAdmin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address USER = makeAddr("USER");
    address ATTACKER = makeAddr("ATTACKER");
    bytes32 immutable burnerRole = keccak256("BURNER_ROLE");

    function setUp() public {
        deployer = new deployToken();
        (silverERC20,,) = deployer.run();
        i_silverERC20 = ISilverERC20(address(silverERC20));

        // vm.prank(vaultAdmin);
        // silverERC20.grantRole(burnerRole, USER);
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

        vm.prank(address(deployer));
        bool success = i_silverERC20.burn(USER, 150);
        assertTrue(success);
        assertEq(i_silverERC20.balanceOf(USER), 50);
    }

    function testCannotBurnMoreThanBalance() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 100);

        vm.prank(USER);
        vm.expectRevert();
        i_silverERC20.burn(USER, 200);
    }

    // function testCannotBurnIfNotOwner() public {
    //     vm.prank(USER);
    //     i_silverERC20.mint(USER, 100);

    //     vm.prank(ATTACKER);
    //     vm.expectRevert(SilverERC20.SilverERC20__UnauthorizedBurn.selector);
    //     i_silverERC20.burn(USER, 50);
    // }

    function testCannotBurnZeroAmount() public {
        vm.prank(USER);
        i_silverERC20.mint(USER, 100);

        vm.prank(USER);
        vm.expectRevert(SilverERC20.SilverERC20__AmountMustBeGreaterThanZero.selector);
        i_silverERC20.burn(USER, 0);
    }

    // function testCannotBurnFromZeroAddress() public {
    //     vm.prank(USER);
    //     i_silverERC20.mint(USER, 100);

    //     vm.prank(USER);
    //     vm.expectRevert();
    //     i_silverERC20.burn(address(0), 50);
    // }
}
