// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/InvariantTest.sol";
import {WETH} from "../src/WETH.sol";

// https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw

// TODO: conditional invariant
// invariant target
// ghost variables
// TODO: - function level assertions
// TODO: - bound
// actor management
// TODO: target selectors

contract WETH_Open_Invariant_Tests is Test, InvariantTest {
    WETH public weth;

    function setUp() public {
        weth = new WETH();
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
    WETH private weth;
    uint256 public wethBalance;

    constructor(WETH _weth) {
        weth = _weth;
    }

    receive() external payable {}

    function sendToFallback(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);
        wethBalance += amount;
        (bool ok,) = address(weth).call{value: amount}("");
        require(ok, "sendToFallback failed");
    }

    function deposit(uint256 amount) public {
        // bound amount
        bound(amount, 0, address(this).balance);
        wethBalance += amount;
        weth.deposit{value: amount}();
    }

    function withdraw(uint256 amount) public {
        bound(amount, 0, weth.balanceOf(address(this)));
        wethBalance -= amount;
        weth.withdraw(amount);
    }
}

contract WETH_Handler_Based_Invariant_Tests is Test, InvariantTest {
    WETH public weth;
    Handler public handler;

    uint256 private constant ETH_SUPPLY = 10 ether;

    function setUp() public {
        weth = new WETH();
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

contract ActorManager is CommonBase, StdCheats, StdUtils {
    Handler[] public handlers;

    constructor(Handler[] memory _handlers) {
        handlers = _handlers;
    }

    function sendToFallback(uint256 handlerIndex, uint256 amount) public {
        handlers[bound(handlerIndex, 0, handlers.length - 1)].sendToFallback(
            amount
        );
    }

    function deposit(uint256 handlerIndex, uint256 amount) public {
        handlers[bound(handlerIndex, 0, handlers.length - 1)].deposit(amount);
    }

    function withdraw(uint256 handlerIndex, uint256 amount) public {
        handlers[bound(handlerIndex, 0, handlers.length - 1)].withdraw(amount);
    }
}

contract WETH_Multi_Handler_Invariant_Tests is Test, InvariantTest {
    WETH public weth;
    ActorManager public manager;
    Handler[] public handlers;

    uint256 private constant ETH_SUPPLY = 10 ether;

    function setUp() public {
        weth = new WETH();

        for (uint256 i = 0; i < 3; i++) {
            handlers.push(new Handler(weth));
            // Send 10 ETH to handler
            deal(address(handlers[i]), ETH_SUPPLY);
        }

        manager = new ActorManager(handlers);

        // TODO:
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = ActorManager.deposit.selector;
        selectors[1] = ActorManager.withdraw.selector;
        selectors[2] = ActorManager.sendToFallback.selector;

        targetSelector(
            FuzzSelector({addr: address(manager), selectors: selectors})
        );

        targetContract(address(manager));
    }

    function invariant_eth_balance() public {
        uint256 total = 0;
        for (uint256 i = 0; i < handlers.length; i++) {
            total += handlers[i].wethBalance();
        }
        console.log("ETH total", total);
        assertGe(address(weth).balance, total);
    }
}
