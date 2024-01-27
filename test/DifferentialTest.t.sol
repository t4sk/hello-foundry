pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {exp} from "../src/Exp.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// FOUNDRY_FUZZ_RUNS=100 forge test --match-path test/DifferentialTest.t.sol --ffi -vvv

contract DifferentialTest is Test {
    using Strings for uint256;

    function setUp() public {}

    function ffi_exp(int128 x) private returns (int128) {
        require(x >= 0, "x < 0");

        string[] memory inputs = new string[](3);
        inputs[0] = "python";
        inputs[1] = "exp.py";
        inputs[2] = uint256(int256(x)).toString();

        bytes memory res = vm.ffi(inputs);
        // console.log(string(res));

        int128 y = abi.decode(res, (int128));

        return y;
    }

    function test_exp(int128 x) public {
        // 2**64 = 1 (64.64 bit number)
        vm.assume(x >= 2 ** 64);
        vm.assume(x <= 20 * 2 ** 64);

        int128 y0 = ffi_exp(x);
        int128 y1 = exp(x);

        // Check |y0 - y1| <= 1
        uint256 DELTA = 2 ** 64;
        assertApproxEqAbs(uint256(int256(y0)), uint256(int256(y1)), DELTA);
    }
}
