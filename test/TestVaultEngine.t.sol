// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {IdUtils} from "../src/utils/IdUtils.sol";
import {VaultEngine} from "../src/engine/VaultEngine.sol";
import {deployEngine} from "../script/deployEngine.s.sol";
import {deployToken} from "../script/deployToken.s.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IdUtils} from "../src/utils/IdUtils.sol";

contract TestVaultEngine is Test, AccessControl {
    using IdUtils for string;

    VaultEngine vault;
    deployEngine deployer;
    deployToken tokenDeployer;
    SilverNFT nft;

    //In the script, it use the first anvil account to deploy, and the first anvil account is as below
    address vaultAdmin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address randomUser = makeAddr("randomUser");
    string _id = "a1b2c3";
    uint256[] _weight = [1, 5, 10, 50];
    uint256 _purity = 999;
    string _redeemLocationA = "Store A";
    string _redeemLocationB = "Store B";
    address silverNFTAddress;

    string[] randomSilverIdOne = ["1a9f3d", "3b7e5c", "8f2a0e", "e1c4b9", "a7b5f1"];
    string[] randomSilverIdTwo = ["0d4c9a", "f3e8a1", "7b1d2c", "9c0b7e", "56e3f2"];
    string[] randomSilverIdThree = ["a1b2c3", "d4e5f6", "123abc", "789def", "bada55"];
    string[] randomSilverIdFour = ["feedbe", "deadfa", "fa11ed", "c0ffee", "decade"];
    string[] randomSilverIdFive = ["5e7a9d", "2b4c6e", "9f8a1c", "0e1f2d", "7d3a6b"];
    string[] randomSilverIdSix = ["aabbcc", "112233", "334455", "abc123", "efcdab"];
    string[] randomSilverIdSeven = ["c4f8b3", "b8d2e1", "f1a0c9", "2e4a7b", "904edc"];
    string[] randomSilverIdEight = ["8d1a2c", "3f9b7e", "0a4e1f", "b3c6a8", "e4f1d0"];


    modifier addSilverStockInStoreA() {
        vm.startPrank(vaultAdmin);
        for(uint256 i = 0; i < 5; i++) {
            vault.registerBar(randomSilverIdOne[i], _weight[0], _purity, _redeemLocationA);
            vault.registerBar(randomSilverIdTwo[i], _weight[1], _purity, _redeemLocationA);
            vault.registerBar(randomSilverIdThree[i], _weight[2], _purity, _redeemLocationA);
            vault.registerBar(randomSilverIdFour[i], _weight[3], _purity, _redeemLocationA);
        }
        vm.stopPrank();
        _;
    }

    modifier addSilverStockInStoreB() {
        vm.startPrank(vaultAdmin);
        for(uint256 i = 0; i < 5; i++) {
            vault.registerBar(randomSilverIdFive[i], _weight[0], _purity, _redeemLocationB);
            vault.registerBar(randomSilverIdSix[i], _weight[1], _purity, _redeemLocationB);
            vault.registerBar(randomSilverIdSeven[i], _weight[2], _purity, _redeemLocationB);
            vault.registerBar(randomSilverIdEight[i], _weight[3], _purity, _redeemLocationB);
        }
        vm.stopPrank();
        _;
    }

    ///@notice the deployer for local test is the first anvil account that can be seen in the HelperConfig
    function setUp() public {
        deployer = new deployEngine();
        (,vault,,silverNFTAddress,,) = deployer.run();
        nft = SilverNFT(silverNFTAddress);
    }

    /*//////////////////////////////////////////////////////////////
                                REGISTER
    //////////////////////////////////////////////////////////////*/

    function testRevertIfRegisterBarNotAdmin() public {
        vm.prank(randomUser);
        vm.expectRevert();
        vault.registerBar(_id, _weight[1], _purity, _redeemLocationA);
    }

    function testRevertIfSilverIdAlreadyRegistered() public {
        vm.prank(vaultAdmin);
        vault.registerBar(_id, _weight[1], _purity, _redeemLocationA);
        vm.expectRevert();
        vault.registerBar(_id, _weight[1], _purity, _redeemLocationA);
    }

    function testRegisterBar() public {
        vm.prank(vaultAdmin);
        vault.registerBar(_id, _weight[1], _purity, _redeemLocationA);

        uint256 tokenId = _id._hashIdToUint();
        assertEq(nft.ownerOf(tokenId), address(vault));

        assertEq(vault.getSilverNftMetadata(tokenId).id, _id);
        assertEq(vault.getSilverNftMetadata(tokenId).weight, _weight[1]);
        assertEq(vault.getSilverNftMetadata(tokenId).purity, _purity);
        assertEq(vault.getSilverNftMetadata(tokenId).redeemLocation, _redeemLocationA);
    }

    function testRevertIfWeightNotOneFiveTenOrFifty() public {
        vm.prank(vaultAdmin);
        vm.expectRevert();
        vault.registerBar(_id, 2, _purity, _redeemLocationA);
    }

    /*//////////////////////////////////////////////////////////////
                                 REDEEM
    //////////////////////////////////////////////////////////////*/

    function testRedeemOneSilverNft() public {
        vm.prank(vaultAdmin);
        vault.registerBar(_id, _weight[0], _purity, _redeemLocationA);

        uint256 tokenId = _id._hashIdToUint();
        vm.prank(randomUser);
        vault.redeemFromVault(1, _redeemLocationA);
        assertEq(nft.balanceOf(randomUser), 1);
    }

    function testRedeemMultipleSilverNft() public addSilverStockInStoreA() {
        vm.prank(randomUser);
        vault.redeemFromVault(10, _redeemLocationA);
        assertEq(nft.balanceOf(randomUser), 1);
    }

    function testRedeemMultipleNftAndCheckTheWeight() public addSilverStockInStoreA() {
        vm.prank(randomUser);
        vault.redeemFromVault(8, _redeemLocationA); //Should return 4 NFT, 1 NFT with weight of 5 oz, and 3 NFT with weight of 1 oz
        assertEq(nft.balanceOf(randomUser), 4);
    }
}
