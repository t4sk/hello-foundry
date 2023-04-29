// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IERC20Permit.sol";

contract GasslessTokenTransfer {
    // Protect from signature replay attack
    mapping(address => uint256) public nonces;

    function send(
        address token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 fee,
        uint256 deadline,
        // 2 signatures, first for send, second for permit
        uint8[2] calldata vs,
        bytes32[2] calldata rs,
        bytes32[2] calldata ss
    ) external {
        require(deadline > block.timestamp, "expired");

        // Check signature
        uint256 nonce = nonces[sender];
        bytes32 ethHash = getEthSignedMessageHash(getMessageHash(token, sender, receiver, amount, fee, deadline, nonce));
        require(isValidSignature(ethHash, sender, vs[0], rs[0], ss[0]), "invalid signature");

        // Update nonces[sender]
        nonces[sender] = nonce + 1;

        // Permit
        IERC20Permit(token).permit(sender, address(this), amount + fee, deadline, vs[1], rs[1], ss[1]);

        // Send amount to receiver
        IERC20Permit(token).transferFrom(sender, receiver, amount);

        // Take fee - send fee to msg.sender
        IERC20Permit(token).transferFrom(sender, msg.sender, fee);
    }

    function getMessageHash(
        address token,
        address sender,
        address receiver,
        uint256 amount,
        uint256 fee,
        uint256 deadline,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, sender, receiver, amount, fee, deadline, nonce));
    }

    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function isValidSignature(bytes32 ethHash, address signer, uint8 v, bytes32 r, bytes32 s)
        public
        pure
        returns (bool)
    {
        return ecrecover(ethHash, v, r, s) == signer;
    }
}
