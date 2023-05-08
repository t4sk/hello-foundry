// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../ERC20.sol";
import "../ERC721.sol";
import "../Token.sol";

// Bond is bought at a discount
// Discount determines fixed interest

contract CollateralToken is Token("collateral", "col", 18) {}

contract Coin is Token("coin", "coin", 6) {}

contract Auth {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "not authorized");
        _;
    }

    function _setAuthorized(address account, bool auth) internal {
        authorized[account] = auth;
    }

    function setAuthorized(address account, bool auth) external onlyAuthorized {
        _setAuthorized(account, auth);
    }
}

// NFT
interface IFixedYieldBond is IERC721 {
    function mint(address account, uint256 fyAmount) external returns (uint256);
}

struct ZeroCouponBond {
    address issuer;
    uint256 debt;
    uint256 maturity;
}

contract FixedYieldBond is IFixedYieldBond, ERC721, Auth {
    constructor() {
        _setAuthorized(msg.sender, true);
    }

    function mint(address account, uint256 fyAmount) external onlyAuthorized returns (uint256) {
        // TODO: maturity
        // TODO: id
        uint256 id = 123;
        _mint(account, id);
        return id;
    }

    function burn() external {}
}

contract ZeroCouponBondMarket {
    IERC20 public immutable coin;
    IFixedYieldBond public immutable fyBond;

    constructor(IERC20 _coin, IFixedYieldBond _fyBond) {
        coin = _coin;
        fyBond = _fyBond;
    }

    function sell(uint256 _nftId) external {
        fyBond.transferFrom(msg.sender, address(this), _nftId);
    }

    // TODO: cancel

    // TODO: Auction or AMM
    function buy(uint256 _nftId) external {
        uint256 price = 0;
        address nftOwner;
        uint256 fyAmount;
        coin.transferFrom(msg.sender, nftOwner, fyAmount);
        // TODO: can be resold?
        fyBond.transferFrom(address(this), msg.sender, _nftId);
    }
}

contract CollateralLock {
    IERC20 public immutable collateral;
    IERC20 public immutable coin;
    IFixedYieldBond public immutable fyBond;

    mapping(address => uint256) public collateralBalances;

    constructor(IERC20 _collateral, IERC20 _coin, IFixedYieldBond _fyBond) {
        collateral = _collateral;
        coin = _coin;
        fyBond = _fyBond;
    }

    function lock(uint256 colAmount) external {
        collateral.transferFrom(msg.sender, address(this), colAmount);
        collateralBalances[msg.sender] += colAmount;
    }

    function borrow(uint256 fyAmount) external returns (uint256) {
        uint256 nftId = fyBond.mint(msg.sender, fyAmount);
        return nftId;
    }

    function repay(uint256 fyAmount) external {
        // TODO: fees after expiry
        coin.transferFrom(msg.sender, address(this), fyAmount);
        // TODO: calculate how much collateral to release
        uint256 colAmount;
        collateral.transfer(msg.sender, colAmount);
    }

    function withdraw() external {}

    // TODO: liquidation AMM or auction
    function liquidate() external {}
}

contract PriceOracle {}
