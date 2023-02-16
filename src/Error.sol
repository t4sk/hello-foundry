// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Error {
    error NotAuthorized();

    function testRequire() external {
        require(false, "not authorized");
    }

    function testCustomError() external {
        revert NotAuthorized();
    }
}
