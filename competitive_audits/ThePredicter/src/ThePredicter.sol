// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ScoreBoard} from "./ScoreBoard.sol";

contract ThePredicter {
    using Address for address payable;

    uint256 private constant START_TIME = 1723752000; // Thu Aug 15 2024 20:00:00 GMT+0000

    enum Status {
        Unknown,
        Pending,
        Approved,
        Canceled
    }

    address public organizer;
    address[] public players;
    uint256 public entranceFee;
    uint256 public predictionFee;
    ScoreBoard public scoreBoard;
    mapping(address players => Status) public playersStatus;

    error ThePredicter__IncorrectEntranceFee();
    error ThePredicter__RegistrationIsOver();
    error ThePredicter__IncorrectPredictionFee();
    error ThePredicter__AllPlacesAreTaken();
    error ThePredicter__CannotParticipateTwice();
    error ThePredicter__NotEligibleForWithdraw();
    error ThePredicter__PredictionsAreClosed();
    error ThePredicter__UnauthorizedAccess();

    constructor(
        address _scoreBoard,
        uint256 _entranceFee,
        uint256 _predictionFee
    ) {
        organizer = msg.sender;
        scoreBoard = ScoreBoard(_scoreBoard);
        entranceFee = _entranceFee;
        predictionFee = _predictionFee;
    }

    function register() public payable {
        if (msg.value != entranceFee) {
            revert ThePredicter__IncorrectEntranceFee();
        }

        if (block.timestamp > START_TIME - 14400) {
            revert ThePredicter__RegistrationIsOver();
        }

        if (playersStatus[msg.sender] == Status.Pending) {
            revert ThePredicter__CannotParticipateTwice();
        }

        playersStatus[msg.sender] = Status.Pending;
    }

    function cancelRegistration() public {
        if (playersStatus[msg.sender] == Status.Pending) {
            (bool success, ) = msg.sender.call{value: entranceFee}("");
            require(success, "Failed to withdraw");
            playersStatus[msg.sender] = Status.Canceled;
            return;
        }
        revert ThePredicter__NotEligibleForWithdraw();
    }

    function approvePlayer(address player) public {
        if (msg.sender != organizer) {
            revert ThePredicter__UnauthorizedAccess();
        }
        if (players.length >= 30) {
            revert ThePredicter__AllPlacesAreTaken();
        }
        if (playersStatus[player] == Status.Pending) {
            playersStatus[player] = Status.Approved;
            players.push(player);
        }
    }

    function makePrediction(
        uint256 matchNumber,
        ScoreBoard.Result prediction
    ) public payable {
        if (msg.value != predictionFee) {
            revert ThePredicter__IncorrectPredictionFee();
        }

        if (block.timestamp > START_TIME + matchNumber * 68400 - 68400) {
            revert ThePredicter__PredictionsAreClosed();
        }

        scoreBoard.confirmPredictionPayment(msg.sender, matchNumber);
        scoreBoard.setPrediction(msg.sender, matchNumber, prediction);
    }

    function withdrawPredictionFees() public {
        if (msg.sender != organizer) {
            revert ThePredicter__NotEligibleForWithdraw();
        }

        uint256 fees = address(this).balance - players.length * entranceFee;
        (bool success, ) = msg.sender.call{value: fees}("");
        require(success, "Failed to withdraw");
    }

    function withdraw() public {
        if (!scoreBoard.isEligibleForReward(msg.sender)) {
            revert ThePredicter__NotEligibleForWithdraw();
        }

        int8 score = scoreBoard.getPlayerScore(msg.sender);

        int8 maxScore = -1;
        int256 totalPositivePoints = 0;

        for (uint256 i = 0; i < players.length; ++i) {
            int8 cScore = scoreBoard.getPlayerScore(players[i]);
            if (cScore > maxScore) maxScore = cScore;
            if (cScore > 0) totalPositivePoints += cScore;
        }

        if (maxScore > 0 && score <= 0) {
            revert ThePredicter__NotEligibleForWithdraw();
        }

        uint256 shares = uint8(score);
        uint256 totalShares = uint256(totalPositivePoints);
        uint256 reward = 0;

        reward = maxScore < 0
            ? entranceFee
            : (shares * players.length * entranceFee) / totalShares;

        if (reward > 0) {
            scoreBoard.clearPredictionsCount(msg.sender);
            (bool success, ) = msg.sender.call{value: reward}("");
            require(success, "Failed to withdraw");
        }
    }
}
