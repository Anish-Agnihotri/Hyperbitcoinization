// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/// ============ Imports ============

import "../../src/interfaces/IERC20.sol"; // ERC20 minified
import "../../src/Hyperbitcoinization.sol"; // Hyperbitcoinization

/// @title HyperbitcoinizationUser
/// @author Anish Agnihotri
/// @notice Mock user to test interacting with Hyperbitcoinization
contract HyperbitcoinizationUser {
    /// ============ Immutable storage ============

    /// @notice USDC token
    IERC20 internal immutable USDC_TOKEN;
    /// @notice WBTC token
    IERC20 internal immutable WBTC_TOKEN;
    /// @notice Bet contract
    Hyperbitcoinization internal immutable BET_CONTRACT;

    /// ============ Constructor ============

    /// @notice Creates a new HyperbitcoinizationUser
    /// @param _USDC_TOKEN USDC token
    /// @param _WBTC_TOKEN wBTC token
    /// @param _BET_CONTRACT Hyperbitcoinization contract
    constructor(IERC20 _USDC_TOKEN, IERC20 _WBTC_TOKEN, Hyperbitcoinization _BET_CONTRACT) {
        USDC_TOKEN = _USDC_TOKEN;
        WBTC_TOKEN = _WBTC_TOKEN;
        BET_CONTRACT = _BET_CONTRACT;

        // Approve bet contract to spend funds
        USDC_TOKEN.approve(address(BET_CONTRACT), 2 ** 256 - 1);
        WBTC_TOKEN.approve(address(BET_CONTRACT), 2 ** 256 - 1);
    }

    /// ============ Helper functions ============

    /// @notice Check USDC balance
    function USDCBalance() public view returns (uint256) {
        return USDC_TOKEN.balanceOf(address(this));
    }

    /// @notice Check WBTC balance
    function WBTCBalance() public view returns (uint256) {
        return WBTC_TOKEN.balanceOf(address(this));
    }

    /// ============ Inherited Functionality ============

    /// @notice Add USDC to bet
    function addUSDC(uint256 betId) public {
        BET_CONTRACT.addUSDC(betId);
    }

    /// @notice Add wBTC to bet
    function addWBTC(uint256 betId) public {
        BET_CONTRACT.addWBTC(betId);
    }

    /// @notice Withdraw stale funds
    function withdrawStale(uint256 betId) public {
        BET_CONTRACT.withdrawStale(betId);
    }
}
