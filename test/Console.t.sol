pragma solidity 0.8.20;

import "forge-std/Test.sol";

contract ConsoleTest is Test {
    function testLogSomething() public {
        console.log("Log something here", 123);

        int256 x = -1;
        console.logInt(x);
    }
}
