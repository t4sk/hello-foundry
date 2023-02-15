// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Auth} from "../src/Auth.sol";

//forge test --match-path test/Auth.t.sol -vvvv

contract AuthTest is Test {
    Auth public auth;

    function setUp() public {
        auth = new Auth();
    }

    function testSetOwner() public {
        auth.setOwner(address(1));
        assertEq(auth.owner(), address(1));
    }

    function testFailNotOwner() public {
        // next call will be called by address(1)
        vm.prank(address(1));
        auth.setOwner(address(1));
    }

    function testFailSetOwnerAgain() public {
        // msg.sender = address(this)
        auth.setOwner(address(1));

        // Set all subsequent msg.sender to address(1)
        vm.startPrank(address(1));

        // all calls made from address(1)
        auth.setOwner(address(1));
        auth.setOwner(address(1));
        auth.setOwner(address(1));

        // Reset all subsequent msg.sender to address(this)
        vm.stopPrank();

        // call made from address(this)
        auth.setOwner(address(1));
    }
}
