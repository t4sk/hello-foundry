// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Bit} from "../src/Bit.sol";

// forge test --match-path test/Fuzz.t.sol

contract FuzzTest is Test {
    Bit public b;

    function setUp() public {
        b = new Bit();
    }

    function mostSignificantBit(uint x) private pure returns (uint) {
        uint i = 0;
        while ((x >>= 1) > 0) {
            ++i;
        }
        return i;
    }

    function testMostSignificantBit(uint x) public {
        // Exclude i = 0
        vm.assume(x > 0);

        uint i = b.mostSignificantBit(x);
        assertEq(i, mostSignificantBit(x));
    }
    // (runs: 256, μ: 18301, ~: 10819)
    // runs - number of tests
    // μ - mean gas used
    // ~ - median gas used
}
