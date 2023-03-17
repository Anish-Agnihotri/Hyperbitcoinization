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
        VM.startPrank(0x28C6c06298d514Db089934071355E5743bf21d60); // Binance
        USDC_TOKEN.transfer(
            address(USER_BALAJI),
            BET_CONTRACT.USDC_AMOUNT() * 100
        );
        WBTC_TOKEN.transfer(
            address(USER_COUNTERPARTY),
            BET_CONTRACT.WBTC_AMOUNT() * 100
        );
        VM.stopPrank();
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
    function testAddUSDC() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        assertEq(USDC_TOKEN.balanceOf(address(BET_CONTRACT)), 0);
        USER_BALAJI.addUSDC(betId);
        assertEq(USDC_TOKEN.balanceOf(address(BET_CONTRACT)), BET_CONTRACT.USDC_AMOUNT());
    }

    /// @notice Cannot add USDC twice as partyUSDC
    function testCannotAddUSDCTwice() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        VM.expectRevert(bytes("USDC already added"));
        USER_BALAJI.addUSDC(betId);
    }

    /// @notice Cannot add USDC if not partyUSDC
    function testCannotAddUSDCWrongAddress() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        VM.expectRevert(bytes("User not part of bet"));
        USER_COUNTERPARTY.addUSDC(betId);
    }

    /// @notice Can add USDC as partyUSDC twice, after stale withdraw
    function testCanAddUSDCTwiceAfterStaleWithdraw() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        VM.expectRevert(bytes("USDC already added"));
        USER_BALAJI.addUSDC(betId);
        (,bool USDCSent,,,,) = BET_CONTRACT.bets(betId);
        assertEq(USDCSent, true);
        USER_BALAJI.withdrawStale(betId);
        (,USDCSent,,,,) = BET_CONTRACT.bets(betId);
        assertEq(USDCSent, false);
        USER_BALAJI.addUSDC(betId);
        assertEq(USDC_TOKEN.balanceOf(address(BET_CONTRACT)), BET_CONTRACT.USDC_AMOUNT());
    }

    /// @notice Can start bet after adding USDC
    function testCanStartBetAfterAddUSDC() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        (,bool USDCSent,,,,) = BET_CONTRACT.bets(betId);
        assertEq(USDCSent, true);
    }

    /// @notice Can add wBTC as partyWBTC
    function testAddWBTC() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        assertEq(WBTC_TOKEN.balanceOf(address(BET_CONTRACT)), 0);
        USER_COUNTERPARTY.addWBTC(betId);
        assertEq(WBTC_TOKEN.balanceOf(address(BET_CONTRACT)), BET_CONTRACT.WBTC_AMOUNT());
    }

    /// @notice Cannot add wBTC twice as partyWBTC
    function testCannotAddWBTCTwice() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_COUNTERPARTY.addWBTC(betId);
        VM.expectRevert(bytes("wBTC already added"));
        USER_COUNTERPARTY.addWBTC(betId);
    }

    /// @notice Cannot add wBTC if not partyWBTC
    function testCannotAddWBTCWrongAddress() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        VM.expectRevert(bytes("User not part of bet"));
        USER_BALAJI.addWBTC(betId);
    }

    /// @notice Can add wBTC as partyWBTC twice, after stale withdraw
    function testCanAddWBTCTwiceAfterStaleWithdraw() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_COUNTERPARTY.addWBTC(betId);
        VM.expectRevert(bytes("wBTC already added"));
        USER_COUNTERPARTY.addWBTC(betId);
        (,,bool WBTCSent,,,) = BET_CONTRACT.bets(betId);
        assertEq(WBTCSent, true);
        USER_COUNTERPARTY.withdrawStale(betId);
        (,,WBTCSent,,,) = BET_CONTRACT.bets(betId);
        assertEq(WBTCSent, false);
        USER_COUNTERPARTY.addWBTC(betId);
        assertEq(WBTC_TOKEN.balanceOf(address(BET_CONTRACT)), BET_CONTRACT.WBTC_AMOUNT());
    }

    /// @notice Can start bet after adding wBTC
    function testCanStartBetAfterAddWBTC() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_COUNTERPARTY.addWBTC(betId);
        (,,bool WBTCSent,,,) = BET_CONTRACT.bets(betId);
        assertEq(WBTCSent, true);
    }

    /// @notice Cannot withdraw stale if bet started
    function testCannotWithdrawStaleAfterBetStart() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        USER_COUNTERPARTY.addWBTC(betId);
        VM.expectRevert(bytes("Bet already started"));
        USER_BALAJI.withdrawStale(betId);
        VM.expectRevert(bytes("Bet already started"));
        USER_COUNTERPARTY.withdrawStale(betId);
    }

    /// @notice No one, but bet users, can withdraw stale unstarted bet
    function testCannotWithdrawStaleBetAsNonPartyUser() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        VM.expectRevert(bytes("Not bet participant"));
        BET_CONTRACT.withdrawStale(betId);
    }

    /// @notice Can settle unsettled bet
    function testCanSettleBet() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        USER_COUNTERPARTY.addWBTC(betId);
        uint256 counterpartyBalanceUSDC = USER_COUNTERPARTY.USDCBalance();
        uint256 counterpartyBalanceWBTC = USER_COUNTERPARTY.WBTCBalance();
        VM.warp(block.timestamp + 90 days);
        BET_CONTRACT.settleBet(betId);
        assertEq(USER_COUNTERPARTY.USDCBalance(), counterpartyBalanceUSDC + BET_CONTRACT.USDC_AMOUNT());
        assertEq(USER_COUNTERPARTY.WBTCBalance(), counterpartyBalanceWBTC + BET_CONTRACT.WBTC_AMOUNT());
    }

    /// @notice Cannot settle settled bet
    function testCannotSettleSettledBet() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        USER_COUNTERPARTY.addWBTC(betId);
        VM.warp(block.timestamp + 90 days);
        BET_CONTRACT.settleBet(betId);
        VM.expectRevert(bytes("Bet already settled"));
        BET_CONTRACT.settleBet(betId);
    }

    /// @notice Cannot settle unfinished bet
    function testCannotSettleUnfinishedBet() public {
        uint256 betId = BET_CONTRACT.createBet(address(USER_BALAJI), address(USER_COUNTERPARTY));
        USER_BALAJI.addUSDC(betId);
        USER_COUNTERPARTY.addWBTC(betId);
        VM.warp(block.timestamp + 89 days);
        VM.expectRevert(bytes("Bet still pending"));
        BET_CONTRACT.settleBet(betId);
    }
}
