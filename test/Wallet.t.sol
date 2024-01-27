pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Wallet} from "../src/Wallet.sol";

// Examples of deal and hoax
// deal(address, uint) - Set balance of address
// hoax(address, uint) - deal + prank, Sets up a prank and set balance

contract WalletTest is Test {
    Wallet public wallet;

    function setUp() public {
        wallet = new Wallet{value: 1e18}();
    }

    // Receive ETH from wallet
    receive() external payable {}

    // Check how much ETH available for test
    function testLogBalance() public {
        console.log("ETH balance", address(this).balance / 1e18);
    }

    function _send(uint256 amount) private {
        (bool ok,) = address(wallet).call{value: amount}("");
        require(ok, "send ETH failed");
    }

    function testSendEth() public {
        uint256 bal = address(wallet).balance;

        // deal
        deal(address(1), 100);
        assertEq(address(1).balance, 100);

        deal(address(1), 10);
        assertEq(address(1).balance, 10);

        // hoax = deal + prank
        deal(address(1), 123);
        vm.prank(address(1));
        _send(123);

        hoax(address(1), 456);
        _send(456);

        assertEq(address(wallet).balance, bal + 123 + 456);
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
