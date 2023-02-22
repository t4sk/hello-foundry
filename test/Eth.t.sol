pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Wallet} from "../src/Wallet.sol";

contract EthTest is Test {
    Wallet public wallet;

    function setUp() public {
        wallet = new Wallet();
    }

    function testLogBalance() public {
        console.log("ETH balance", address(this).balance / 1e18);
    }

    function testSendEth() public {
        // hoax - Sets up a prank from an address that has some ether
        hoax(address(1), 123);
        assertEq(address(1).balance, 123);

        address(wallet).call{value: 123}("");

        assertEq(address(1).balance, 0);
        assertEq(address(wallet).balance, 123);

        // deal - Set balance
        deal(address(1), 1e18);
        assertEq(address(1).balance, 1e18);

        vm.prank(address(1));
        address(wallet).call{value: 456}("");

        assertEq(address(1).balance, 1e18 - 456);
        assertEq(address(wallet).balance, 123 + 456);
    }
}
