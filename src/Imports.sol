pragma solidity 0.8.26;

// Test import solmate
import "solmate/tokens/ERC20.sol";

contract Token is ERC20("name", "symbol", 16) {}

// Test import openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestOZ is Ownable {}
