// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Error} from "../src/Error.sol";

contract ErrorTest is Test {
    Error public err;

    function setUp() public {
        err = new Error();
    }

    function testFail() public {
        err.testRequire();
    }

    function testRevert() public {
        vm.expectRevert();
        err.testRequire();
    }

    function testRequireMessage() public {
        vm.expectRevert(bytes("not authorized"));
        err.testRequire();
    }

    function testCustomError() public {
        vm.expectRevert(Error.NotAuthorized.selector);
        err.testCustomError();
    }
}
