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
    uint256 duration;
    uint256 collateral;
    uint256 minBorrow;
    uint256 nonce;
    uint256 createdAt;
    address buyer;
    uint256 soldAt;
}

contract FixedYieldBond is IFixedYieldBond, ERC721, Auth {
    IERC20 public immutable collateral;
    IERC20 public immutable coin;

    mapping(uint256 => ZeroCouponBond) public bonds;

    constructor(IERC20 _collateral, IERC20 _coin) {
        collateral = _collateral;
        coin = _coin;
    }

    function mint(uint256 debt, uint256 duration, uint256 coll, uint256 minBorrow, uint256 nonce)
        external
        returns (uint256)
    {
        require(duration > 0, "invalid duration");

        uint256 id = uint256(keccak256(abi.encode(msg.sender, debt, duration, coll, minBorrow, nonce)));
        require(bonds[id].state == BondState.NotCreated, "created");

        // Start Dutch auction
        bonds[id] = ZeroCouponBond({
            state: BondState.Created,
            issuer: msg.sender,
            debt: debt,
            duration: duration,
            collateral: coll,
            minBorrow: minBorrow,
            nonce: nonce,
            createdAt: block.timestamp,
            buyer: address(0),
            soldAt: 0
        });

        collateral.transferFrom(msg.sender, address(this), coll);

        return id;
    }

    function calcBorrowAmount(uint256 id) public view returns (uint256) {}

    function _calcBorrowAmount(ZeroCouponBond memory bond) private view returns (uint256) {}

    function buy(uint256 id, uint256 maxLoanAmount) external {
        ZeroCouponBond storage bond = bonds[id];
        require(bond.state == BondState.Created, "not created");

        uint256 borrowAmount = _calcBorrowAmount(bond);
        require(bond.minBorrow >= borrowAmount, "min borrow < borrow amount");
        require(borrowAmount <= maxLoanAmount, "borrow amount > max loan");

        coin.transferFrom(msg.sender, bond.issuer, borrowAmount);

        bond.state = BondState.Sold;
        bond.buyer = msg.sender;
        bond.soldAt = block.timestamp;
    }

    function burn() external {}
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
