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
    // function mint(address account, uint256 fyAmount) external returns (uint256);
    function getBond(uint256 id) external view returns (ZeroCouponBond memory);
}

enum BondState {
    NotCreated,
    Created,
    Sold
}

struct ZeroCouponBond {
    BondState state;
    address issuer;
    uint256 debt;
    uint256 loanDuration;
    uint256 collateralAmount;
    uint256 createdAt;
    // 1e18 = 100% / second
    uint256 discountRate;
    uint256 minBorrow;
    address buyer;
    uint256 soldAt;
}

contract FixedYieldBond is IFixedYieldBond, ERC721, Auth {
    IERC20 public immutable collateral;
    IERC20 public immutable coin;

    uint256 private nonce;
    mapping(uint256 => ZeroCouponBond) public bonds;

    function getBond(uint256 id) external view returns (ZeroCouponBond memory) {
        return bonds[id];
    }

    constructor(IERC20 _collateral, IERC20 _coin) {
        collateral = _collateral;
        coin = _coin;
    }

    struct MintParams {
        uint256 debt;
        uint256 loanDuration;
        uint256 collateralAmount;
        uint256 discountRate;
        uint256 minBorrow;
    }

    function mint(MintParams memory params) external returns (uint256) {
        require(params.loanDuration > 0, "invalid loan duration");
        require(params.discountRate <= 1e18, "discount rate > 1e18");
        require(params.debt >= params.minBorrow, "debt < min borrow");

        nonce += 1;
        uint256 id = nonce;
        // require(bonds[id].state == BondState.NotCreated, "created");

        // Start Dutch auction
        bonds[id] = ZeroCouponBond({
            state: BondState.Created,
            issuer: msg.sender,
            debt: params.debt,
            loanDuration: params.loanDuration,
            collateralAmount: params.collateralAmount,
            createdAt: block.timestamp,
            discountRate: params.discountRate,
            minBorrow: params.minBorrow,
            buyer: address(0),
            soldAt: 0
        });

        collateral.transferFrom(msg.sender, address(this), params.collateralAmount);

        return id;
    }

    // TODO: cancel

    function calcLoan(uint256 id) external view returns (uint256) {
        ZeroCouponBond memory bond = bonds[id];
        if (bond.state != BondState.Created) {
            return 0;
        }
        return _calcLoan(bond);
    }

    function _calcLoan(ZeroCouponBond memory bond) private view returns (uint256) {
        uint256 dt = block.timestamp - bond.createdAt;
        uint256 discount = bond.discountRate * dt;
        if (bond.debt >= discount) {
            return max(bond.debt - discount, bond.minBorrow);
        }
        return bond.minBorrow;
    }

    // TODO: sell;

    function buy(uint256 id) external {
        ZeroCouponBond storage bond = bonds[id];
        require(bond.state == BondState.Created, "not created");

        uint256 loan = _calcLoan(bond);
        require(loan > 0, "loan = 0");

        coin.transferFrom(msg.sender, bond.issuer, loan);

        bond.state = BondState.Sold;
        // TODO: transfer ownership of NFT?
        bond.buyer = msg.sender;
        bond.soldAt = block.timestamp;
    }

    function repay(uint256 id) external {
        ZeroCouponBond storage bond = bonds[id];
        require(bond.state == BondState.Sold, "not sold");
        require(msg.sender == bond.issuer, "not authorized");

        coin.transferFrom(msg.sender, bond.buyer, bond.debt);
        collateral.transfer(msg.sender, bond.collateralAmount);

        delete bonds[id];
    }

    // TODO: liquidate
    function liquidate(uint256 id) external {
        ZeroCouponBond storage bond = bonds[id];
        require(bond.state == BondState.Sold, "not sold");
        require(msg.sender == bond.buyer, "not authorized");

        // Dutch auction
        // buyer - debt -> loan -> min repay

        // Dutch auction failed -> collateral transferred to buyer
    }

    function burn() external {}

    function max(uint256 x, uint256 y) private pure returns (uint256) {
        return x >= y ? x : y;
    }
}

struct Auction {
    uint256 startingPrice;
    uint256 minPrice;
    uint256 createdAt;
}

contract CollateralAuctionHouse {
    IERC20 immutable collateral;
    IERC20 immutable coin;
    IFixedYieldBond immutable fyBond;

    constructor(IERC20 _collateral, IERC20 _coin, IFixedYieldBond _fyBond) {
        collateral = _collateral;
        coin = _coin;
        fyBond = _fyBond;
    }

    // function _calcLoan(ZeroCouponBond memory bond) private view returns (uint256) {
    //     uint256 dt = block.timestamp - bond.createdAt;
    //     uint256 discount = bond.discountRate * dt;
    //     if (bond.debt >= discount) {
    //         return max(bond.debt - discount, bond.minBorrow);
    //     }
    //     return bond.minBorrow;
    // }

    function start(uint256 nftId) external {
        // ZeroCouponBond memory bond = fyBond.getBond(nftId);
        fyBond.transferFrom(msg.sender, address(this), nftId);
    }

    function buy() external {}
}

// contract ZeroCouponBondMarket {
//     IERC20 public immutable coin;
//     IFixedYieldBond public immutable fyBond;

//     constructor(IERC20 _coin, IFixedYieldBond _fyBond) {
//         coin = _coin;
//         fyBond = _fyBond;
//     }

//     function sell(uint256 _nftId) external {
//         fyBond.transferFrom(msg.sender, address(this), _nftId);
//     }

//     // TODO: cancel

//     // TODO: Auction or AMM
//     function buy(uint256 _nftId) external {
//         uint256  = 0;
//         address nftOwner;
//         uint256 fyAmount;
//         coin.transferFrom(msg.sender, nftOwner, fyAmount);
//         // TODO: can be resold?
//         fyBond.transferFrom(address(this), msg.sender, _nftId);
//     }
// }

// contract CollateralLock {
//     IERC20 public immutable collateral;
//     IERC20 public immutable coin;
//     IFixedYieldBond public immutable fyBond;

//     mapping(address => uint256) public collateralBalances;

//     constructor(IERC20 _collateral, IERC20 _coin, IFixedYieldBond _fyBond) {
//         collateral = _collateral;
//         coin = _coin;
//         fyBond = _fyBond;
//     }

//     function lock(uint256 colAmount) external {
//         collateral.transferFrom(msg.sender, address(this), colAmount);
//         collateralBalances[msg.sender] += colAmount;
//     }

//     function borrow(uint256 fyAmount) external returns (uint256) {
//         uint256 nftId = fyBond.mint(msg.sender, fyAmount);
//         return nftId;
//     }

//     function repay(uint256 fyAmount) external {
//         // TODO: fees after expiry
//         coin.transferFrom(msg.sender, address(this), fyAmount);
//         // TODO: calculate how much collateral to release
//         uint256 colAmount;
//         collateral.transfer(msg.sender, colAmount);
//     }

//     function withdraw() external {}

//     // TODO: liquidation AMM or auction
//     function liquidate() external {}
// }

// contract PriceOracle {}
