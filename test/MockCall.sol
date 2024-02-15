// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
address constant POOL_PROXY = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
address constant PRICE_ORACLE = 0x54586bE62E3c3580375aE3723C145253060Ca0C2;

// forge test --fork-url $MAINNET_FORK_URL --match-path test/MockCall.sol -vvv
contract AaveTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);

    IPool private constant pool = IPool(POOL_PROXY);
    // 1 = stable, 2 = variable
    uint256 private constant INTEREST_RATE_MODE = 2;

    address[] private users = [address(11), address(22)];

    function setUp() public {
        deal(users[0], 100 * 1e18);

        vm.startPrank(users[0]);
        weth.deposit{value: 1 * 1e18}();
        weth.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(users[1]);
        deal(DAI, users[1], 10000 * 1e18);
        dai.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.label(POOL_PROXY, "pool");
    }

    function get_hf() private view returns (uint256) {
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = pool.getUserAccountData(users[0]);
        return healthFactor;
    }

    function test() public {
        // users[0] supplies 1 WETH
        vm.prank(users[0]);
        pool.supply(WETH, 1 * 1e18, users[0], 0);

        // Set WETH price
        vm.mockCall(
            PRICE_ORACLE,
            abi.encodeCall(IAaveOracle.getAssetPrice, (WETH)),
            abi.encode(uint256(2000 * 1e8))
        );

        // users[0] borrows DAI
        vm.prank(users[0]);
        pool.borrow({
            asset: DAI,
            amount: 1500 * 1e18,
            interestRateMode: INTEREST_RATE_MODE,
            referralCode: 0,
            onBehalfOf: users[0]
        });

        // hf < 0.95 => col * 0.83 / debt < 0.95
        //              col * 0.83 / 0.95 < debt
        //              col * 0.873 < debt
        // Set WETH price to = debt / liquidation threshold * 0.95
        vm.mockCall(
            PRICE_ORACLE,
            abi.encodeCall(IAaveOracle.getAssetPrice, (WETH)),
            abi.encode(uint256(1700 * 1e8))
        );

        // users[0] hf < 0.95
        skip(1);
        assertLt(get_hf(), 0.95 * 1e18, "hf >= 0.95");

        // users[1] liquidates users[0], repay 999 DAI
        vm.prank(users[1]);
        pool.liquidationCall({
            collateralAsset: WETH,
            debtAsset: DAI,
            user: users[0],
            debtToCover: type(uint256).max,
            receiveAToken: false
        });
    }
}

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
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
        // 1 = stable, 2 = variable
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;
}

interface IDebtToken {
    function approveDelegation(address delegatee, uint256 amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}
