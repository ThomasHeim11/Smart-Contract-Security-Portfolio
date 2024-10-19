// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tstETH is ERC20 {
    uint8 public _decimals;

    constructor(
        uint256 initialSupply,
        uint8 numberOfDecimals
    ) ERC20("Test ETH", "tstETH") {
        _mint(msg.sender, initialSupply);
        _decimals = numberOfDecimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
