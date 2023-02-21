pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract SignTest is Test {
    function testSignature() public {
        uint256 privateKey = 123;
        // Computes the address for a given private key.
        address alice = vm.addr(privateKey);

        // Test valid signature
        bytes32 hash = keccak256("Signed by Alice");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        address signer = ecrecover(hash, v, r, s);

        assertEq(signer, alice);

        // Test invalid message
        bytes32 invalidHash = keccak256("Not signed by Alice");
        signer = ecrecover(invalidHash, v, r, s);

        assertTrue(signer != alice);
    }
}
