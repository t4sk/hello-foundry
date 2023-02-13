// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    // invoked before each test
    function setUp() public {
        counter = new Counter();
    }

    // test must be external or public
    function testInc() public {
        counter.inc();
        assertEq(counter.count(), 1);
    }

    function testFailDec() public {
        counter.dec();
    }

    // Same as testFailDec
    function testDecUnderflow() public {
        vm.expectRevert(stdError.arithmeticError);
        counter.dec();
    }

    function testDec() public {
        counter.inc();
        counter.inc();
        counter.dec();
        assertEq(counter.count(), 1);
    }
}
