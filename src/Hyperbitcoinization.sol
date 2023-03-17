// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/// ============ Imports ============

import "./interfaces/IERC20.sol"; // ERC20 minified interface
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Chainlink pricefeed

/// @title Hyperbitcoinization
/// @author Anish Agnihotri
/// @notice Simple 1M USDC vs 1 wBTC 90-day bet cleared by Chainlink
contract Hyperbitcoinization {

    /// ============ Structs ============

    /// @notice Bet terms
    struct Bet {
        /// @notice Completed bet
        bool completed;
        /// @notice USDC-providing party
        address partyUSDC;
        /// @notice wBTC-providing party
        address partyWBTC;
        /// @notice USDC-providing party sent funds
        bool USDCSent;
        /// @notice wBTC-providing party sent funds
        bool WBTCSent;
        /// @notice Bet starting timestamp
        uint256 startTimestamp;
    }

    /// ============ Immutable storage ============

    /// @notice USDC token
    IERC20 public immutable USDC_TOKEN;
    /// @notice WBTC token
    IERC20 public immutable WBTC_TOKEN;
    /// @notice BTC/USD price feed (Chainlink)
    AggregatorV3Interface public immutable BTCUSD_PRICEFEED;

    /// ============ Mutable storage ============

    /// @notice ID of current bet (next = curr + 1)
    uint256 currentBetId = 0;
    /// @notice Mapping of bet id => bet
    mapping(uint256 => Bet) bets;

    /// ============ Constructor ============

    /// @notice Creates a new Hyperbitcoinization contract
    /// @param _USDC_TOKEN address of USDC token
    /// @param _WBTC_TOKEN address of WBTC token
    /// @param _WBTC_PRICEFEED address of pricefeed for BTC/USD
    constructor(address _USDC_TOKEN, address _WBTC_TOKEN, address _BTCUSD_PRICEFEED) {
        USDC_TOKEN = IERC20(_USDC_TOKEN);
        WBTC_TOKEN = IERC20(_WBTC_TOKEN);
        BTCUSD_PRICEFEED = AggregatorV3Interface(_BTCUSD_PRICEFEED);
    }

    /// ============ Functions ============

    /// @notice Creates a new bet between two parties
    /// @param partyUSDC providing USDC
    /// @param partyWBTC providing wBTC
    function createBet(address partyUSDC, address partyWBTC) external returns (uint256) {
        currentBetId++;
        bets[currentBetId] = Bet({
            partyUSDC: partyUSDC,
            partyWBTC: partyWBTC,
            USDCSent: false,
            WBTCSent: false,
            startTimestamp: block.timestamp
        });
        return currentBetId;
    }

    /// @notice Allows partyUSDC to add USDC to a bet.
    /// @dev Requires user to approve contract.
    /// @param betId to add funds to
    function addUSDC(uint256 betId) external {
        Bet memory bet = bets[betId];
        require(!bet.USDCSent, "Bet already entered by party");
        require(msg.sender == bet.partyUSDC, "Not USDC sending party");

        // Transfer USDC
        USDC_TOKEN.transferFrom(
            msg.sender,
            address(this),
            1_000_000e6
        );

        // Toggle partyASent
        bet.USDCSent = true;

        if (bet.WBTCSent) {
            bet.startTimestamp = block.timestamp;
        }
    }

    /// @notice Allows partyWBTC to add wBTC to a bet.
    /// @dev Requires user to approve contract.
    /// @param betId to add funds to
    function addWBTC(uint256 betId) external {
        Bet memory bet = bets[betId];
        require(!bet.WBTCSent, "Bet already entered by party");
        require(msg.sender == bet.partyWBTC, "Not wBTC sending party");

        // Transfer WBTC
        WBTC_TOKEN.transferFrom(
            msg.sender,
            address(this),
            1e8
        );

        // Toggle partyBSent
        bet.WBTCSent = true;

        if (bet.USDCSent) {
            bet.startTimestamp = block.timestamp;
        }
    }

    function settleBet(uint256 betId) external {
        Bet memory bet = bets[betId];
        require(!bet.completed, "Prevent settling completed bet");
        require(bet.startTimestamp + 7776000 >= block.timestamp, "Bet still pending");

        // Mark bet completed
        bet.completed = true;

        // Collect BTC price
        (,int price,,) = BTCUSD_PRICEFEED.latestRoundData();
        uint256 wBTCPrice = uint256(price) / 10 ** BTCUSD_PRICEFEED.decimals();

        address winner;
        if (wBTCPrice > 1e6) {
            winner = bet.partyWBTC;
        } else {
            winner = bet.partyUSDC;
        }

        USDC.transferFrom(address(this), winner, 1_000_000e6);
        WBTC.transferFrom(address(this), winner, 1e8);
    }

    function withdrawStale(uint256 betId) external {

    }
}