pragma solidity 0.8.26;

interface IVyperStorage {
    function store(uint256 val) external;
    function get() external returns (uint256);
}
