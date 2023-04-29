// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../../src/ERC20Permit.sol";
import "../../src/app/GasslessTokenTransfer.sol";

contract GasslessTokenTransferTest is Test {
    ERC20Permit private token;
    GasslessTokenTransfer private gassless;

    uint256 constant SENDER_PRIVATE_KEY = 111;
    address sender;
    address receiver;
    uint256 constant AMOUNT = 1000;
    uint256 constant FEE = 10;

    function setUp() public {
        sender = vm.addr(SENDER_PRIVATE_KEY);
        receiver = address(2);

        token = new ERC20Permit("Test", "TEST", 18);
        token.mint(sender, AMOUNT + FEE);

        gassless = new GasslessTokenTransfer();
    }

    function _prepareSignatures(uint256 deadline)
        private
        view
        returns (uint8[2] memory vs, bytes32[2] memory rs, bytes32[2] memory ss)
    {
        // Sender - prepare permit signature
        bytes32 permitHash = _getPermitHash(sender, address(gassless), AMOUNT + FEE, deadline, token.nonces(sender));
        (vs[1], rs[1], ss[1]) = vm.sign(SENDER_PRIVATE_KEY, permitHash);

        // token.permit(sender, address(gassless), AMOUNT + FEE, deadline, vs[1], rs[1], ss[1]);

        // Sender - prepare gassless token transfer signature
        bytes32 transferHash = gassless.getEthSignedMessageHash(
            gassless.getMessageHash(address(token), sender, receiver, AMOUNT, FEE, deadline, gassless.nonces(sender))
        );
        (vs[0], rs[0], ss[0]) = vm.sign(SENDER_PRIVATE_KEY, transferHash);

        return (vs, rs, ss);
    }

    function testValidSig() public {
        uint256 deadline = block.timestamp + 60;
        (uint8[2] memory vs, bytes32[2] memory rs, bytes32[2] memory ss) = _prepareSignatures(deadline);

        // Execute transfer
        gassless.send(address(token), sender, receiver, AMOUNT, FEE, deadline, vs, rs, ss);

        // Check balances
        assertEq(token.balanceOf(sender), 0, "sender balance");
        assertEq(token.balanceOf(receiver), AMOUNT, "receiver balance");
        assertEq(token.balanceOf(address(this)), FEE, "fee");
    }

    function testInvalidSig() public {
        uint256 deadline = block.timestamp + 60;
        (uint8[2] memory vs, bytes32[2] memory rs, bytes32[2] memory ss) = _prepareSignatures(deadline);

        vm.expectRevert("invalid signature");
        gassless.send(address(token), sender, receiver, AMOUNT + 1, FEE, deadline, vs, rs, ss);
    }

    function _getPermitHash(address owner, address spender, uint256 value, uint256 deadline, uint256 nonce)
        private
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        owner,
                        spender,
                        value,
                        nonce,
                        deadline
                    )
                )
            )
        );
    }
}
