// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ScoreBoard {
    uint256 private constant START_TIME = 1723752000; // Thu Aug 15 2024 20:00:00 GMT+0000
    uint256 private constant NUM_MATCHES = 9;

    enum Result {
        Pending,
        First,
        Draw,
        Second
    }

    struct PlayerPredictions {
        Result[NUM_MATCHES] predictions;
        bool[NUM_MATCHES] isPaid;
        uint8 predictionsCount;
    }

    address owner;
    address thePredicter;
    Result[NUM_MATCHES] private results;
    mapping(address players => PlayerPredictions) playersPredictions;

    error ScoreBoard__UnauthorizedAccess();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ScoreBoard__UnauthorizedAccess();
        }
        _;
    }

    modifier onlyThePredicter() {
        if (msg.sender != thePredicter) {
            revert ScoreBoard__UnauthorizedAccess();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setThePredicter(address _thePredicter) public onlyOwner {
        thePredicter = _thePredicter;
    }

    function setResult(uint256 matchNumber, Result result) public onlyOwner {
        results[matchNumber] = result;
    }

    function confirmPredictionPayment(
        address player,
        uint256 matchNumber
    ) public onlyThePredicter {
        playersPredictions[player].isPaid[matchNumber] = true;
    }

    function setPrediction(
        address player,
        uint256 matchNumber,
        Result result
    ) public {
        if (block.timestamp <= START_TIME + matchNumber * 68400 - 68400)
            playersPredictions[player].predictions[matchNumber] = result;
        playersPredictions[player].predictionsCount = 0;
        for (uint256 i = 0; i < NUM_MATCHES; ++i) {
            if (
                playersPredictions[player].predictions[i] != Result.Pending &&
                playersPredictions[player].isPaid[i]
            ) ++playersPredictions[player].predictionsCount;
        }
    }

    function clearPredictionsCount(address player) public onlyThePredicter {
        playersPredictions[player].predictionsCount = 0;
    }

    function getPlayerScore(address player) public view returns (int8 score) {
        for (uint256 i = 0; i < NUM_MATCHES; ++i) {
            if (
                playersPredictions[player].isPaid[i] &&
                playersPredictions[player].predictions[i] != Result.Pending
            ) {
                score += playersPredictions[player].predictions[i] == results[i]
                    ? int8(2)
                    : -1;
            }
        }
    }

    function isEligibleForReward(address player) public view returns (bool) {
        return
            results[NUM_MATCHES - 1] != Result.Pending &&
            playersPredictions[player].predictionsCount > 1;
    }
}
