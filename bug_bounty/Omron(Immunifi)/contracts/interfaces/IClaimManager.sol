// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaimManager {
    event DepositContractAddressSet(address indexed _depositContractAddress);
    event PointsClaimed(address indexed _user, uint256 _points);

    function setDepositContractAddress(
        address _depositContractAddress
    ) external;

    function claimPoints(address _user) external;
}
