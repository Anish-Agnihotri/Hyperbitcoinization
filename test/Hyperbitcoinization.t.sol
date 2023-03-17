// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/// ============ Imports ============

import "forge-std/Vm.sol"; // Foundry: VM
import "forge-std/Test.sol"; // Foundry: Test
import "../src/Hyperbitcoinization.sol"; // Hyperbitcoinization
import "./utils/HyperbitcoinizationUser.sol"; // Mock user

/// @title HyperbitcoinizationTest
/// @author Anish Agnihotri
/// @notice Hyperbitcoinization tests
contract HyperbitcoinizationTest is Test {
    /// @notice Cheatcodes
    Vm internal VM;
    /// @notice USDC token
    IERC20 internal USDC_TOKEN;
    /// @notice WBTC token
    IERC20 internal WBTC_TOKEN;
    /// @notice Bet contract
    Hyperbitcoinization internal BET_CONTRACT;

    /// ============ Users ============

    /// @notice User: Balaji
    HyperbitcoinizationUser internal USER_BALAJI;
    /// @notice User: Counterparty
    HyperbitcoinizationUser internal USER_COUNTERPARTY;

    /// ============ Setup ============

    function setUp() public {
        // Setup cheatcodes
        VM = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

        // Setup tokens
        USDC_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        WBTC_TOKEN = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

        // Setup bet contract
        BET_CONTRACT = new Hyperbitcoinization(
            address(USDC_TOKEN),
            address(WBTC_TOKEN),
            0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
        );

        // Setup users
        USER_BALAJI = new HyperbitcoinizationUser(USDC_TOKEN, WBTC_TOKEN, BET_CONTRACT);
        USER_COUNTERPARTY = new HyperbitcoinizationUser(USDC_TOKEN, WBTC_TOKEN, BET_CONTRACT);

        // Mock balances from whales
        /*VM.startPrank(0x28C6c06298d514Db089934071355E5743bf21d60); // Binance
        USDC_TOKEN.transferFrom(
            0x28C6c06298d514Db089934071355E5743bf21d60,
            address(USER_BALAJI),
            BET_CONTRACT.USDC_AMOUNT()
        );
        WBTC_TOKEN.transferFrom(
            0x28C6c06298d514Db089934071355E5743bf21d60,
            address(USER_COUNTERPARTY),
            BET_CONTRACT.WBTC_AMOUNT()
        );
        VM.stopPrank();*/
    }

    /// @notice Can create new bet
    function testNewBet() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));

        assertEq(betId, 1);
    }

    /// @notice Creating new bet increments betId
    function testNewBetIncrement() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        uint256 secondBetId = BET_CONTRACT.createBet(address(USER_COUNTERPARTY), address(USER_BALAJI));
        assertEq(betId, 1);
        assertEq(secondBetId, 2);
    }

    /// @notice Creating new bet has correct starting parameters
    function testNewBetParameters() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));

        (bool settled, bool USDCSent, bool WBTCSent, address partyUSDC, address partyWBTC, uint256 startTimestamp) =
            BET_CONTRACT.bets(betId);
        assertEq(settled, false);
        assertEq(USDCSent, false);
        assertEq(WBTCSent, false);
        assertEq(partyUSDC, address(USER_BALAJI));
        assertEq(partyWBTC, address(USER_COUNTERPARTY));
        assertEq(startTimestamp, 0);
    }
    /// @notice Can add USDC as partyUSDC
    /// @notice Cannot add USDC if not partyUSDC
    /// @notice Cannot add USDC twice as partyUSDC
    /// @notice Can add USDC as partyUSDC twice, after stale withdraw
    /// @notice Can start bet after adding USDC
    /// @notice Can add wBTC as partyWBTC
    /// @notice Cannot add wBTC if not partyWBTC
    /// @notice Cannot add wBTC twice as partyWBTC
    /// @notice Can add wbTC as partyWBTC twice, after stale withdraw
    /// @notice Can start bet after adding wBTC
    /// @notice Can withdraw stale USDC
    /// @notice Can withdraw stale wBTC
    /// @notice Cannot withdraw stale if bet started
    /// @notice Can settle unsettled bet
    /// @notice Cannot settle settled bet
    /// @notice Cannot settle unfinished bet
}
