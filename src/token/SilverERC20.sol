// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SilverERC20 is ERC20 {
    error SilverERC20__AddressCantBeNull();
    error SilverERC20__AmountMustBeGreaterThanZero();
    error SilverERC20__InsufficientBalance();
    error SilverERC20__UnauthorizedBurn();

    constructor() ERC20("ETHSilver", "ESLV") {}

    function mint(address _to, uint256 _amount) external {
        if (_to == address(0)) {
            revert SilverERC20__AddressCantBeNull();
        }
        if (_amount <= 0) {
            revert SilverERC20__AmountMustBeGreaterThanZero();
        }

        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external /* onlyRole */ {
        uint256 senderBalance = balanceOf(_msgSender());

        // Make sure burn token done by the sender and burn their own token
        if (_from != _msgSender()) {
            revert SilverERC20__UnauthorizedBurn();
        }
        if (_from == address(0)) {
            revert SilverERC20__AddressCantBeNull();
        }
        if (_amount > senderBalance) {
            revert SilverERC20__InsufficientBalance();
        }
        if (_amount <= 0) {
            revert SilverERC20__AmountMustBeGreaterThanZero();
        }
        _burn(_from, _amount);
    }
}
