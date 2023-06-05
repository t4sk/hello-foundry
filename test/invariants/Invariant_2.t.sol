// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/InvariantTest.sol";
import {WETH} from "../../src/WETH.sol";

// Topics
// - handler
// - target contract
// - target selector
// NOTE: - handler based testing - test functiond under specific conditions

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    WETH private weth;
    uint256 public wethBalance;
    uint256 public numCalls;

    constructor(WETH _weth) {
        weth = _weth;
    }

    receive() external payable {}

    function sendToFallback(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);
        wethBalance += amount;
        numCalls += 1;

        (bool ok,) = address(weth).call{value: amount}("");
        require(ok, "sendToFallback failed");
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, 0, address(this).balance);
        wethBalance += amount;
        numCalls += 1;

        weth.deposit{value: amount}();
    }

    function withdraw(uint256 amount) public {
        amount = bound(amount, 0, weth.balanceOf(address(this)));
        wethBalance -= amount;
        numCalls += 1;

        weth.withdraw(amount);
    }

    function fail() external {
        revert("fail");
    }
}

contract WETH_Handler_Based_Invariant_Tests is Test, InvariantTest {
    WETH public weth;
    Handler public handler;

    function setUp() public {
        weth = new WETH();
        handler = new Handler(weth);

        // Send 100 ETH to handler
        deal(address(handler), 100 * 1e18);
        // Set fuzzer to only call the handler
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.sendToFallback.selector;

        // Handler.fail() not called
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
    }

    function invariant_eth_balance() public {
        assertGe(address(weth).balance, handler.wethBalance());
        console.log("handler num calls", handler.numCalls());
    }
}

// TODO: conditional invariant
// invariant target
// ghost variables
// TODO: - function level assertions
// TODO: - bound
// actor management
// TODO: target selectors

// contract ActorManager is CommonBase, StdCheats, StdUtils {
//     Handler[] public handlers;

//     constructor(Handler[] memory _handlers) {
//         handlers = _handlers;
//     }

//     function sendToFallback(uint256 handlerIndex, uint256 amount) public {
//         handlers[bound(handlerIndex, 0, handlers.length - 1)].sendToFallback(
//             amount
//         );
//     }

//     function deposit(uint256 handlerIndex, uint256 amount) public {
//         handlers[bound(handlerIndex, 0, handlers.length - 1)].deposit(amount);
//     }

//     function withdraw(uint256 handlerIndex, uint256 amount) public {
//         handlers[bound(handlerIndex, 0, handlers.length - 1)].withdraw(amount);
//     }
// }

// contract WETH_Multi_Handler_Invariant_Tests is Test, InvariantTest {
//     WETH public weth;
//     ActorManager public manager;
//     Handler[] public handlers;

//     uint256 private constant ETH_SUPPLY = 10 ether;

//     function setUp() public {
//         weth = new WETH();

//         for (uint256 i = 0; i < 3; i++) {
//             handlers.push(new Handler(weth));
//             // Send 10 ETH to handler
//             deal(address(handlers[i]), ETH_SUPPLY);
//         }

//         manager = new ActorManager(handlers);

//         // TODO:
//         bytes4[] memory selectors = new bytes4[](3);
//         selectors[0] = ActorManager.deposit.selector;
//         selectors[1] = ActorManager.withdraw.selector;
//         selectors[2] = ActorManager.sendToFallback.selector;

//         targetSelector(
//             FuzzSelector({addr: address(manager), selectors: selectors})
//         );

//         targetContract(address(manager));
//     }

//     function invariant_eth_balance() public {
//         uint256 total = 0;
//         for (uint256 i = 0; i < handlers.length; i++) {
//             total += handlers[i].wethBalance();
//         }
//         console.log("ETH total", total);
//         assertGe(address(weth).balance, total);
//     }
// }
