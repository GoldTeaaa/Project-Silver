// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdCheats} from "lib/forge-std/src/StdCheats.sol";
import {SilverNFT} from "../src/token/SilverNFT.sol";
import {SilverERC20} from "../src/token/SilverERC20.sol";
import {VaultEngine} from "../src/engine/VaultEngine.sol";
import {deployEngine} from "../script/deployEngine.s.sol";
import {IdUtils} from "../src/utils/IdUtils.sol";
import {MockStableCoin} from "../src/token/MockStableCoin.sol";
import {MockV3Aggregator} from "test/mockPriceFeed/mockPriceFeed.sol";
import {SilverTradeEngine} from "../src/engine/SilverTradeEngine.sol";

contract TestRedeemSilver is Test {
    using IdUtils for string;

    VaultEngine vault;
    deployEngine deployer;
    SilverNFT nft;
    SilverERC20 silverERC20;
    MockStableCoin stableCoin;
    SilverTradeEngine tradeEngine;
    MockV3Aggregator priceFeed;

    address public silverERC2OAddress;
    address public silverNFTAddress;
    address public stableCoinAddress;
    address public priceFeedAddress;

    address vaultAdmin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public BUYER = makeAddr("BUYER");
    address public BUYER2 = makeAddr("BUYER2");
    address public RECEIVER = makeAddr("RECEIVER");
    address public UNAUTHORIZED = makeAddr("UNAUTHORIZED");
    uint256 public initialUserBalance = 10000 * PRECISION; //Let say its equal to 10k USD value
    uint256 buyTenOzSilver = 10;
    uint256 buySixTeenSilver = 16;
    uint256 constant PRECISION = 1e18;
    uint256[] _weight = [50, 10, 5, 1];
    uint256 _purity = 999;
    string redeemLocationA = "Store A";
    string redeemLocationB = "Store B";

    string[] randomSilverIdOne = ["1a9f3d", "3b7e5c", "8f2a0e", "e1c4b9", "a7b5f1"];
    string[] randomSilverIdTwo = ["0d4c9a", "f3e8a1", "7b1d2c", "9c0b7e", "56e3f2"];
    string[] randomSilverIdThree = ["a1b2c3", "d4e5f6", "123abc", "789def", "bada55"];
    string[] randomSilverIdFour = ["feedbe", "deadfa", "fa11ed", "c0ffee", "decade"];
    string[] randomSilverIdFive = ["5e7a9d", "2b4c6e", "9f8a1c", "0e1f2d", "7d3a6b"];
    string[] randomSilverIdSix = ["aabbcc", "112233", "334455", "abc123", "efcdab"];
    string[] randomSilverIdSeven = ["c4f8b3", "b8d2e1", "f1a0c9", "2e4a7b", "904edc"];
    string[] randomSilverIdEight = ["8d1a2c", "3f9b7e", "0a4e1f", "b3c6a8", "e4f1d0"];

    uint256 silverPrice = calculateSilverPrice(buySixTeenSilver);
    uint256 buySixTeenSilverInPrecision = calculatePrecision(buySixTeenSilver);

    modifier addSilverStockInStoreA() {
        vm.startPrank(vaultAdmin);
        for (uint256 i = 0; i < 5; i++) {
            vault.registerBar(randomSilverIdOne[i], _weight[0], _purity, redeemLocationA); //50
            vault.registerBar(randomSilverIdTwo[i], _weight[1], _purity, redeemLocationA); //10
            vault.registerBar(randomSilverIdThree[i], _weight[2], _purity, redeemLocationA); //5
            vault.registerBar(randomSilverIdFour[i], _weight[3], _purity, redeemLocationA); //1
        }
        vm.stopPrank();
        _;
    }

    modifier addSilverStockInStoreB() {
        vm.startPrank(vaultAdmin);
        for (uint256 i = 0; i < 5; i++) {
            vault.registerBar(randomSilverIdFive[i], _weight[0], _purity, redeemLocationB);
            vault.registerBar(randomSilverIdSix[i], _weight[1], _purity, redeemLocationB);
            vault.registerBar(randomSilverIdSeven[i], _weight[2], _purity, redeemLocationB);
            vault.registerBar(randomSilverIdEight[i], _weight[3], _purity, redeemLocationB);
        }
        vm.stopPrank();
        _;
    }

    modifier buyAndRedeemSilver() {
        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);
        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buyTenOzSilver);
        tradeEngine.redeemSilver(buyTenOzSilverInPrecision, redeemLocationA);
        vm.stopPrank();
        _;
    }

    modifier buySilver() {
        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);
        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buyTenOzSilver);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        deployer = new deployEngine();
        (tradeEngine, vault, silverERC2OAddress, silverNFTAddress, stableCoinAddress, priceFeedAddress) = deployer.run();
        nft = SilverNFT(silverNFTAddress);
        silverERC20 = SilverERC20(silverERC2OAddress);
        stableCoin = MockStableCoin(stableCoinAddress);
        priceFeed = MockV3Aggregator(priceFeedAddress);

        vm.startPrank(vaultAdmin);
        stableCoin.transfer(BUYER, initialUserBalance);
        stableCoin.transfer(BUYER2, initialUserBalance);
        silverERC20.grantRole(silverERC20.getBurnerRole(), address(tradeEngine));
        vm.stopPrank();

        vm.startPrank(vaultAdmin);
        for (uint256 i = 0; i < 5; i++) {
            vault.registerBar(randomSilverIdOne[i], _weight[0], _purity, redeemLocationA); //50
            vault.registerBar(randomSilverIdTwo[i], _weight[1], _purity, redeemLocationA); //10
            vault.registerBar(randomSilverIdThree[i], _weight[2], _purity, redeemLocationA); //5
            vault.registerBar(randomSilverIdFour[i], _weight[3], _purity, redeemLocationA); //1
        }
        vm.stopPrank();

        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buySixTeenSilver);
        vm.stopPrank();
        assertEq(silverERC20.balanceOf(BUYER), buySixTeenSilverInPrecision);
        assertEq(stableCoin.balanceOf(BUYER), initialUserBalance - silverPrice);
        console.log("This address balance ", address(BUYER));
        console.log("is: ", silverERC20.balanceOf(BUYER));
    }

    function testRedeemSilverTwo() public {
        vm.prank(BUYER);
        tradeEngine.redeemSilver(buySixTeenSilverInPrecision, redeemLocationA);
        assertEq(silverERC20.balanceOf(BUYER), 0);
    }

    function approveAndRedeemSilver(uint256 amount, uint256 amountPrecision) public {
        uint256 amountToSpend = calculateSilverPrice(amount);
        stableCoin.approve(address(tradeEngine), amountToSpend);
        tradeEngine.buySilver(amountPrecision);
    }

    function calculateSilverPrice(uint256 amount) public view returns (uint256 price) {
        uint256 silverPrice = tradeEngine.getSilverPrice();
        price = amount * silverPrice; //This in 8 decimals
        return price;
    }

    function calculatePrecision(uint256 amount) internal pure returns (uint256 precision) {
        precision = amount * PRECISION;
        return precision;
    }
}