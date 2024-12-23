// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";

contract Counter {
    uint256 public constant count = 1;
    address public owner = msg.sender;
}

contract Deploy is Script {
    function run() public {
        console.log("msg.sender", msg.sender);
        console.log("address(this)", address(this));

        vm.startBroadcast();
        Counter counter = new Counter();
        console.log("counter.owner", counter.owner());
        vm.stopBroadcast();
    }
}
