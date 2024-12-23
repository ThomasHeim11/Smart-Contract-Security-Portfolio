//SPDX-License-Identifier: MIT

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.27;

contract ChristmasDinner {
    using SafeERC20 for IERC20;
    ////////////////////////////////////////////////////////////////
    //////////////////        Custom Errors        /////////////////
    ////////////////////////////////////////////////////////////////
    error NotHost();
    error BeyondDeadline();
    error DeadlineAlreadySet();
    error OnlyParticipantsCanBeHost();
    error NotSupportedToken();

    ////////////////////////////////////////////////////////////////
    //////////////////        Custom Events        /////////////////
    ////////////////////////////////////////////////////////////////
    event NewHost(address indexed);
    event NewSignup(address indexed, uint256 indexed, bool indexed);
    event GenerousAdditionalContribution(address indexed, uint256 indexed);
    event ChangedParticipation(address indexed, bool indexed);
    event Refunded(address indexed);
    event DeadlineSet(uint256 indexed);

    ////////////////////////////////////////////////////////////////
    //////////////////         Immutables          /////////////////
    ////////////////////////////////////////////////////////////////
    IERC20 public immutable i_WBTC;
    IERC20 public immutable i_WETH;
    IERC20 public immutable i_USDC;


    ////////////////////////////////////////////////////////////////
    //////////////////       State Variables       /////////////////
    ////////////////////////////////////////////////////////////////
    address public host;
    uint256 public deadline;
    bool public deadlineSet = false;
    bool private locked = false;
    mapping (address user => bool) participant;
    mapping (address user => mapping (address token => uint256 balance )) balances;
    mapping (address user => uint256 amount) etherBalance;
    mapping (address token => bool ) whitelisted;

    constructor (address _WBTC, address _WETH, address _USDC) {
        host = msg.sender;
        i_WBTC = IERC20(_WBTC);
        whitelisted[_WBTC] = true;
        i_WETH = IERC20(_WETH);
        whitelisted[_WETH] = true;
        i_USDC = IERC20(_USDC);
        whitelisted[_USDC] = true;
    }

    ////////////////////////////////////////////////////////////////
    /////////   Modifiers for Privileged External     //////////////
    ////////////////////////////////////////////////////////////////

    modifier onlyHost() {
        if(msg.sender != host) {
            revert NotHost();
        }
        _;
    }

    modifier beforeDeadline() {
        if(block.timestamp > deadline) {
            revert BeyondDeadline();
        }
        _;
    }

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        _;
        locked = false;
    }


    ////////////////////////////////////////////////////////////////
    //////////////////      External Functions     /////////////////
    ////////////////////////////////////////////////////////////////

    ///////////////////////    View Methods  ///////////////////////
    /**
     * @dev Simple Getter function for the host, primarly for streamlined testing purposes
     */
    function getHost() public view returns (address _host) {
        return host;
    }

    /**
     * @dev Simple getter function for the participation, steamlined testing
     */
    function getParticipationStatus(address _user) public view returns (bool) {
        return participant[_user];
    }

    ///////////////////////  State Changing External  ///////////////////////

    /**
     * @dev handles the deposit logic. Supposed to only let deposits of whitelisted tokens happen.
     * Supposed to not accept deposits after deadline. Allows multiple deposits of a user as generous extra contribution.
     * Allows a user to sign-up other users.
     * Assumes that no weird ERC20s or any ERC20s outside the whitelisted tokens need to be handled.
     * Assumes general trust relationship between the users of this contract.
     * Does not allow signing up with Ether, for Ether signups use receive()
     * @param _token the token the user wishes to deposit
     * @param _amount the amount the user wishes to contribute
     */
    function deposit(address _token, uint256 _amount) external beforeDeadline {
        if(!whitelisted[_token]) {
            revert NotSupportedToken();
        }
        if(participant[msg.sender]){
            balances[msg.sender][_token] += _amount;
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            emit GenerousAdditionalContribution(msg.sender, _amount);
        } else {
            participant[msg.sender] = true;
            balances[msg.sender][_token] += _amount;
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            emit NewSignup(msg.sender, _amount, getParticipationStatus(msg.sender));
        }

    }

    /**
     * @dev Refund function if people do not want to attend the event anymore, 
     * pays out all underlying assets. Reentrancy safe via mutex lock, therefor 
     * CEI does not necessarly need to be followed.
     */
    function refund() external nonReentrant beforeDeadline {
        address payable _to = payable(msg.sender);
        _refundERC20(_to);
        _refundETH(_to);
        emit Refunded(msg.sender);
    }

    /**
     * @dev supports not attending without a refund, also allows many changes of mind
     * But strictly enforces that false can not be changed to true after the deadline
     */
    function changeParticipationStatus() external {
        if(participant[msg.sender]) {
            participant[msg.sender] = false;
        } else if(!participant[msg.sender] && block.timestamp <= deadline) {
            participant[msg.sender] = true;
        } else {
            revert BeyondDeadline();
        }
        emit ChangedParticipation(msg.sender, participant[msg.sender]);
    }

    ////////////////////// Privileged External Functions  //////////////////////////
    /**
     * @dev Changes the host of the event. Must be Changeable multiple times
     * to avoid spontanous cancellation issues of the host (the host must attend the event).
     * We assume that if the host changes after deadline, the new host has an agreement with the old host
     * to make the event work.
     * @param _newHost an arbitrary user which is participant
     */
    function changeHost(address _newHost) external onlyHost {
        if(!participant[_newHost]) {
            revert OnlyParticipantsCanBeHost();
        }
        host = _newHost;
        emit NewHost(host);
    }

    /**
     * @dev changes the deadline until which attendees can sign up. Any sign up or refund after the deadline 
     * should never be possible to assure proper planning for the attendees
     * @param _days Number in days until when the host has to know who attends
     */
    function setDeadline(uint256 _days) external onlyHost {
        if(deadlineSet) {
            revert DeadlineAlreadySet();
        } else {
            deadline = block.timestamp + _days * 1 days;
            emit DeadlineSet(deadline);
        }
    }

    /**
     * @dev withdraws all tokens from the contract into the host wallet, to fascilitate the event.
     * we do not have reentrancy considerations, since this function is supposed to sweep the contract anyway 
     */

    function withdraw() external onlyHost {
        address _host = getHost();
        i_WETH.safeTransfer(_host, i_WETH.balanceOf(address(this)));
        i_WBTC.safeTransfer(_host, i_WBTC.balanceOf(address(this)));
        i_USDC.safeTransfer(_host, i_USDC.balanceOf(address(this)));
    }
    ///////////////////////// Receive  Function to handle Ether Deposits  //////////////////////////
    /**
     * @dev handles ether signups, users sending ether to this contract will still be tracked 
     * with their balances and participation status.
     */
    receive() external payable {
        etherBalance[msg.sender] += msg.value;
        emit NewSignup(msg.sender, msg.value, true);
    }

    ////////////////////////////////////////////////////////////////
    /////////////////      Internal Functions         //////////////
    ////////////////////////////////////////////////////////////////

    /**
     * @dev ERC20 withdrawal of all user funds. No concern for Reentrancy
     * since refund() uses a Mutex Lock
     * @param _to payable address passed from refund()
     */
    function _refundERC20(address _to) internal {
        i_WETH.safeTransfer(_to, balances[_to][address(i_WETH)]);
        i_WBTC.safeTransfer(_to, balances[_to][address(i_WBTC)]);
        i_USDC.safeTransfer(_to, balances[_to][address(i_USDC)]);
        balances[_to][address(i_USDC)] = 0;
        balances[_to][address(i_WBTC)] = 0;
        balances[_to][address(i_WETH)] = 0;
    }

    /**
     * @dev ERC20 withdrawal of all user funds. No concern for Reentrancy
     * since refund() uses a Mutex Lock
     * @param _to payable address passed from refund()
     */
    function _refundETH(address payable _to) internal {
        uint256 refundValue = etherBalance[_to];
        _to.transfer(refundValue);
        etherBalance[_to] = 0;
    }
}