pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Wallet} from "../src/Wallet.sol";

contract WalletTest is Test {
    Wallet public wallet;

    function setUp() public {
        wallet = new Wallet{value: 1e18}();
    }

    // Receive ETH from wallet
    receive() external payable {}

    function testLogBalance() public {
        console.log("ETH balance", address(this).balance / 1e18);
    }

    function _send(uint256 amount) private {
        (bool ok,) = address(wallet).call{value: amount}("");
        require(ok, "send ETH failed");
    }

    // Examples of hoax and deal
    // hoax - Sets up a prank from an address that has some ether
    // deal - Set balance
    function testSendEth() public {
        uint256 bal = address(wallet).balance;
        assertEq(bal, 1e18);

        hoax(address(1), 123);
        assertEq(address(1).balance, 123);
        _send(123);

        bal += 123;
        assertEq(address(1).balance, 0);
        assertEq(address(wallet).balance, bal);

        deal(address(1), 1e18);
        assertEq(address(1).balance, 1e18);

        vm.prank(address(1));
        _send(456);

        bal += 456;
        assertEq(address(1).balance, 1e18 - 456);
        assertEq(address(wallet).balance, bal);
    }

    function testFailWithdrawNotOwner() public {
        vm.prank(address(1));
        wallet.withdraw(1);
    }

    // Test fail and check error message
    function testWithdrawNotOwner() public {
        vm.prank(address(1));
        vm.expectRevert(bytes("caller is not owner"));
        wallet.withdraw(1);
    }

    function testWithdraw() public {
        uint256 walletBalanceBefore = address(wallet).balance;
        uint256 ownerBalanceBefore = address(this).balance;

        wallet.withdraw(1);

        uint256 walletBalanceAfter = address(wallet).balance;
        uint256 ownerBalanceAfter = address(this).balance;

        assertEq(walletBalanceAfter, walletBalanceBefore - 1);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + 1);
    }
}
