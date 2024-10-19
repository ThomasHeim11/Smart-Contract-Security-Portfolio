// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OmronDeposit} from "../OmronDeposit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 10000 * 10 ** 18);
    }
}

contract OmronDepositTest is OmronDeposit {
    MockToken public token;
    bool private initialized = false;

    constructor() OmronDeposit(msg.sender, new address[](0)) {}

    function echidna_points_decimals_18() public returns (bool) {
        return (POINTS_SCALE == 10 ** 18);
    }

    function echidna_test_whitelisted_tokens() public returns (bool) {
        address[] memory _tokens = allWhitelistedTokens;
        for (uint i = 0; i < _tokens.length; i++) {
            if (!whitelistedTokens[_tokens[i]]) {
                return false;
            }
        }
        return true;
    }

    function echidna_test_user_info() public returns (bool) {
        address userAddress = address(this);
        (uint256 pointsPerHour, , uint256 pointBalance) = this.getUserInfo(
            userAddress
        );
        return pointsPerHour == 0 && pointBalance == 0;
    }
}
