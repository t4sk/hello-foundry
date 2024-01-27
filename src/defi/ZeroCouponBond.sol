// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../ERC721.sol";
import "../Token.sol";

contract Coin is Token("coin", "coin", 6) {}

struct Bond {
    uint256 debt;
    uint256 maturity;
}

contract ZeroCouponBond is ERC721 {
    IERC20 public immutable coin;

    // TODO: test
    // TODO: redeem anytime
    // TODO: dynamic interest rate
    // TODO: where does the yield come from?
    uint256 constant BOND_DURATION = 365 days;
    uint256 constant INTEREST_RATE = 0.05 * 1e18;

    address public admin;

    uint256 private _id;
    mapping(uint256 => Bond) public bonds;

    constructor(IERC20 _coin) {
        coin = _coin;
        admin = msg.sender;
    }

    function buy(uint256 amount) external returns (uint256 id) {
        _id += 1;
        id = _id;

        /*
        p = M / (1 + r)^n

        p = current price of bond
        M = price of bond at maturity
        r = interest rate
        n = number of years to maturity
        --------------------
        bp = a

        b = amount of bonds to mint
        a = amount of coins sent

        b = a / p = a(1 + r)^n / M
        --------------------

        At maturity the bond is worth M so debt to buyer = bM
        */
        uint256 debt = amount * (1e18 + INTEREST_RATE) / 1e18;
        require(debt > 0, "debt = 0");

        bonds[id] =
            Bond({debt: debt, maturity: block.timestamp + BOND_DURATION});

        _mint(msg.sender, id);

        coin.transferFrom(msg.sender, address(this), amount);
    }

    function redeem(uint256 id) external {
        address owner = _ownerOf[id];
        require(msg.sender == owner, "not authorized");

        Bond memory bond = bonds[id];
        require(bond.maturity <= block.timestamp, "bond not matured");

        _burn(id);
        delete bonds[id];

        coin.transfer(msg.sender, bond.debt);
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == admin, "not authorized");
        coin.transfer(msg.sender, amount);
    }
}
