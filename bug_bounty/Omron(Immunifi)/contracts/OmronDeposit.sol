// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOmronDeposit} from "./interfaces/IOmronDeposit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

using SafeERC20 for IERC20;

/**
 * @title OmronDeposit
 * @author Inference Labs
 * @custom:security-contact whitehat@inferencelabs.com
 * @notice A contract that allows users to deposit tokens and earn points based on the amount of time the tokens are held in the contract.
 * @dev Users can deposit any token that is accepted by the contract. The contract will track the amount of time the tokens are held in the contract and award points based on the amount of time the tokens are held.
 */
contract OmronDeposit is Ownable, ReentrancyGuard, Pausable, IOmronDeposit {
    // Mappings

    /**
     * @notice A mapping of whitelisted tokens to a boolean indicating if the token is whitelisted
     */
    mapping(address tokenAddress => bool isWhitelisted)
        public whitelistedTokens;

    /**
     * @notice A mapping of user addresses to information about the user including points and token balances
     */
    mapping(address userAddress => UserInfo userInformation) public userInfo;

    // Variables

    /**
     * @notice The number of decimal places for points
     */
    uint256 public constant POINTS_SCALE = 10 ** 18;

    /**
     * @notice One hour, in seconds, scaled to points decimals
     */
    uint256 public constant ONE_HOUR_IN_POINTS = 3600 * POINTS_SCALE;

    /**
     * @notice An array of addresses of all whitelisted tokens
     */
    address[] public allWhitelistedTokens;

    /**
     * @notice The address of the contract which is allowed to claim points on behalf of users.
     */
    address public claimManager;

    /**
     * @notice The time at which claims become enabled and points no longer accrue for any deposits.
     */
    uint256 public depositStopTime;

    /**
     * @dev The constructor for the OmronDeposit contract.
     * @param _initialOwner The address of the initial owner of the contract.
     * @param _whitelistedTokens An array of addresses of tokens that are accepted by the contract.
     */
    constructor(
        address _initialOwner,
        address[] memory _whitelistedTokens
    ) Ownable(_initialOwner) {
        for (uint256 i; i < _whitelistedTokens.length; ) {
            address token = _whitelistedTokens[i];
            if (token == address(0)) {
                revert ZeroAddress();
            }
            whitelistedTokens[token] = true;
            allWhitelistedTokens.push(token);

            emit WhitelistedTokenAdded(token);
            unchecked {
                ++i;
            }
        }
    }

    // Owner only methods

    /**
     * @dev Add a new deposit token to the contract
     * @param _tokenAddress The address of the token to be added
     */
    function addWhitelistedToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) {
            revert ZeroAddress();
        }
        whitelistedTokens[_tokenAddress] = true;
        allWhitelistedTokens.push(_tokenAddress);
        emit WhitelistedTokenAdded(_tokenAddress);
    }

    /**
     * @dev Remove a token from the whitelist
     * @param _tokenAddress The address of the token to be removed
     */
    function removeWhitelistedToken(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(0)) {
            revert ZeroAddress();
        }
        whitelistedTokens[_tokenAddress] = false;
        bool found = false;
        for (uint256 i; i < allWhitelistedTokens.length; ) {
            // Check if the current token address is the token to be removed
            if (allWhitelistedTokens[i] == _tokenAddress) {
                found = true;
                // If the token is not already at the end of the array, then copy the token address from the last position into the i position
                if (i != allWhitelistedTokens.length - 1) {
                    allWhitelistedTokens[i] = allWhitelistedTokens[
                        allWhitelistedTokens.length - 1
                    ];
                }
                // Remove the last element from the array. This will either:
                // - Remove a duplicated address if the last address was copied into the spot of the target token's address
                // - Remove the target address since it's the last element in the array (no swap occurred)
                allWhitelistedTokens.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert TokenNotWhitelisted();
        }
        emit WhitelistedTokenRemoved(_tokenAddress);
    }

    /**
     * @dev Set the address of the contract which is allowed to claim points on behalf of users. Can be set to the null address to disable claims.
     * @param _newClaimManager The address of the contract which is allowed to claim points on behalf of users.
     */
    function setClaimManager(address _newClaimManager) external onlyOwner {
        if (_newClaimManager == address(0)) {
            revert ZeroAddress();
        }
        // Set the new claim manager
        claimManager = _newClaimManager;

        emit ClaimManagerSet(_newClaimManager);
    }

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
    function stopDeposits() external onlyOwner {
        if (depositStopTime != 0) {
            revert DepositsAlreadyStopped();
        }
        depositStopTime = block.timestamp;
        emit DepositStopTimeSet(block.timestamp);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Modifiers

    /**
     * @dev A modifier that checks if the claim manager contract address is set and the sender is the claim manager contract
     */
    modifier onlyClaimManager() {
        if (claimManager == address(0)) {
            revert ClaimManagerNotSet();
        }
        if (msg.sender != claimManager) {
            revert NotClaimManager();
        }
        _;
    }

    /**
     * @dev A modifier that checks whether the deposit stop time hasn't been set.
     * If the deposit stop time has not been set, then the function will revert.
     */
    modifier onlyAfterDepositStop() {
        if (depositStopTime == 0) {
            revert DepositsNotStopped();
        }
        _;
    }

    /**
     * @dev A modifier that checkes whether the deposit stop time has been set.
     * If it has been set, then the function will revert.
     */
    modifier onlyBeforeDepositStop() {
        if (depositStopTime != 0) {
            revert DepositsStopped();
        }
        _;
    }

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
        )
    {
        UserInfo storage user = userInfo[_userAddress];
        pointsPerHour = user.pointsPerHour;
        lastUpdated = user.lastUpdated;
        pointBalance = user.pointBalance;
    }

    /**
     * @notice A view method that returns the list of all whitelisted tokens.
     * @return _allWhitelistedTokens An array of addresses of all whitelisted tokens.
     */
    function getAllWhitelistedTokens()
        external
        view
        returns (address[] memory _allWhitelistedTokens)
    {
        _allWhitelistedTokens = allWhitelistedTokens;
    }

    /**
     * @notice A view method that calculates the points earned by a user.
     * @param _userAddress The address of the user to calculate the points for.
     * @return currentPointsBalance The total points earned by the user, including points earned from time elapsed since the last update.
     */
    function calculatePoints(
        address _userAddress
    ) external view returns (uint256 currentPointsBalance) {
        UserInfo storage user = userInfo[_userAddress];
        currentPointsBalance = user.pointBalance + _calculatePointsDiff(user);
    }

    /**
     * @notice A view method that returns the token balance for a user.
     * @param _userAddress The address of the user to check the token balance for.
     * @param _tokenAddress The address of the token to check the balance for.
     * @return balance The token balance of the user for the specified token.
     */
    function tokenBalance(
        address _userAddress,
        address _tokenAddress
    ) external view returns (uint256 balance) {
        UserInfo storage user = userInfo[_userAddress];
        balance = user.tokenBalances[_tokenAddress];
    }

    // External methods

    /**
     * @dev Deposit a token into the contract
     * @param _tokenAddress The address of the token to be deposited
     * @param _amount The amount of the token to be deposited
     */
    function deposit(
        address _tokenAddress,
        uint256 _amount
    ) external nonReentrant whenNotPaused onlyBeforeDepositStop {
        if (_amount == 0) {
            revert ZeroAmount();
        }

        if (!whitelistedTokens[_tokenAddress]) {
            revert TokenNotWhitelisted();
        }

        IERC20 token = IERC20(_tokenAddress);

        UserInfo storage user = userInfo[msg.sender];

        _updatePoints(user);

        user.pointsPerHour += _amount;
        user.tokenBalances[_tokenAddress] += _amount;

        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _tokenAddress, _amount);
    }

    /**
     * @notice Withdraw tokens from the contract
     * @dev Called by the claim manager to withdraw tokens on a user's behalf
     * @param _userAddress The address of the user to withdraw the tokens from
     * @return withdrawnAmounts An array of the amounts of the tokens that were withdrawn
     */
    function withdrawTokens(
        address _userAddress
    )
        external
        nonReentrant
        whenNotPaused
        onlyClaimManager
        onlyAfterDepositStop
        returns (uint256[] memory withdrawnAmounts)
    {
        if (_userAddress == address(0)) {
            revert ZeroAddress();
        }

        UserInfo storage user = userInfo[_userAddress];
        _updatePoints(user);

        withdrawnAmounts = new uint256[](allWhitelistedTokens.length);

        for (uint256 i; i < allWhitelistedTokens.length; ) {
            uint256 userBalance = user.tokenBalances[allWhitelistedTokens[i]];

            if (userBalance == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            withdrawnAmounts[i] = userBalance;

            user.tokenBalances[allWhitelistedTokens[i]] = 0;

            IERC20 token = IERC20(allWhitelistedTokens[i]);
            token.safeTransfer(claimManager, userBalance);

            unchecked {
                ++i;
            }
        }
        user.pointsPerHour = 0;
        emit WithdrawTokens(_userAddress, withdrawnAmounts);
        return withdrawnAmounts;
    }

    /**
     * @dev Called by the claim manager to claim all points for the user
     * @param _userAddress The address of the user to claim for
     * @return pointsClaimed The number of points claimed by the user
     */
    function claim(
        address _userAddress
    )
        external
        nonReentrant
        whenNotPaused
        onlyClaimManager
        onlyAfterDepositStop
        returns (uint256 pointsClaimed)
    {
        if (_userAddress == address(0)) {
            revert ZeroAddress();
        }

        UserInfo storage user = userInfo[_userAddress];

        _updatePoints(user);

        // Return their current point balance, and set it to zero.
        pointsClaimed = user.pointBalance;

        user.pointBalance = 0;

        emit ClaimPoints(_userAddress, pointsClaimed);
    }

    // Private functions

    /**
     * @dev Update points information for a user
     * @param _user The user to update the points for
     */
    function _updatePoints(UserInfo storage _user) private {
        if (_user.lastUpdated != 0) {
            _user.pointBalance += _calculatePointsDiff(_user);
        }
        _user.lastUpdated = block.timestamp;
    }

    // Private View Methods

    /**
     * @notice Calculate the points earned by a user between their last updated timestamp and the current block timestamp, or the deposit stop time, whichever comes first.
     * @dev Will return zero if a user hasn't deposited, the user is not earning any points per hour, or the last updated timestamp is later than the deposit stop time as long as it's non-zero.
     * @param _user The user to calculate the points for
     * @return calculatedPoints The number of points earned by the user, since lastUpdated
     */
    function _calculatePointsDiff(
        UserInfo storage _user
    ) private view returns (uint256 calculatedPoints) {
        // If the user doesn't have this timestamp, then they haven't deposited any tokens, and thus their points are zero.
        // Otherwise, if their points per hour are zero, then there are no rewards between their last updated time and the deposit stop or the current time.
        // Finally, if the deposit stop time is non-zero and the last updated time is after the deposit stop time, then the user is not earning points.
        if (
            _user.lastUpdated == 0 ||
            _user.pointsPerHour == 0 ||
            (_user.lastUpdated >= depositStopTime && depositStopTime != 0)
        ) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp - _user.lastUpdated;
        // If the current time is after the depositStopTime and it is non-zero, then use it to determine time elapsed,
        // since no points are being accrued after deposit stop
        // timeElapsed will always be >= 0 due to checks above
        if (depositStopTime != 0) {
            timeElapsed = depositStopTime - _user.lastUpdated;
        }
        calculatedPoints =
            (timeElapsed * _user.pointsPerHour * POINTS_SCALE) /
            ONE_HOUR_IN_POINTS;
    }
}
