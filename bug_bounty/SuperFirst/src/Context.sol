pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(address target, bool success, bytes memory returndata)
        internal
        view
        returns (bytes memory)
    {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IBankroll {
    function sendFTN(address _to, uint256 _amount) external;

    function sendERC20(IERC20 _token, address _to, uint256 _amount) external;

    function sendERC721(IERC721 _token, address _to, uint256 _id) external;
}

// SPDX-License-Identifier: MIT
/**
 * @title SuperFirst
 * @dev A simple betting contract where players can bet on boxes, and if their bet matches the randomly selected box, they win a prize.
 */
contract SuperFirst is Ownable, ReentrancyGuard {
    using Address for address payable;

    IBankroll public bankrollContract;
    uint256 private salt;
    uint256 public minBet;
    uint256 public maxBet;
    uint256 public winCoefficient;
    uint256 public numberOfBoxes;
    uint256 public constant COEFFICIENT_DENOMINATOR = 100;

    struct Bet {
        uint256 blockNumber;
        uint256 amount;
        uint256 boxNumber;
        uint256 salt;
        address player;
    }

    mapping(address => Bet[]) public bets;

    event RewardDistributed(uint256 amount);
    /**
     * @dev Emitted when a player places a bet.
     * @param player The address of the player placing the bet.
     * @param blockNumber The block number at which the bet is placed.
     * @param amount The amount of FTNs sent with the bet.
     * @param boxNumber The player's selected box number.
     */
    event BetPlaced(address indexed player, uint256 blockNumber, uint256 amount, uint256 boxNumber, uint256 salt);

    /**
     * @dev Emitted when a player claims their prize.
     * @param player The address of the player claiming the prize.
     * @param winAmount The amount of FTN won by the player.
     */
    event PrizeClaimed(address indexed player, uint256 winAmount);

    modifier notZero(uint256 number) {
        require(number > 0, "Number must be greater than zero");
        _;
    }

    constructor(IBankroll _bankrollContract) Ownable(msg.sender) {
        minBet = 1 * 10 ** 18;
        maxBet = 10 * 10 ** 18;
        numberOfBoxes = 5;
        winCoefficient = numberOfBoxes * COEFFICIENT_DENOMINATOR;
        bankrollContract = _bankrollContract;
    }

    receive() external payable {}

    /**
     * @dev Withdraws the FTN balance from the contract.
     * @param _amount The amount of FTN to withdraw.
     */
    function withdrawFTN(uint256 _amount) external onlyOwner {
        payable(msg.sender).sendValue(_amount);
    }

    /**
     * @dev Sets the address of the Bankroll contract.
     * @param _bankrollContract The address of the Bankroll contract to be set.
     * @notice Only the owner of this contract can set the Bankroll contract address.
     * @dev Reverts if the provided Bankroll contract address is zero.
     */
    function setBankrollContract(IBankroll _bankrollContract) external onlyOwner {
        require(address(_bankrollContract) != address(0), "Invalid bankroll contract address");
        bankrollContract = _bankrollContract;
    }

    /**
     * @dev Sets the minimum bet amount.
     * @param _minBet The new minimum bet amount.
     */
    function setMinBet(uint256 _minBet) external onlyOwner notZero(_minBet) {
        minBet = _minBet;
    }

    /**
     * @dev Sets the maximum bet amount.
     * @param _maxBet The new maximum bet amount.
     */
    function setMaxBet(uint256 _maxBet) external onlyOwner notZero(_maxBet) {
        maxBet = _maxBet;
    }

    /**
     * @dev Sets the win coefficient.
     * @param _winCoefficient The new win coefficient.
     */
    function setWinCoefficient(uint256 _winCoefficient) external onlyOwner notZero(_winCoefficient) {
        winCoefficient = _winCoefficient;
    }

    /**
     * @dev Sets the number of boxes available for betting.
     * @param _numberOfBoxes The new number of boxes.
     */
    function setNumberOfBoxes(uint256 _numberOfBoxes) external onlyOwner notZero(_numberOfBoxes) {
        numberOfBoxes = _numberOfBoxes;
    }

    /**
     * @dev Allows a player to place a bet on a box.
     * @param _boxNumber The player's selected box number.
     */
    function play(uint256 _boxNumber) external payable nonReentrant returns (uint256) {
        require(
            address(bankrollContract).balance >= (msg.value * winCoefficient) / COEFFICIENT_DENOMINATOR,
            "Insufficient funds"
        );
        require(_boxNumber > 0 && _boxNumber <= numberOfBoxes, "Incorrect bet number");
        require(msg.value >= minBet && msg.value <= maxBet, "Incorrect bet amount");
        payable(address(bankrollContract)).sendValue(msg.value);
        distributeReward(msg.sender);
        bets[msg.sender].push(Bet(block.number, msg.value, _boxNumber, salt, msg.sender));
        emit BetPlaced(msg.sender, block.number, msg.value, _boxNumber, salt);
        salt++;
        return salt - 1;
    }

    /**
     * @dev Allows a player to claim their prize.
     */
    function getPrize() external nonReentrant {
        uint256 winAmount = calculateTotalWin(msg.sender);
        require(winAmount > 0, "You have not won");
        delete bets[msg.sender];
        bankrollContract.sendFTN(msg.sender, winAmount);
        emit PrizeClaimed(msg.sender, winAmount);
    }

    function distributeReward(address _player) public {
        if (bets[_player].length == 0 || bets[_player][0].blockNumber == block.number) {
            return;
        }
        uint256 totalWin;
        for (uint256 i = 0; i < bets[_player].length; i++) {
            totalWin += calculateWin(_player, i);
        }
        delete bets[_player];
        if (totalWin > 0) {
            bankrollContract.sendFTN(_player, totalWin);
            emit RewardDistributed(totalWin);
        }
    }

    /**
     * @dev Retrieves the bets placed by a player.
     * @param _player The address of the player.
     * @return An array of Bet structs representing the player's bets.
     */
    function getPlayerBets(address _player) external view returns (Bet[] memory) {
        return bets[_player];
    }

    /**
     * @dev Calculates the total prize amount for a player.
     * @param _player The address of the player.
     * @return The total prize amount.
     */
    function calculateTotalWin(address _player) public view returns (uint256) {
        uint256 totalWin;
        for (uint256 i = 0; i < bets[_player].length; i++) {
            totalWin += calculateWin(_player, i);
        }
        return totalWin;
    }

    /**
     * @dev Calculates the prize for player's specific bet.
     * @param _player The address of the player.
     * @param _betIndex The index of the bet in the player's array of bets.
     * @return The amount of prize for the bet.
     */
    function calculateWin(address _player, uint256 _betIndex) public view returns (uint256) {
        Bet storage _bet = bets[_player][_betIndex];
        uint256 winNum = getRand(_bet.blockNumber, _bet.salt, _player);
        if (_bet.boxNumber == winNum) {
            return (_bet.amount * winCoefficient) / COEFFICIENT_DENOMINATOR;
        } else {
            return 0;
        }
    }

    /**
     * @dev Estimates the potential reward for a given bet amount.
     * @param _amount The amount of FTN staked in the bet.
     * @return The estimated reward based on the bet amount and the global win coefficient.
     * @notice This function provides an estimate of the potential reward for a bet
     * based on the specified amount of bet and the win coefficient stated in this smart contract.
     * The estimate does not represent the actual reward claimable by the player.
     * To claim the actual reward, use the 'getPrize' function after the bet's outcome is determined.
     * @dev The win coefficient used for the calculation is set by the contract owner.
     */
    function estimatePotentialReward(uint256 _amount) public view returns (uint256) {
        return (_amount * winCoefficient) / COEFFICIENT_DENOMINATOR;
    }

    /**
     * @dev Generates a random number based on the hash of the past block.
     * @param _blockNumber The block number to use for generation of a random number.
     * @return The random number.
     */
    function getRand(uint256 _blockNumber, uint256 _salt, address _player) internal view returns (uint256) {
        require(block.number > _blockNumber, "Block number is out of range");
        if (_blockNumber + 250 < block.number) {
            return 0;
        }
        return (uint256(keccak256(abi.encodePacked((blockhash(_blockNumber)), _salt, _player))) % numberOfBoxes) + 1;
    }

    /**
     * @dev Checks if a bet is a winning bet and calculates the potential prize.
     * @param _blockHash The hash of the block at which the bet was placed.
     * @param _boxNumber The player's selected box number.
     * @param _betAmount The amount of FTN staked in the bet.
     * @return The potential prize based on the bet outcome.
     * @dev The win coefficient used for the calculation is set by the contract owner.
     */
    function checkGameResult(bytes32 _blockHash, uint256 _boxNumber, uint256 _betAmount, uint256 _salt, address _player)
        external
        view
        returns (uint256)
    {
        uint256 winNum = (uint256(keccak256(abi.encodePacked(_blockHash, _salt, _player))) % numberOfBoxes) + 1;
        if (winNum == _boxNumber) {
            return (_betAmount * winCoefficient) / COEFFICIENT_DENOMINATOR;
        } else {
            return 0;
        }
    }
}
