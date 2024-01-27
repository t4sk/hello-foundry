// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IERC20.sol";

// Forward contract
// Agreement between two parties which forces the first party to buy from
// the second at a pre-determined price and date

// Prepaid forward contract - strike price is paid at the initiation

enum Status {
    Open,
    Entered,
    Settled
}

contract PrepaidForward {
    // long position - buyer
    // short position - seller
    // strike price - pre-determined price
    // maturity date - pre-determined date to execute the agreement

    // K - strike price
    // T - maturity date
    // S(t) - underlying asset price at time t

    // Payoff
    // Long  = S(T) - K
    // Short = K - S(T)

    // Theorem
    // Assume
    // - no arbitrage opportunity
    // - underlying asset doesn't pay dividends
    // - 0 cost to store underlying asset
    // Then strike price for forward contract entered at t0
    //    K = S(t0) / Z(t0, T)
    // where Z(t, T) = price of zero-coupon bond at time t with maturity T
    //       Z(T, T) = 1
    // For prepaid forward contract
    //    K = S(t0) / Z(t0, T) * Z(t0, T) = S(t0)

    // For example, WETH
    IERC20 public immutable underlyingAsset;
    // For example, USDC
    IERC20 public immutable payToken;

    address public buyer;
    address public immutable seller;
    uint256 public immutable quantity;
    uint256 public immutable strike;
    uint256 public immutable maturity;
    Status public status;

    constructor(
        IERC20 _underlying,
        IERC20 _pay,
        address _seller,
        uint256 _quantity,
        uint256 _strike,
        uint256 _maturity
    ) {
        underlyingAsset = _underlying;
        payToken = _pay;

        require(block.timestamp < _maturity, "maturity must be > now");

        seller = _seller;
        quantity = _quantity;
        strike = _strike;
        maturity = _maturity;
    }

    // NOTE: enter should be called immediately after the contract is deployed
    function enter() external {
        require(block.timestamp < maturity, "expired");
        require(status == Status.Open, "not open");

        status = Status.Entered;
        buyer = msg.sender;

        underlyingAsset.transferFrom(seller, address(this), quantity);
        payToken.transferFrom(msg.sender, address(this), strike);
    }

    function settle() external {
        require(block.timestamp >= maturity, "not matured");
        require(status == Status.Entered, "not entered");

        status = Status.Settled;

        underlyingAsset.transfer(buyer, quantity);
        payToken.transfer(seller, strike);
    }
}
