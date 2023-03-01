// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

interface IWETH {
    function balanceOf(address) external view returns (uint);
    function deposit() external payable;
}

contract ForkTest is Test {
    // fork ids
    uint mainnet;
    uint opt;
    uint arb;

    function setUp() public {
        string memory MAINNET_FORK_URL = vm.envString("MAINNET_FORK_URL");
        string memory OPT_FORK_URL = vm.envString("OPT_FORK_URL");
        string memory ARB_FORK_URL = vm.envString("ARB_FORK_URL");

        mainnet = vm.createFork(MAINNET_FORK_URL);
        opt = vm.createFork(OPT_FORK_URL);
        arb = vm.createFork(ARB_FORK_URL);
    }

    function testForks() public {
        // select mainnet
        vm.selectFork(mainnet);
        assertEq(vm.activeFork(), mainnet);

        // select optimism
        vm.selectFork(opt);
        assertEq(vm.activeFork(), opt);

        // set block number
        vm.selectFork(arb);
        vm.rollFork(123_456_789);
        assertEq(block.number, 123_456_789);
    }
}
