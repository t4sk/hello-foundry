// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {exp} from "../src/Exp.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// forge test --match-path test/DifferentialTest.t.sol --ffi -vvv

contract DifferentialTest is Test {
    using Strings for uint256;

    function setUp() public {}

    function ffi_exp(uint256 x) private returns (uint256) {
        string[] memory inputs = new string[](3);
        inputs[0] = "python";
        inputs[1] = "exp.py";
        inputs[2] = x.toString();

        bytes memory res = vm.ffi(inputs);
        // console.log(string(res));

        uint256 y = abi.decode(res, (uint256));
        console.log("y", y);

        return y;
    }

    function test() public {
        ffi_exp(0);
    }
}
