pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ConsoleTest is Test {
    function testLogSomething() public {
        console.log("Log something here", 123);
    }
}
