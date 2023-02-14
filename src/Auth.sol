pragma solidity 0.8.18;

contract Auth {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not authorized");
        owner = _owner;
    }
}
