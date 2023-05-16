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
    event Authorize(address indexed account, bool authorized);

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "not authorized");
        _;
    }

    function _setAuthorized(address account, bool auth) internal {
        authorized[account] = auth;
        emit Authorize(account, auth);
    }

    function setAuthorized(address account, bool auth)
        external
        onlyAuthorized
    {
        _setAuthorized(account, auth);
    }
}

// NFT
interface IFixedYieldBond is IERC721 {
    // function mint(address account, uint256 fyAmount) external returns (uint256);
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
    uint256 duration;
    uint256 collateral;
}

contract BondStorage is Auth {
    // TODO: events

    uint256 private nonce;
    mapping(uint256 => Bond) private bonds;

    constructor() {
        _setAuthorized(msg.sender, true);
    }

    function get(uint256 id) external view returns (Bond memory) {
        return bonds[id];
    }

    function create(
        address issuer,
        uint256 debt,
        uint256 duration,
        uint256 collateral
    ) external onlyAuthorized returns (uint256) {
        // TODO: validate inputs

        nonce += 1;
        uint256 id = nonce;

        bonds[id] = Bond({
            state: BondState.Created,
            issuer: issuer,
            debt: debt,
            duration: duration,
            collateral: collateral
        });

        return id;
    }

    function _isValidStateTransition(BondState pre, BondState next)
        private
        pure
        returns (bool)
    {
        if (pre == BondState.Created) {
            return next == BondState.Sold;
        }
        return false;
    }

    function update(uint256 id, BondState state) external onlyAuthorized {
        Bond storage bond = bonds[id];
        require(
            _isValidStateTransition(bond.state, state),
            "invalid bond state transition"
        );
        bond.state = state;
    }

    function remove(uint256 id) external onlyAuthorized {
        Bond memory bond = bonds[id];
        require(bond.state == BondState.Created, "invalid bond state");
        delete bonds[id];
    }
}

interface IBondStorage {
    function get(uint256 id) external view returns (Bond memory);
    function create(
        address issuer,
        uint256 debt,
        uint256 duration,
        uint256 collateral
    ) external returns (uint256);
    function update(uint256 id, BondState state) external;
    function remove(uint256 id) external;
}

// TODO: leverage?
// TODO: any coin, multi-collateral

contract FixedYieldBond is IFixedYieldBond, ERC721, Auth {
    IERC20 public immutable collateral;
    IERC20 public immutable coin;
    IBondStorage public immutable bondStorage;

    constructor(IERC20 _collateral, IERC20 _coin, IBondStorage _bondStorage) {
        collateral = _collateral;
        coin = _coin;
        bondStorage = _bondStorage;
    }

    // TODO: perpetual?
    function mint(uint256 debt, uint256 duration, uint256 collateralAmount)
        external
        returns (uint256)
    {
        uint256 id = bondStorage.create({
            issuer: msg.sender,
            debt: debt,
            duration: duration,
            collateral: collateralAmount
        });

        _mint(msg.sender, id);

        collateral.transferFrom(msg.sender, address(this), collateralAmount);

        return id;
    }

    function burn(uint256 id) external {
        address owner = _ownerOf[id];
        require(msg.sender == owner, "not authorized");

        Bond memory bond = bondStorage.get(id);
        // TODO: require(msg.sender == bond.issuer, "not authorized");
        require(bond.state == BondState.Created, "invalid bond state");

        _burn(id);

        bondStorage.remove(id);
        collateral.transfer(msg.sender, bond.collateral);
    }

    // TODO: update debtor on transfer?

    function repay(uint256 id) external {
        // TODO: after loan duration?
        Bond memory bond = bondStorage.get(id);
        require(bond.state == BondState.Sold, "invalid bond state");
        // TODO: require(msg.sender == bond.issuer, "not authorized");

        bondStorage.remove(id);

        address owner = _ownerOf[id];
        coin.transferFrom(msg.sender, owner, bond.debt);
        collateral.transfer(msg.sender, bond.collateral);
    }
}

enum BondAuctionState {
    NotOpen,
    Open
}

struct BondAuction {
    BondAuctionState state;
    uint256 bondId;
    address seller;
    uint256 startingPrice;
    uint256 minPrice;
    uint256 createdAt;
}

