// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/// ============ Imports ============

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Chainlink pricefeed

/// @title PriceFeedMock
/// @author Anish Agnihotri
/// @notice Mocks Chainlink AggregatorV3Interface
/// @dev Specifically hard codes params for BTC/USD pricefeed
contract PriceFeedMock is AggregatorV3Interface {
    /// ============ Constants ============

    /// @notice Feed decimals
    uint8 public constant decimals = 8;
    /// @notice Feed description
    string public constant description = "BTCUSD mock pricefeed";
    /// @notice Feed version
    uint256 public constant version = 4;

    /// ============ Mutable storage ============

    /// @notice Oracle expected answer
    int256 internal price = 25_000e8; // $25,000

    /// ============ Functions ============

    /// @notice Chainlink pricefeed specific round data
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 0;
        answer = price;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;
    }

    /// @notice Chainlink pricefeed latest round data
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 0;
        answer = price;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;
    }

    /// ============ Oracle modifiers ============

    /// @notice Updates internal price for BTC/USD pricefeed
    function updatePrice(int256 newPrice) external {
        price = newPrice;
    }
}
