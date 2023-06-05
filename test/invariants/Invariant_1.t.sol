// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/InvariantTest.sol";
import {WETH} from "../../src/WETH.sol";

// Topics
// - invariant
// - difference between fuzz and invariant
// - runs, calls, reverts

// NOTE: open testing - randomly call all public functions
contract WETH_Open_Invariant_Tests is Test, InvariantTest {
    WETH public weth;

    function setUp() public {
        weth = new WETH();
    }

    receive() external payable {}

    // NOTE: - calls = runs x depth, (runs, calls, reverts)

    function invariant_totalSupply_is_always_zero() public {
        assertEq(0, weth.totalSupply());
    }
}
