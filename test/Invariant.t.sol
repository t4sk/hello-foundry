// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/InvariantTest.sol";
import {WETH9} from "../src/WETH9.sol";

// TODO: test english auction?
// TODO: conditional invariant
// TODO: invariant target
// TODO: [x] ghost variables
// TODO: - function level assertions
// TODO: - bound
// TODO: - actor management
// TODO: target selectors


contract WETH9_Open_Invariant_Tests is Test, InvariantTest {
    WETH9 public weth;

    function setUp() public {
        weth = new WETH9();
    }

    // NOTE: - calls = runs x depth
    // NOTE: - open testing - randomly call all public functions
    // NOTE: - handler based testing - test functiond under specific conditions

    function invariant_totalSupply_is_always_zero() public {
        assertEq(0, weth.totalSupply());
    }
}

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    WETH9 private weth;
    uint public wethBalance;

    constructor(WETH9 _weth) {
        weth = _weth;
    }

    receive() external payable {}

    function sendToFallback(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);
        wethBalance += amount;
        (bool ok,) = address(weth).call{ value: amount }("");
        require(ok, "sendToFallback failed");
    }

    function deposit(uint amount) public {
        // bound amount 
        bound(amount, 0, address(this).balance);
        wethBalance += amount;
        weth.deposit{value: amount}();
    }

    function withdraw(uint amount) public {
        bound(amount, 0, weth.balanceOf(address(this)));
        wethBalance -= amount;
        weth.withdraw(amount);
    }
}

contract WETH9_Handler_Based_Invariant_Tests is Test, InvariantTest {
    WETH9 public weth;
    Handler public handler;

    uint private constant ETH_SUPPLY = 10 ether;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        // Send 10 ETH to handler
        deal(address(handler), ETH_SUPPLY);
        // Set fuzzer to only call the handler
        targetContract(address(handler));
    }

    function invariant_eth_balance() public {
        assertGe(address(weth).balance, handler.wethBalance());
    }
}
