// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test,  console} from "forge-std/Test.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant AAVE_V3_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

contract LabelTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IPool private constant pool = IPool(AAVE_V3_POOL); 

    function setUp() public {
        //
    }

    function test() public {
        weth.deposit{value: 1e18}();
        weth.approve(address(pool), type(uint).max);

        console.log("HERE");

        pool.supply(WETH, 1e18, address(this), 0);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function balanceOf(address) external view returns (uint256);
    function deposit() external payable;
}

interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;
}
