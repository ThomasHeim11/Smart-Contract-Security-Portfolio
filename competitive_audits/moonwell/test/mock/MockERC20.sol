// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.5.17;

import {IERC20} from "./IERC20.sol";
import {SafeMath} from "./SafeMath.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Moonwell
 **/
contract MockERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function __ERC20_init_unchained(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token
     **/
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token
     **/
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the decimals of the token
     **/
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return the total supply of the token
     **/
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return the balance of the token
     **/
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev executes a transfer of tokens from msg.sender to recipient
     * @param recipient the recipient of the tokens
     * @param amount the amount of tokens being transferred
     * @return true if the transfer succeeds, false otherwise
     **/
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev returns the allowance of spender on the tokens owned by owner
     * @param owner the owner of the tokens
     * @param spender the user allowed to spend the owner"s tokens
     * @return the amount of owner"s tokens spender is allowed to spend
     **/
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev allows spender to spend the tokens owned by msg.sender
     * @param spender the user allowed to spend msg.sender tokens
     * @return true
     **/
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev executes a transfer of token from sender to recipient, if msg.sender is allowed to do so
     * @param sender the owner of the tokens
     * @param recipient the recipient of the tokens
     * @param amount the amount of tokens being transferred
     * @return true if the transfer succeeds, false otherwise
     **/
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev increases the allowance of spender to spend msg.sender tokens
     * @param spender the user allowed to spend on behalf of msg.sender
     * @param addedValue the amount being added to the allowance
     * @return true
     **/
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev decreases the allowance of spender to spend msg.sender tokens
     * @param spender the user allowed to spend on behalf of msg.sender
     * @param subtractedValue the amount being subtracted to the allowance
     * @return true
     **/
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setName(string memory newName) internal {
        _name = newName;
    }

    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}
