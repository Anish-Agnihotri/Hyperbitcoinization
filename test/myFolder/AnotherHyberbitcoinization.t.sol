// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol"; // Foundry: Test
import "../../src/Hyperbitcoinization.sol";
import "./OracleNotNice.sol";
import {USDC, WBTC} from "./tokens/Tokens.sol";

contract HyperBitcoinizationTest is Test {
    // Whoever stakes USDC wants BTC to be > $1M.

    address BALAJI = vm.addr(1); // Owns USDC.
    address COUNTERPARTY = vm.addr(2); // Owns WBTC.

    Hyperbitcoinization HB;
    OracleNotNice ORC;

    USDC usdc;
    WBTC wbtc;

    uint256 bet = 0;

    function setUp() public {
        vm.prank(BALAJI);
        usdc = new USDC();

        vm.prank(COUNTERPARTY);
        wbtc = new WBTC();

        ORC = new OracleNotNice();

        HB = new Hyperbitcoinization(address(usdc), address(wbtc), address(ORC));

        vm.startPrank(BALAJI);
        usdc.approve(address(HB), usdc.balanceOf(BALAJI));
        vm.stopPrank();

        vm.startPrank(COUNTERPARTY);
        wbtc.approve(address(HB), wbtc.balanceOf(COUNTERPARTY));
        vm.stopPrank();
    }

    function testSetUp() public {
        assertEq(usdc.balanceOf(BALAJI), 1_000_000e6);
        assertEq(wbtc.balanceOf(COUNTERPARTY), 1e8);

        assertEq(usdc.allowance(BALAJI, address(HB)), 1_000_000e6);
        assertEq(wbtc.allowance(COUNTERPARTY, address(HB)), 1e8);
    }

    // If the Oracle is compromised to return fake, negative data,
    // the bet will fail and the USDC staker wins one WBTC.

    function testFakeOracle() public {
        uint256 betId = HB.createBet(BALAJI, COUNTERPARTY);

        vm.startPrank(BALAJI);
        HB.addUSDC(betId);
        vm.stopPrank();

        vm.startPrank(COUNTERPARTY);
        HB.addWBTC(betId);
        vm.stopPrank();

        assertEq(usdc.balanceOf(BALAJI), 0);
        assertEq(wbtc.balanceOf(COUNTERPARTY), 0);
        assertEq(usdc.balanceOf(address (HB)), 1_000_000e6);
        assertEq(wbtc.balanceOf(address(HB)), 1e8);

        skip(90 days);

        // Balaji has exploited the Oracle to return a negative value.
        vm.startPrank(BALAJI);
        HB.settleBet(betId);
        vm.stopPrank();

        // Balaji takes both USDC and WBTC, unfairly.

        assertEq(usdc.balanceOf(BALAJI), 1_000_000e6);
        assertEq(wbtc.balanceOf(BALAJI), 1e8);

        assertEq(usdc.balanceOf(COUNTERPARTY), 0);
        assertEq(wbtc.balanceOf(COUNTERPARTY), 0);

        assertEq(usdc.balanceOf(address (HB)), 0);
        assertEq(wbtc.balanceOf(address(HB)), 0);
    }
}