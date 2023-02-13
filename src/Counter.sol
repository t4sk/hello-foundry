// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Counter {
    uint256 public count;

    function inc() external {
        count += 1;
    }

    function dec() external {
        count -= 1;
    }
}
