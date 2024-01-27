// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Token} from "../../src/Token.sol";
import {PrepaidForward, Status} from "../../src/defi/PrepaidForward.sol";

contract PrepaidForwardTest is Test {
    Token private underlying;
    Token private payToken;
    PrepaidForward private prepaidForward;

    uint256 private constant QUANTITY = 10;
    uint256 private constant STRIKE = 2000;
    uint256 private immutable MATURITY = block.timestamp + 7 * 24 * 3600;

    address private immutable SELLER = address(1);
    address private constant BUYER = address(2);

    function setUp() public {
        underlying = new Token("underlying", "underlying", 18);
        payToken = new Token("pay", "pay", 18);
        prepaidForward = new PrepaidForward(
            underlying, payToken, SELLER, QUANTITY, STRIKE, MATURITY
        );

        underlying.mint(SELLER, QUANTITY);

        vm.prank(SELLER);
        underlying.approve(address(prepaidForward), QUANTITY);

        payToken.mint(BUYER, STRIKE);

        vm.prank(BUYER);
        payToken.approve(address(prepaidForward), STRIKE);
    }

    function testEnterExpired() public {
        vm.warp(MATURITY);
        vm.expectRevert("expired");
        prepaidForward.enter();
    }

    function testEnter() public {
        vm.prank(BUYER);
        prepaidForward.enter();

        assertTrue(prepaidForward.status() == Status.Entered, "status");
        assertEq(prepaidForward.buyer(), BUYER, "buyer");

        assertEq(underlying.balanceOf(address(prepaidForward)), QUANTITY);
        assertEq(payToken.balanceOf(address(prepaidForward)), STRIKE);
    }

    function testEnterNotOpen() public {
        vm.prank(BUYER);
        prepaidForward.enter();

        vm.expectRevert("not open");
        prepaidForward.enter();
    }

    function testSettleNotMatured() public {
        vm.prank(BUYER);
        prepaidForward.enter();

        vm.expectRevert("not matured");
        prepaidForward.settle();
    }

    function testSettleNotEntered() public {
        vm.warp(MATURITY);
        vm.expectRevert("not entered");
        prepaidForward.settle();
    }

    function testSettle() public {
        vm.prank(BUYER);
        prepaidForward.enter();

        vm.warp(MATURITY);
        prepaidForward.settle();

        assertTrue(prepaidForward.status() == Status.Settled, "status");

        assertEq(underlying.balanceOf(address(prepaidForward)), 0);
        assertEq(underlying.balanceOf(BUYER), QUANTITY);

        assertEq(payToken.balanceOf(address(prepaidForward)), 0);
        assertEq(payToken.balanceOf(SELLER), STRIKE);
    }
}
