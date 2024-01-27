// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DaiProxy} from "../src/DaiProxy.sol";

// forge test --fork-url $FORK_URL --match-path test/Label.t.sol  -vvvv
contract LabelTest is Test {
    DaiProxy private proxy;

    function test() public {
        proxy = new DaiProxy();
        // Label address with "DssProxy", this will be displayed in stack traces
        vm.label(proxy.proxy(), "DssProxy");
        proxy.lockEth{value: 1e18}();
    }
}
