// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library IdUtils {
    function _hashIdToUint(string memory _id) public pure returns (uint256) {
        return uint256(keccak256(bytes(_id)));
    }
}
