// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// TODO: fix
// RUST_LOG=error,debug forge test --match-path test/CrossChainFork.t.sol -vvvvv

contract PingPong {
    bool public called;

    function ping(uint256 val) external {
        called = true;
        console.log("Pong", block.chainid, msg.sender, val);
    }
}

interface IL1_CrossDomainMessenger {
    function sendMessage(
        address target,
        bytes calldata message,
        uint32 gasLimit
    ) external;
}

contract CrossChainTest is Test {
    // fork ids
    uint256 mainnet;
    uint256 opt;
    // NOTE: Arbitrum not working
    uint256 arb;

    address mainPingPong;
    address opPingPong;

    IL1_CrossDomainMessenger private L1_messenger =
        IL1_CrossDomainMessenger(0xd9166833FF12A5F900ccfBf2c8B62a90F1Ca1FD5);

    function setUp() public {
        string memory MAINNET_FORK_URL = vm.envString("MAINNET_FORK_URL");
        string memory OPT_FORK_URL = vm.envString("OPT_FORK_URL");

        mainnet = vm.createFork(MAINNET_FORK_URL);
        opt = vm.createFork(OPT_FORK_URL);

        mainPingPong = address(new PingPong());
        vm.makePersistent(mainPingPong);

        vm.selectFork(opt);
        opPingPong = address(new PingPong());
        vm.makePersistent(opPingPong);
    }

    function testForks() public {
        // select mainnet
        vm.selectFork(mainnet);
        assertEq(vm.activeFork(), mainnet);

        L1_messenger.sendMessage(
            opPingPong, abi.encodeCall(PingPong.ping, (123)), 1000000
        );

        // select optimism
        vm.selectFork(opt);
        assertEq(vm.activeFork(), opt);

        console.log("HERE", PingPong(opPingPong).called());

        // TODO: L1 -> L2
        // TODO: L2 -> L1

        // set block number
        // vm.selectFork(arb);
        // vm.rollFork(123_456_789);
        // assertEq(block.number, 123_456_789);
    }
}
