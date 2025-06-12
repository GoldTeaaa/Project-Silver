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

contract TestTradeEngine is Test {
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
    }

    /*//////////////////////////////////////////////////////////////
                               BUY SILVER
    //////////////////////////////////////////////////////////////*/

    function testRevertBuyZeroSilver() public {
        vm.prank(BUYER);
        vm.expectRevert(SilverTradeEngine.SilverTradeEngine__AmountToBuyNeedMoreThanZero.selector);
        tradeEngine.buySilver(0);
    }

    function testRevertOraclePriceStale() public {
        priceFeed.updateAnswer(0);
        uint256 buySilverInPrecision = calculatePrecision(buyTenOzSilver);
        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);

        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        vm.expectRevert(abi.encodeWithSelector(SilverTradeEngine.SilverTradeEngine__OraclePriceIsStale.selector, 0));
        tradeEngine.buySilver(buySilverInPrecision);
        vm.stopPrank();
    }

    function testBuySilverDirectly() public {
        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);

        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buyTenOzSilver);
        vm.stopPrank();

        assertEq(silverERC20.balanceOf(BUYER), buyTenOzSilverInPrecision);
        assertEq(stableCoin.balanceOf(BUYER), initialUserBalance - silverPrice);
    }

    function testBuySixteenSilverDirectly() public {
        uint256 silverPrice = calculateSilverPrice(buySixTeenSilver);
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buySixTeenSilver);

        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buySixTeenSilver);
        vm.stopPrank();

        assertEq(silverERC20.balanceOf(BUYER), buyTenOzSilverInPrecision);
        assertEq(stableCoin.balanceOf(BUYER), initialUserBalance - silverPrice);
    }

    function testBuySilverERC20() public addSilverStockInStoreA buySilver {
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);
        vm.startPrank(BUYER);
        tradeEngine.listERC20ToSell(buyTenOzSilverInPrecision);
        silverERC20.approve(address(tradeEngine), buyTenOzSilverInPrecision);
        vm.stopPrank();

        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);

        vm.startPrank(BUYER2);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilverERC20(BUYER);
        vm.stopPrank();
        assertEq(silverERC20.balanceOf(RECEIVER), 0);
        assertEq(silverERC20.balanceOf(BUYER2), buyTenOzSilverInPrecision);
    }

    function testBuySilverNFT() public addSilverStockInStoreA buyAndRedeemSilver {
        string memory silverId = randomSilverIdTwo[4];
        uint256 nftId = silverId._hashIdToUint();
        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);

        vm.startPrank(BUYER);
        tradeEngine.listNftToSell(randomSilverIdTwo[4]);
        nft.approve(address(tradeEngine), nftId);
        vm.stopPrank();

        uint256 nftIdToSell = tradeEngine.getListedNFTToSell(BUYER);
        assertEq(nftIdToSell, randomSilverIdTwo[4]._hashIdToUint());

        vm.startPrank(BUYER2);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilverNFT(BUYER);
        vm.stopPrank();
        assertEq(nft.balanceOf(BUYER), 0);
        assertEq(nft.balanceOf(BUYER2), 1);
    }

    /*//////////////////////////////////////////////////////////////
                                 REDEEM
    //////////////////////////////////////////////////////////////*/
    function testRevertRedeemInsufficientVaultStock() public {
        uint256 silverPrice = calculateSilverPrice(buySixTeenSilver);
        uint256 buySilverInPrecision = calculatePrecision(buySixTeenSilver);

        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buySixTeenSilver);
        vm.expectRevert(
            abi.encodeWithSelector(VaultEngine.VaultEngine__LocationHaveZeroSilverToRedeem.selector, redeemLocationA)
        );
        tradeEngine.redeemSilver(buySilverInPrecision, redeemLocationA);
        vm.stopPrank();
    }

    function testRedeemSilver() public addSilverStockInStoreA {
        uint256 silverPrice = calculateSilverPrice(buySixTeenSilver);
        uint256 buySixTeenSilverInPrecision = calculatePrecision(buySixTeenSilver);

        vm.startPrank(BUYER);
        stableCoin.approve(address(tradeEngine), silverPrice);
        tradeEngine.buySilver(buySixTeenSilver);
        vm.stopPrank();
        assertEq(silverERC20.balanceOf(BUYER), buySixTeenSilverInPrecision);
        assertEq(stableCoin.balanceOf(BUYER), initialUserBalance - silverPrice);
        console.log("This address balance ", address(BUYER));
        console.log("is: ", silverERC20.balanceOf(BUYER));

        vm.prank(BUYER);
        tradeEngine.redeemSilver(buySixTeenSilverInPrecision, redeemLocationA);
        assertEq(silverERC20.balanceOf(BUYER), 0);

        uint256 totalNftOwned = nft.balanceOf(BUYER);
        // uint256 nftId = randomSilverIdTwo[1]._hashIdToUint();
        assertEq(totalNftOwned, 3);
        console.log(address(vault));
        // assertEq(nft.ownerOf(nftId), BUYER);
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER ERC20 & NFT
    //////////////////////////////////////////////////////////////*/
    function testRevertInsufficientBalanceERC20Transfer() public {
        uint256 transferAmount = calculatePrecision(100);
        vm.prank(BUYER);
        vm.expectRevert(
            abi.encodeWithSelector(
                SilverTradeEngine.SilverTradeEngine__InsufficientBalanceOfSenderToTransfer.selector, 0
            )
        );
        tradeEngine.transferERC20(RECEIVER, transferAmount);
    }

    function testTransferERC20() public buySilver(){
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);

        uint256 amountToTransfer = buyTenOzSilverInPrecision / 2;
        vm.startPrank(BUYER);
        silverERC20.approve(address(tradeEngine), amountToTransfer);
        tradeEngine.transferERC20(RECEIVER, amountToTransfer);
        vm.stopPrank();
        assertEq(silverERC20.balanceOf(RECEIVER), amountToTransfer);
    }

    function testRevertNFTNotApproved() public addSilverStockInStoreA buyAndRedeemSilver {
        string memory silverId = randomSilverIdTwo[4];

        vm.prank(BUYER);
        tradeEngine.listNftToSell(silverId);

        uint256 silverPrice = calculateSilverPrice(buyTenOzSilver);
        vm.startPrank(BUYER2);
        stableCoin.approve(address(tradeEngine), silverPrice);
        vm.expectRevert();
        tradeEngine.buySilverNFT(BUYER);
        vm.stopPrank();
    }

    function testRevertListNFTNotOwned() public addSilverStockInStoreA buyAndRedeemSilver {
        vm.prank(UNAUTHORIZED);
        vm.expectRevert(
            abi.encodeWithSelector(SilverTradeEngine.SilverTradeEngine__NotOwnerOfNFT.selector, UNAUTHORIZED)
        );
        tradeEngine.listNftToSell(randomSilverIdTwo[0]);
    }

    function testTransferNFT() public addSilverStockInStoreA buySilver(){
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);

        vm.prank(BUYER);
        tradeEngine.redeemSilver(buyTenOzSilverInPrecision, redeemLocationA);
        assertEq(silverERC20.balanceOf(BUYER), 0);
        assertEq(nft.balanceOf(BUYER), 1);

        uint256[] memory nftId = new uint256[](nft.balanceOf(BUYER));
        for (uint256 i = 0; i < nft.balanceOf(BUYER); i++) {
            nftId[i] = nft.tokenOfOwnerByIndex(BUYER, i);
            console.log(nftId[i]);
        }
        address owner = nft.ownerOf(nftId[0]);
        assertEq(owner, BUYER);
        string memory firstTenOzSilverId = randomSilverIdTwo[4];
        assertEq(firstTenOzSilverId._hashIdToUint(), nftId[0]);

        vm.startPrank(BUYER);
        nft.approve(address(tradeEngine), firstTenOzSilverId._hashIdToUint());
        tradeEngine.transferNFT(RECEIVER, randomSilverIdTwo[4]);
        vm.stopPrank();

        address ownerAfterTransfer = nft.ownerOf(nftId[0]);

        assertEq(ownerAfterTransfer, RECEIVER);
    }
    /*//////////////////////////////////////////////////////////////
                             SELL FUNCTION
    //////////////////////////////////////////////////////////////*/

    function testRevertIfSellerHaveNoBalance() public buySilver(){
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);

        vm.prank(makeAddr("BROKE_MAN"));
        vm.expectRevert();
        tradeEngine.listERC20ToSell(buyTenOzSilverInPrecision);
    }

    function testListSilverERC20ToSell() public buySilver{
        uint256 buyTenOzSilverInPrecision = calculatePrecision(buyTenOzSilver);

        vm.prank(BUYER);
        tradeEngine.listERC20ToSell(buyTenOzSilverInPrecision);

        uint256 amountToSell = tradeEngine.getListedERC20ToSell(BUYER);
        assertEq(amountToSell, buyTenOzSilverInPrecision);
        assertEq(silverERC20.allowance(BUYER, address(tradeEngine)), 0);
    }

    function testListSilverNFTToSell() public addSilverStockInStoreA buyAndRedeemSilver {
        string memory silverId = randomSilverIdTwo[4];
        uint256 nftId = silverId._hashIdToUint();

        vm.startPrank(BUYER);
        tradeEngine.listNftToSell(silverId);
        nft.approve(address(tradeEngine), nftId);
        vm.stopPrank();

        uint256 nftIdToSell = tradeEngine.getListedNFTToSell(BUYER);
        assertEq(nftIdToSell, randomSilverIdTwo[4]._hashIdToUint());
    }

    function testRevertUnauthorizedSeller() public addSilverStockInStoreA buyAndRedeemSilver {
        vm.prank(UNAUTHORIZED);
        vm.expectRevert(
            abi.encodeWithSelector(SilverTradeEngine.SilverTradeEngine__NotOwnerOfNFT.selector, UNAUTHORIZED)
        );
        tradeEngine.listNftToSell(randomSilverIdTwo[4]);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/
    function allNftOwnedByUser(address user) public view returns (uint256[] memory nftId) {
        nftId = new uint256[](nft.balanceOf(user));
        for (uint256 i = 0; i < nft.balanceOf(user); i++) {
            nftId[i] = nft.tokenOfOwnerByIndex(user, i);
            console.log(nftId[i]);
        }
        return nftId;
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
