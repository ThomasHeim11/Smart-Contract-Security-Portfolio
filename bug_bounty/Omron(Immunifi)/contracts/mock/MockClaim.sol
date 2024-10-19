// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {IOmronDeposit} from "../interfaces/IOmronDeposit.sol";
import {IClaimManager} from "../interfaces/IClaimManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockClaim
 * @author Inference Labs
 * @notice MockClaim is a mock claim contract implementation for claiming points and withdrawing tokens from the OmronDeposit contract.
 */
contract MockClaim is IClaimManager, Ownable {
    IOmronDeposit depositContract;

    constructor(address _deposit) Ownable(msg.sender) {
        depositContract = IOmronDeposit(_deposit);
    }

    function setDepositContractAddress(
        address _depositContractAddress
    ) external onlyOwner {
        depositContract = IOmronDeposit(_depositContractAddress);
        emit DepositContractAddressSet(_depositContractAddress);
    }

    function claimPoints(address _addressToClaimFor) external {
        uint256 pointsClaimed = depositContract.claim(_addressToClaimFor);
        emit PointsClaimed(_addressToClaimFor, pointsClaimed);
    }
}
