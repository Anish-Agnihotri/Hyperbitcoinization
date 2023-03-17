// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}