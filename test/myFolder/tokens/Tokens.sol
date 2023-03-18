// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 1_000_000e6);
    }
}

contract WBTC is ERC20 {
    constructor() ERC20("WBTC", "WBTC") {
        _mint(msg.sender, 1e8);
    }
}