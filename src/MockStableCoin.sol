// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStableCoin is ERC20 {
    /**
     * @notice This is a mock contract of the ERC20 standard for testing purposes only, it SHOULD NOT be used in production.
     @notice the decimals follow the ERC20 standard which is 10^18
     */
    constructor(uint256 initialSupply) ERC20("MockStableCoin", "MSC") {
        _mint(msg.sender, initialSupply);
    }
}