contract BondAuctionHouse {
    // TODO:  events
    uint256 private constant DISCOUNT_DURATION = 3 days;

    IERC20 immutable collateral;
    IERC20 immutable coin;
    IBondStorage immutable bondStorage;
    IFixedYieldBond immutable fyBond;

    uint256 private nonce;
    mapping(uint256 => BondAuction) public auctions;

    constructor(
        IERC20 _collateral,
        IERC20 _coin,
        IBondStorage _bondStorage,
        IFixedYieldBond _fyBond
    ) {
        collateral = _collateral;
        coin = _coin;
        bondStorage = _bondStorage;
        fyBond = _fyBond;
    }

    function start(uint256 bondId, uint256 minPrice) external {
        // TODO: use create 2 + minimal proxy?

        Bond memory bond = bondStorage.get(bondId);
        require(bond.state == BondState.Created, "invalid bond state");
        // TODO: require(msg.sender == bond.issuer, "not authorized");
        require(minPrice <= bond.debt, "min price > starting price");

        // TODO: require msg.sender == bond.issuer == bond owner?
        fyBond.transferFrom(msg.sender, address(this), bondId);

        nonce += 1;
        uint256 id = nonce;

        auctions[id] = BondAuction({
            state: BondAuctionState.Open,
            bondId: bondId,
            seller: msg.sender,
            startingPrice: bond.debt,
            minPrice: minPrice,
            createdAt: block.timestamp
        });
    }

    function cancel(uint256 auctionId) external {
        BondAuction memory auction = auctions[auctionId];
        require(msg.sender == auction.seller, "not authorized");
        require(auction.state == BondAuctionState.Open, "invalid auction state");

        delete auctions[auctionId];

        fyBond.transferFrom(address(this), msg.sender, auction.bondId);
    }

    function calcPrice(uint256 id) external view returns (uint256) {
        BondAuction memory auction = auctions[id];
        require(auction.state != BondAuctionState.Open, "auction not open");
        return _calcPrice(auction);
    }

    function _calcPrice(BondAuction memory auction)
        private
        view
        returns (uint256)
    {
        uint256 discountEndsAt = auction.createdAt + DISCOUNT_DURATION;

        if (discountEndsAt <= block.timestamp) {
            return auction.minPrice;
        }

        // dt < DISCOUNT_DURATION
        uint256 dt = block.timestamp - auction.createdAt;
        uint256 discount =
            (auction.startingPrice - auction.minPrice) * dt / DISCOUNT_DURATION;

        return auction.startingPrice - discount;
    }

    function buy(uint256 id) external {
        BondAuction memory auction = auctions[id];
        require(auction.state == BondAuctionState.Open, "auction not open");

        uint256 price = _calcPrice(auction);
        require(price >= auction.minPrice, "price < min price");

        delete auctions[id];

        bondStorage.update(auction.bondId, BondState.Sold);

        // TODO: require auction.seller == bond.issuer?
        coin.transferFrom(msg.sender, auction.seller, price);
        fyBond.transferFrom(address(this), msg.sender, auction.bondId);
    }
}

// enum CollateralAuctionState {
//     NotOpen,
//     Open
// }

// struct CollateralAuction {
//     CollateralAuctionState state;
//     uint256 fyBondId;
//     address seller;
//     uint256 startingPrice;
//     uint256 minPrice;
//     uint256 discountRate;
//     uint256 expiresAt;
//     uint256 createdAt;
// }

// // TODO: use minimal proxy for each CollateralAuction?
// contract CollateralAuctionHouse {
//     IERC20 immutable collateral;
//     IERC20 immutable coin;
//     IFixedYieldBond immutable fyBond;

//     uint256 private nonce;
//     mapping(uint256 => CollateralAuction) public auctions;

//     constructor(IERC20 _collateral, IERC20 _coin, IFixedYieldBond _fyBond) {
//         collateral = _collateral;
//         coin = _coin;
//         fyBond = _fyBond;
//     }

//     function start(
//         uint256 fyBondId,
//         address seller,
//         uint256 startingPrice,
//         uint256 minPrice,
//         uint256 discountRate,
//         uint256 expiresAt
//     ) external {
//         // TODO: check bond state
//         fyBond.transferFrom(msg.sender, address(this), fyBondId);

//         nonce += 1;
//         uint256 id = nonce;

//         auctions[id] = CollateralAuction({
//             state: CollateralAuctionState.Open,
//             fyBondId: fyBondId,
//             seller: seller,
//             startingPrice: startingPrice,
//             minPrice: minPrice,
//             discountRate: discountRate,
//             expiresAt: expiresAt,
//             createdAt: block.timestamp
//         });

//         // TODO: update bond state?
//     }

//     function calcPrice(uint256 id) external view returns (uint256) {
//         CollateralAuction memory auction = auctions[id];
//         if (auction.state != CollateralAuctionState.Open) {
//             // TODO: return type(uint).max?
//             return 0;
//         }

//         return _calcPrice(auction);
//     }

//     function _calcPrice(CollateralAuction memory auction) private view returns (uint256) {
//         uint256 dt = block.timestamp - auction.createdAt;
//         uint256 discount = auction.discountRate * dt;
//         if (auction.startingPrice >= discount) {
//             return max(auction.startingPrice - discount, auction.minPrice);
//         }
//         return auction.minPrice;
//     }

//     function buy(uint256 id) external {
//         CollateralAuction memory auction = auctions[id];
//         require(auction.state == CollateralAuctionState.Open, "auction not open");
//         require(block.timestamp < auction.expiresAt, "auction expired");

//         uint256 price = _calcPrice(auction);
//         require(price >= auction.minPrice, "price < min price");

//         coin.transferFrom(msg.sender, auction.seller, price);
//         // TODO: update bond?
//         fyBond.transferFrom(address(this), msg.sender, auction.fyBondId);

//         delete auctions[id];
//         // TODO: update bond state?
//     }

//     function seize(uint256 id) external {
//         CollateralAuction memory auction = auctions[id];
//         require(auction.state == CollateralAuctionState.Open, "auction not open");
//         require(block.timestamp >= auction.expiresAt, "auction not expired");

//         delete auctions[id];

//         // TODO: Transfer collateral?
//         fyBond.burn(auction.fyBondId);
//         // TODO: update bond state?
//     }

//     function max(uint256 x, uint256 y) private pure returns (uint256) {
//         return x >= y ? x : y;
//     }
// }
