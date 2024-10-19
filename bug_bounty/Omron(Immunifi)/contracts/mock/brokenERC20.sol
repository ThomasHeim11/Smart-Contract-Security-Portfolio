// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BrokenERC20 is ERC20 {
    bool public transfersEnabled;
    uint256 public approvalRejectAmount;

    constructor(uint256 initialSupply) ERC20("Broken ERC20", "brokenERC20") {
        _mint(msg.sender, initialSupply);
    }

    function setTransfersEnabled(bool _enabled) public {
        transfersEnabled = _enabled;
    }

    function setApprovalRejectAmount(uint256 _revertAmount) public {
        approvalRejectAmount = _revertAmount;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return
            transfersEnabled && super.transferFrom(sender, recipient, amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return transfersEnabled && super.transfer(recipient, amount);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        return
            amount == approvalRejectAmount
                ? false
                : super.approve(spender, amount);
    }
}
