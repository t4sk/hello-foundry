// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// TODO: European and American

// Right to sell
contract Put {
    uint256 public strike;
    uint256 public expiresAt;

    // sell
    function short() external {}

    // buy
    function long() external {}

    function exercise() external {}
}

// Right to buy
contract Call {
    // sell
    function short() external {}

    // buy
    function long() external {}

    function exercise() external {}
}
