// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title SilverTradeEngine
 *  @author Handaya Riawan
 *  @dev Still in development stage, not proper for production.
 *  @dev This contract is used for research purpose and not yet applicable to real world usage.
 *  @dev The purpose is to give insight and idea for future development in current field.
 */
import {ISilverERC20} from "src/interface/ISilverERC20.sol";
import {ISilverNFT} from "src/interface/ISilverNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IdUtils} from "src/utils/IdUtils.sol";
import {VaultEngine} from "src/engine/VaultEngine.sol";

contract SilverTradeEngine is ReentrancyGuard {
    using IdUtils for string;

    error SilverTradeEngine__OraclePriceIsStale(int256);
    error SilverTradeEngine__AmountToBuyNeedMoreThanZero();
    error SilverTradeEngine__ExceedLimitOfMaxPurchase(uint256);
    error SilverTradeEngine__TransferFailed();
    error SilverTradeEngine__StableCoinTransferFailed();
    error SilverTradeEngine__ERC20MintFailed();
    error SilverTradeEngine__InsufficientBalanceOfSenderToTransfer(uint256);
    error SilverTradeEngine__TransferERC20OwnershipFailed();
    error SilverTradeEngine__TransferNFTOwnershipFailed();
    error SilverTradeEngine__TargetToSendAddressIsNull(address);
    error SilverTradeEngine__RedeemSilverFailed();
    error SilverTradeEngine__BurnFailed();
    error SilverTradeEngine__NotOwnerOfNFT(address);
    error SilverTradeEngine__NFTNotApproved(address);

    ISilverERC20 immutable i_silverERC20;
    ISilverNFT immutable i_silverNFT;
    IERC20 immutable i_mockStableCoin;
    AggregatorV3Interface immutable i_aggregator;
    VaultEngine immutable vault;

    int256 constant PRECISION = 1e10;
    uint256 constant MAX_AMOUNT = 1000000;

    mapping(address seller => uint256 amountToSell) private s_listedERC2OSilverToSell;
    mapping(address seller => uint256 tokenIdToSell) private s_listedNFTToSell;

    event PaymentReceived(address indexed from, address indexed to, uint256 indexed amount);
    event RedeemSilver(address indexed from, uint256 indexed amount, string indexed location);
    event SellERC20Succeeded(address indexed from, address indexed to, uint256 indexed amount);
    event NFTListed(address indexed from, uint256 indexed tokenId, string indexed silverId);
    event ERC20Unlisted(address indexed owner);
    event NFTUnlisted(address indexed owner);

    constructor(address SilverERC20, address SilverNFT, address MockStableCoin, address silverPriceFeedAddress) {
        i_silverERC20 = ISilverERC20(SilverERC20);
        i_silverNFT = ISilverNFT(SilverNFT);
        i_mockStableCoin = IERC20(MockStableCoin);
        i_aggregator = AggregatorV3Interface(silverPriceFeedAddress);
        vault = VaultEngine(SilverNFT);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier checkNullAddress(address to) {
        if (to == address(0)) {
            revert SilverTradeEngine__TargetToSendAddressIsNull(to);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              BUY SECTION
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev This buy function used to buy silver with no listed ERC20 to sell.
     * @notice The routing part to choose whether to use this buySilver or the
     * @notice buySilverERC20 function is assumed to be route from the front end.
     * @notice Buyer may arbitrarily prefer to choose this function and not check
     * @notice if there are existing silver ERC20 that listed to sell that may cause infinite minting
     */
    function buySilver(uint256 amountSilverToBuy) external virtual {
        if (amountSilverToBuy == 0) {
            revert SilverTradeEngine__AmountToBuyNeedMoreThanZero();
        }
        if (amountSilverToBuy > MAX_AMOUNT) {
            revert SilverTradeEngine__ExceedLimitOfMaxPurchase(amountSilverToBuy);
        }
        //pull price from oracle for the silver (DECIMAL IN 8, CORRECT THE PRECISION)
        int256 price = getSilverPrice();
        if (price <= 0) {
            revert SilverTradeEngine__OraclePriceIsStale(price);
        }
        //check the stablecoin amount payed
        uint256 amountToPay = amountSilverToBuy * uint256(price);

        _safeTransferStableCoin(msg.sender, address(this), amountToPay);

        bool mintSuccess = i_silverERC20.mint(msg.sender, amountSilverToBuy);
        //mint the erc20 to the user
        if (!mintSuccess) {
            revert SilverTradeEngine__ERC20MintFailed();
        }

        emit PaymentReceived(msg.sender, address(this), amountToPay);
    }

    /**
     * @notice This function is still in development stage and not proper for production.
     * @notice Assume to buy directly all the silver sold by the seller.
     */
    function buySilverERC20(address seller) external virtual {
        uint256 amountToBuy = s_listedERC2OSilverToSell[seller];
        int256 silverPrice = getSilverPrice();
        uint256 calculatedPrice = amountToBuy * uint256(silverPrice);

        _safeTransferStableCoin(msg.sender, address(this), calculatedPrice);
        _safeTransferSilverERC20(seller, msg.sender, amountToBuy);
        emit PaymentReceived(msg.sender, address(this), calculatedPrice);
    }

    /**
     * @notice Weakness of this buying model is the user have to know the seller
     * @notice for future development this have to be changed
     */
    function buySilverNFT(address seller) external virtual {
        uint256 silverNFTId = s_listedNFTToSell[seller];
        (, uint256 weight,,) = vault.getSilverNftMetadata(silverNFTId);
        int256 price = getSilverPrice();
        uint256 calculatedPrice = uint256(price) * weight;

        _safeTransferStableCoin(msg.sender, address(this), calculatedPrice);
        i_silverNFT.safeTransferFrom(address(this), msg.sender, silverNFTId);
        emit PaymentReceived(msg.sender, address(this), calculatedPrice);
    }

    /*//////////////////////////////////////////////////////////////
                             REDEEM SECTION
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Redeem the silver to its physical form
     * @notice Burn the ERC20 and mint the NFT as certificate
     */
    function redeemSilver(uint256 amountToRedeem, string calldata location) external {
        //input total silver to redeem
        //check if the vault have stocks, if not then revert
        //burn the redeemer erc20 token
        //mint the nft to the redeemer
        bool burnSuccess = i_silverERC20.burn(msg.sender, amountToRedeem);
        if (!burnSuccess) {
            revert SilverTradeEngine__BurnFailed();
        }
        bool redeemSuccess = vault.redeemFromVault(amountToRedeem, location);
        if (!redeemSuccess) {
            revert SilverTradeEngine__RedeemSilverFailed();
        }
        emit RedeemSilver(msg.sender, amountToRedeem, location);
    }

    /*//////////////////////////////////////////////////////////////
                       TRANSFEROWNERSHIP SECTION
    //////////////////////////////////////////////////////////////*/

    // To transfer ownership, no payment required
    // purely transfer ownership
    function transferERC20(address to, uint256 amountToTransfer) external checkNullAddress(to) {
        uint256 balanceOfSender = i_silverERC20.balanceOf(msg.sender);
        if (balanceOfSender < amountToTransfer) {
            revert SilverTradeEngine__InsufficientBalanceOfSenderToTransfer(balanceOfSender);
        }
        _safeTransferSilverERC20(msg.sender, to, amountToTransfer);
    }

    function transferNFT(address to, string memory silverId) external checkNullAddress(to) {
        uint256 silverNFTId = silverId._hashIdToUint();
        bool success = i_silverNFT.transfer(to, silverNFTId);
        if (!success) {
            revert SilverTradeEngine__TransferNFTOwnershipFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          SELL SILVER SECTION
    //////////////////////////////////////////////////////////////*/
    function listERC20ToSell(uint256 amountToSell) external {
        bool success = i_silverERC20.approve(address(this), amountToSell);
        if (!success) {
            revert SilverTradeEngine__TransferERC20OwnershipFailed();
        }
        s_listedERC2OSilverToSell[msg.sender] = amountToSell;
    }

    /**
     * @notice Make sure the NFT owner approve first outside this function before listing
     * @notice This algorithm is static buying that assume the buyer know what seller they want to buy from
     * @notice Future development is to store it in struct and list it in an array so the frontend
     * can iterate through the array
     */
    function listNftToSell(string calldata silverId) external virtual {
        uint256 silverNFTId = silverId._hashIdToUint();

        address ownerOfNft = i_silverNFT.ownerOf(silverNFTId);
        if (ownerOfNft != msg.sender) {
            revert SilverTradeEngine__NotOwnerOfNFT(ownerOfNft);
        }
        address approvedBy = i_silverNFT.getApproved(silverNFTId);
        if (approvedBy != address(this)) {
            revert SilverTradeEngine__NFTNotApproved(approvedBy);
        }

        s_listedNFTToSell[msg.sender] = silverNFTId;

        emit NFTListed(msg.sender, silverNFTId, silverId);
    }

    /*//////////////////////////////////////////////////////////////
                             UNLIST SECTION
    //////////////////////////////////////////////////////////////*/
    function unlistERC20ToSell() external {
        delete s_listedERC2OSilverToSell[msg.sender];
        emit ERC20Unlisted(msg.sender);
    }

    function unlistNftToSell() external {
        delete s_listedNFTToSell[msg.sender];
        emit NFTUnlisted(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTION
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice silverPrice is in 18 decimals
     */
    function getSilverPrice() internal view returns (int256) {
        (, int256 price,,,) = i_aggregator.latestRoundData();
        int256 silverPrice = (price * PRECISION);
        return silverPrice;
    }

    /**
     * @dev This can be modified if in the future it can receive more than one type of stablecoin
     * @dev But for current version, only mock stablecoin is supported for research purpose
     */
    function _safeTransferStableCoin(address from, address to, uint256 amount) internal virtual {
        bool transferSuccess = i_mockStableCoin.transferFrom(from, to, amount);
        if (!transferSuccess) {
            revert SilverTradeEngine__StableCoinTransferFailed();
        }
    }

    function _safeTransferSilverERC20(address from, address to, uint256 amount) internal {
        bool transferERC20Success = i_silverERC20.transferFrom(from, to, amount);
        if (!transferERC20Success) {
            revert SilverTradeEngine__TransferERC20OwnershipFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW SECTION
    //////////////////////////////////////////////////////////////*/
    function getCurrentSilverPrice() external view returns (int256) {
        return getSilverPrice();
    }
}
