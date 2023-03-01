// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/InvariantTest.sol";
import {WETH9} from "../src/WETH9.sol";

contract WETH9InvariantTests is Test, InvariantTest {
    // TODO: test english auction?
    WETH9 public weth;

    function setUp() public {
        weth = new WETH9();
    }
    
    // TODO: conditional invariant
    // TODO: invariant target
    // TODO: - open testing
    // TODO: - handler based testing
    // TODO: - ghost variables
    // TODO: - function level assertions
    // TODO: - bound
    // TODO: - actor management

    function invariant_fail() public {
        assertEq(1, weth.totalSupply());
    }
}
