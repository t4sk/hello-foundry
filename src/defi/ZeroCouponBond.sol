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
    function getBond(uint256 id) external view returns (Bond memory);

    function burn(uint256 id) external;
}

enum BondState {
    NotCreated,
    Created,
    Sold
}

struct Bond {
    BondState state;
    address issuer;
    uint256 debt;
    uint256 minBorrow;
    uint256 duration;
    uint256 collateral;
}

contract FixedYieldBond is IFixedYieldBond, ERC721, Auth {
    IERC20 public immutable collateral;
    IERC20 public immutable coin;

    uint256 private nonce;
    mapping(uint256 => Bond) public bonds;

    function getBond(uint256 id) external view returns (Bond memory) {
        return bonds[id];
    }

    constructor(IERC20 _collateral, IERC20 _coin) {
        collateral = _collateral;
        coin = _coin;
    }

    struct MintParams {
        uint256 debt;
        uint256 duration;
        uint256 collateral;
        uint256 discountRate;
        uint256 minBorrow;
    }

    function mint(MintParams memory params) external returns (uint256) {
        require(params.duration > 0, "invalid loan duration");
        require(params.debt >= params.minBorrow, "debt < min borrow");

        nonce += 1;
        uint256 id = nonce;

        bonds[id] = Bond({
            state: BondState.Created,
            issuer: msg.sender,
            debt: params.debt,
            minBorrow: params.minBorrow,
            duration: params.duration,
            collateral: params.collateral
        });

        collateral.transferFrom(msg.sender, address(this), params.collateral);

        return id;
    }

    // TODO: cancel
    // require(msg.sender == owner, "not owner");

    function repay(uint256 id) external {
        // TODO: after loan duration?
        Bond storage bond = bonds[id];
        // TODO: require(bond.state == BondState.Sold, "not sold");
        require(msg.sender == bond.issuer, "not authorized");

        address owner = _ownerOf[id];
        coin.transferFrom(msg.sender, owner, bond.debt);
        collateral.transfer(msg.sender, bond.collateral);

        delete bonds[id];
    }

    function burn(uint256) external {}

    function max(uint256 x, uint256 y) private pure returns (uint256) {
        return x >= y ? x : y;
    }
}

enum BondAuctionState {
    NotOpen,
    Open
}

struct BondAuction {
    BondAuctionState state;
    uint256 fyBondId;
    address seller;
    uint256 startingPrice;
    uint256 minPrice;
    uint256 createdAt;
}

contract BondAuctionHouse {
    uint256 private constant DISCOUNT_DURATION = 3 days;

    IERC20 immutable collateral;
    IERC20 immutable coin;
    IFixedYieldBond immutable fyBond;

    uint256 private nonce;
    mapping(uint256 => BondAuction) public auctions;

    constructor(IERC20 _collateral, IERC20 _coin, IFixedYieldBond _fyBond) {
        collateral = _collateral;
        coin = _coin;
        fyBond = _fyBond;
    }

    function start(uint256 fyBondId, uint256 startingPrice, uint256 minPrice) external {
        // TODO: use create 2 + minimal proxy?
        require(startingPrice > minPrice);

        fyBond.transferFrom(msg.sender, address(this), fyBondId);

        nonce += 1;
        uint256 id = nonce;

        auctions[id] = BondAuction({
            state: BondAuctionState.Open,
            fyBondId: fyBondId,
            seller: msg.sender,
            startingPrice: startingPrice,
            minPrice: minPrice,
            createdAt: block.timestamp
        });
    }

    // TODO: function cancel

    function calcPrice(uint256 id) external view returns (uint256) {
        BondAuction memory auction = auctions[id];
        require(auction.state != BondAuctionState.Open, "auction not open");
        return _calcPrice(auction);
    }

    function _calcPrice(BondAuction memory auction) private view returns (uint256) {
        uint256 discountEndsAt = auction.createdAt + DISCOUNT_DURATION;

        if (discountEndsAt <= block.timestamp) {
            return auction.minPrice;
        }

        // dt < DISCOUNT_DURATION
        uint256 dt = block.timestamp - auction.createdAt;
        uint256 discount = (auction.startingPrice - auction.minPrice) * dt / DISCOUNT_DURATION;

        return auction.startingPrice - discount;
    }

    function buy(uint256 id) external {
        BondAuction memory auction = auctions[id];
        require(auction.state == BondAuctionState.Open, "auction not open");

        uint256 price = _calcPrice(auction);
        require(price >= auction.minPrice, "price < min price");

        coin.transferFrom(msg.sender, auction.seller, price);
        fyBond.transferFrom(address(this), msg.sender, auction.fyBondId);
        // TODO: update bond state and discount rate?

        delete auctions[id];
    }
}

enum AuctionState {
    NotOpen,
    Open
}

struct Auction {
    AuctionState state;
    uint256 fyBondId;
    address seller;
    uint256 startingPrice;
    uint256 minPrice;
    uint256 discountRate;
    uint256 expiresAt;
    uint256 createdAt;
}

// TODO: use minimal proxy for each auction?
contract CollateralAuctionHouse {
    IERC20 immutable collateral;
    IERC20 immutable coin;
    IFixedYieldBond immutable fyBond;

    uint256 private nonce;
    mapping(uint256 => Auction) public auctions;

    constructor(IERC20 _collateral, IERC20 _coin, IFixedYieldBond _fyBond) {
        collateral = _collateral;
        coin = _coin;
        fyBond = _fyBond;
    }

    function start(
        uint256 fyBondId,
        address seller,
        uint256 startingPrice,
        uint256 minPrice,
        uint256 discountRate,
        uint256 expiresAt
    ) external {
        // TODO: check bond state
        fyBond.transferFrom(msg.sender, address(this), fyBondId);

        nonce += 1;
        uint256 id = nonce;

        auctions[id] = Auction({
            state: AuctionState.Open,
            fyBondId: fyBondId,
            seller: seller,
            startingPrice: startingPrice,
            minPrice: minPrice,
            discountRate: discountRate,
            expiresAt: expiresAt,
            createdAt: block.timestamp
        });
    }

    function calcPrice(uint256 id) external view returns (uint256) {
        Auction memory auction = auctions[id];
        if (auction.state != AuctionState.Open) {
            // TODO: return type(uint).max?
            return 0;
        }

        return _calcPrice(auction);
    }

    function _calcPrice(Auction memory auction) private view returns (uint256) {
        uint256 dt = block.timestamp - auction.createdAt;
        uint256 discount = auction.discountRate * dt;
        if (auction.startingPrice >= discount) {
            return max(auction.startingPrice - discount, auction.minPrice);
        }
        return auction.minPrice;
    }

    function buy(uint256 id) external {
        Auction memory auction = auctions[id];
        require(auction.state == AuctionState.Open, "auction not open");
        require(block.timestamp < auction.expiresAt, "auction expired");

        uint256 price = _calcPrice(auction);
        require(price >= auction.minPrice, "price < min price");

        coin.transferFrom(msg.sender, auction.seller, price);
        // TODO: update bond?
        fyBond.transferFrom(address(this), msg.sender, auction.fyBondId);

        delete auctions[id];
    }

    function seize(uint256 id) external {
        Auction memory auction = auctions[id];
        require(auction.state == AuctionState.Open, "auction not open");
        require(block.timestamp >= auction.expiresAt, "auction not expired");

        delete auctions[id];

        // TODO: Transfer collateral?
        fyBond.burn(auction.fyBondId);
    }

    function max(uint256 x, uint256 y) private pure returns (uint256) {
        return x >= y ? x : y;
    }
}
