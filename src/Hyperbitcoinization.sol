// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/// ============ Imports ============

import "./interfaces/IERC20.sol"; // ERC20 minified interface

/// @title Hyperbitcoinization
/// @author Anish Agnihotri
/// @notice Simple 1M USDC vs 1 wBTC 90-day bet cleared by Chainlink
contract Hyperbitcoinization {

    /// ============ Structs ============

    /// @notice Bet terms
    struct Bet {
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

    /// ============ Mutable storage ============

    /// @notice ID of current bet (next = curr + 1)
    uint256 currentBetId = 0;
    /// @notice Mapping of bet id => bet
    mapping(uint256 => Bet) bets;

    /// ============ Constructor ============

    /// @notice Creates a new Hyperbitcoinization contract
    /// @param _USDC_TOKEN address of USDC token
    /// @param _WBTC_TOKEN address of WBTC token
    constructor(address _USDC_TOKEN, address _WBTC_TOKEN) {
        USDC_TOKEN = IERC20(_USDC_TOKEN);
        WBTC_TOKEN = IERC20(_WBTC_TOKEN);
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
        bool success = USDC_TOKEN.transferFrom(
            msg.sender,
            address(this),
            1_000_000e6
        );
        require(success, "Failed collecting USDC");

        // Toggle partyASent
        bet.USDCSent = true;

        if (bet.USDCSent && bet.WBTCSent) {
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
        bool success = WBTC_TOKEN.transferFrom(
            msg.sender,
            address(this),
            1e8
        );
        require(success, "Failed collecting wBTC");

        // Toggle partyBSent
        bet.WBTCSent = true;

        if (bet.USDCSent && bet.WBTCSent) {
            bet.startTimestamp = block.timestamp;
        }
    }

    function withdrawStale(uint256 betId) external {}

    function determineWinner() external {}
}