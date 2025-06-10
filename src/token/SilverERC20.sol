// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SilverERC20 is ERC20, AccessControl{
    error SilverERC20__AddressCantBeNull();
    error SilverERC20__AmountMustBeGreaterThanZero();
    error SilverERC20__InsufficientBalance(uint256);
    error SilverERC20__UnauthorizedBurn(address, address);

    bytes32 public constant burnerRole = keccak256("BURNER_ROLE");

    constructor() ERC20("ETHSilver", "ESLV") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(burnerRole, msg.sender);
    }

    function mint(address _to, uint256 _amount) external returns (bool /* addRole */ ) {
        if (_to == address(0)) {
            revert SilverERC20__AddressCantBeNull();
        }
        if (_amount <= 0) {
            revert SilverERC20__AmountMustBeGreaterThanZero();
        }

        _mint(_to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external /* onlyRole(burnerRole) */ returns(bool) {
        uint256 senderBalance = balanceOf(_from);

        if (_from == address(0)) {
            revert SilverERC20__AddressCantBeNull();
        }
        if (_amount > senderBalance) {
            revert SilverERC20__InsufficientBalance(_amount);
        }
        if (_amount <= 0) {
            revert SilverERC20__AmountMustBeGreaterThanZero();
        }
        _burn(_from, _amount);
        return true;
    }
}
