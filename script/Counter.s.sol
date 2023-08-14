// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

/*
source .env
forge script script/Counter.s.sol:CounterScript --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
*/

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("DEV_PRIVATE_KEY");

        vm.startBroadcast(privateKey);

        Counter counter = new Counter();

        counter.inc();
        counter.inc();
        counter.inc();

        vm.stopBroadcast();
    }
}
