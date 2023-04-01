// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {Wallet} from "../src/Wallet.sol";

// forge test --match-path test/Auth.t.sol -vvvv

contract AuthTest is Test {
    Wallet public wallet;

    function setUp() public {
        wallet = new Wallet();
    }

    function testSetOwner() public {
        wallet.setOwner(address(1));
        assertEq(wallet.owner(), address(1));
    }

    function testFailNotOwner() public {
        // next call will be called by address(1)
        vm.prank(address(1));
        wallet.setOwner(address(1));
    }

    function testFailSetOwnerAgain() public {
        // msg.sender = address(this)
        wallet.setOwner(address(1));

        // Set all subsequent msg.sender to address(1)
        vm.startPrank(address(1));

        // all calls made from address(1)
        wallet.setOwner(address(1));
        wallet.setOwner(address(1));
        wallet.setOwner(address(1));

        // Reset all subsequent msg.sender to address(this)
        vm.stopPrank();

        console.log("owner", wallet.owner());

        // call made from address(this) - this will fail
        wallet.setOwner(address(1));

        console.log("owner", wallet.owner());
    }
}
