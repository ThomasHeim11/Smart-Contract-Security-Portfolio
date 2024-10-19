// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title IOmronDeposit
 * @author Inference Labs
 * @custom:security-contact whitehat@inferencelabs.com
 * @notice Contract interface for OmronDeposit
 * @dev This contract is the interface for the OmronDeposit contract.
 */
interface IOmronDeposit {
    // Structs

    /**
     * @notice A struct that holds information about a user's points and token balances
     */
    struct UserInfo {
        mapping(address tokenAddress => uint256 balanceAmount) tokenBalances;
        uint256 pointBalance;
        uint256 pointsPerHour;
        uint256 lastUpdated;
    }

    // Custom Errors
    error ZeroAddress();
    error TokenNotWhitelisted();
    error ZeroAmount();
    error NotClaimManager();
    error ClaimManagerNotSet();
    error DepositsAlreadyStopped();
    error DepositsNotStopped();
    error DepositsStopped();

    // Events

    /**
     * Emitted when a user deposits ERC20 tokens into the contract
     * @param from The address of the user that deposited the tokens
     * @param tokenAddress The address of the token that was deposited
     * @param amount The amount of the token that was deposited
     */
    event Deposit(
        address indexed from,
        address indexed tokenAddress,
        uint256 amount
    );

    /**
     * Emitted when a user claims their points via the claim contract
     * @param user The address of the user that claimed
     * @param pointsClaimed The number of points the user claimed
     */
    event ClaimPoints(address indexed user, uint256 pointsClaimed);

    /**
     * Emitted when a new token is added to the whitelist
     * @param _tokenAddress The address of the token that was added to the whitelist
     */
    event WhitelistedTokenAdded(address indexed _tokenAddress);

    /**
     * Emitted when a token is removed from the whitelist
     * @param _tokenAddress The address of the token that was removed from the whitelist
     */
    event WhitelistedTokenRemoved(address indexed _tokenAddress);

    /**
     * Emitted when the claim manager contract is set
     * @param _claimManager The address of the new claim manager contract
     */
    event ClaimManagerSet(address indexed _claimManager);

    /**
     * Emitted when the deposit stop time is set
     * @param _depositStopTime The timestamp of the new deposit stop time
     */
    event DepositStopTimeSet(uint256 indexed _depositStopTime);

    /**
     * Emitted when tokens are withdrawn from the contract
     * @param _userAddress The address of the user that withdrawn the tokens
     * @param _withdrawnAmounts An array of the amounts of the tokens that were withdrawn
     */
    event WithdrawTokens(
        address indexed _userAddress,
        uint256[] _withdrawnAmounts
    );

    // Owner only methods

    /**
     * @dev Add a new deposit token to the contract
     * @param _tokenAddress The address of the token to be added
     */
    function addWhitelistedToken(address _tokenAddress) external;

    /**
     * @dev Set the address of the contract which is allowed to claim points on behalf of users. Can be set to the null address to disable claims.
     * @param _newClaimManager The address of the contract which is allowed to claim points on behalf of users.
     */
    function setClaimManager(address _newClaimManager) external;

    /**
     * @notice Ends the deposit period
     * @dev This will:
     * 1. Set the deposit stop time to the current block time
     * 2. Emit the DepositStopTimeSet event
     * As a result:
     * Deposits will no longer be accepted
     * Claims will be enabled
     * Withdrawals will be enabled
     * Points accrual will no longer take place
     */
    function stopDeposits() external;

    /**
     * @dev Pause the contract
     */
    function pause() external;

    /**
     * @dev Unpause the contract
     */
    function unpause() external;

    // External view methods

    /**
     * @notice A view method that returns point information about the provided address
     * @param _userAddress The address of the user to check the point information for.
     * @return pointsPerHour The number of points earned per hour by the user.
     * @return lastUpdated The timestamp of the last time the user's points were updated.
     * @return pointBalance The total number of points earned by the user.
     */
    function getUserInfo(
        address _userAddress
    )
        external
        view
        returns (
            uint256 pointsPerHour,
            uint256 lastUpdated,
            uint256 pointBalance
        );

    /**
     * @notice A view method that returns the list of all whitelisted tokens.
     * @return _allWhitelistedTokens An array of addresses of all whitelisted tokens.
     */
    function getAllWhitelistedTokens()
        external
        view
        returns (address[] memory _allWhitelistedTokens);

    /**
     * @notice A view method that calculates the points earned by a user.
     * @param _userAddress The address of the user to calculate the points for.
     * @return currentPointsBalance The total points earned by the user, including points earned from time elapsed since the last update.
     */
    function calculatePoints(
        address _userAddress
    ) external view returns (uint256 currentPointsBalance);

    /**
     * @notice A view method that returns the token balance for a user.
     * @param _userAddress The address of the user to check the token balance for.
     * @param _tokenAddress The address of the token to check the balance for.
     * @return balance The token balance of the user for the specified token.
     */
    function tokenBalance(
        address _userAddress,
        address _tokenAddress
    ) external view returns (uint256 balance);

    // External methods

    /**
     * @dev Deposit a token into the contract
     * @param _tokenAddress The address of the token to be deposited
     * @param _amount The amount of the token to be deposited
     */
    function deposit(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice Withdraw tokens from the contract
     * @dev Called by the claim manager to withdraw tokens on a user's behalf
     * @param _userAddress The address of the user to withdraw the tokens from
     * @return withdrawnAmounts An array of the amounts of the tokens that were withdrawn
     */
    function withdrawTokens(
        address _userAddress
    ) external returns (uint256[] memory withdrawnAmounts);

    /**
     * @dev Called by the claim manager to claim all points for the user
     * @param _userAddress The address of the user to claim for
     * @return pointsClaimed The number of points claimed by the user
     */
    function claim(
        address _userAddress
    ) external returns (uint256 pointsClaimed);
}
