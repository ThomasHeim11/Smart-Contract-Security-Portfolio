// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title Minimal Interface for ERC20 Tokens
 * @author Inference Labs
 * @custom:security-contact whitehat@inferencelabs.com
 * @notice Minimal Interface for ERC20 Tokens
 */
interface IERC20Min {
    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
