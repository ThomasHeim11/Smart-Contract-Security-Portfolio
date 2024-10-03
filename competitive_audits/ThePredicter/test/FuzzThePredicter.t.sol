// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ThePredicter} from "../src/ThePredicter.sol";
import {ScoreBoard} from "../src/ScoreBoard.sol";

contract FuzzThePredicter is Test {
    ThePredicter predictTheWinner;
    ScoreBoard scoreboard;
    address organizer;
    uint256 entranceFee = 0.1 ether;
    uint256 predictionFee = 0.05 ether;

    function setUp() public {
        scoreboard = new ScoreBoard();
        predictTheWinner = new ThePredicter(address(scoreboard), entranceFee, predictionFee);
        organizer = address(this); // Making the test contract the organizer
    }

    function testFuzzRegister(uint256 fuzzValue) public {
        vm.assume(fuzzValue > 0 && fuzzValue < 3_000_000 ether);
        console.log("Running testFuzzRegister with value of %s", Strings.toString(fuzzValue));
        address player = vm.addr(1);
        vm.deal(player, fuzzValue);

        vm.startPrank(player);
        if (fuzzValue == entranceFee) {
            try predictTheWinner.register{value: entranceFee}() {
                assertTrue(predictTheWinner.playersStatus(player) == ThePredicter.Status.Pending);
                console.log("Registration successful for player.");
            } catch Error(string memory reason) {
                assertEq(reason, "", "Unexpected revert reason");
            }
        } else {
            try predictTheWinner.register{value: fuzzValue}() {
                revert(" should revert with incorrect entrance fee error");
            } catch Error(string memory reason) {
                assertEq(reason, "ThePredicter__IncorrectEntranceFee", "Unexpected revert reason");
            }
        }
        vm.stopPrank();
    }

    function testFuzzCancelRegistration(uint256 fuzzValue) public {
        address player = vm.addr(1);
        vm.deal(player, fuzzValue);

        vm.startPrank(player);
        if (fuzzValue == entranceFee) {
            predictTheWinner.register{value: entranceFee}();
            try predictTheWinner.cancelRegistration() {
                assertTrue(predictTheWinner.playersStatus(player) == ThePredicter.Status.Canceled);
                console.log("Cancellation successful for player.");
            } catch {
                revert("Unexpected failure during cancellation");
            }
        }
        vm.stopPrank();
    }

    function testFuzzApprovePlayer(uint256 fuzzValue) public {
        address player = vm.addr(fuzzValue);

        vm.startPrank(player);
        predictTheWinner.register{value: entranceFee}();
        vm.stopPrank();

        uint256 playerCount = playersCount();

        vm.startPrank(organizer);
        try predictTheWinner.approvePlayer(player) {
            if (playerCount >= 30) {
                revert("Test should revert with all places are taken error");
            }
            assertTrue(
                predictTheWinner.playersStatus(player) == ThePredicter.Status.Approved, "Player approval failed."
            );
        } catch Error(string memory reason) {
            if (playerCount >= 30) {
                assertEq(reason, "ThePredicter__AllPlacesAreTaken", "Unexpected revert reason");
            } else {
                revert("Unexpected failure during approval");
            }
        }
        vm.stopPrank();
    }

    function testFuzzMakePrediction(uint256 matchNumber, uint256 fuzzValue) public {
        address player = vm.addr(1);
        vm.deal(player, fuzzValue);

        vm.startPrank(player);
        predictTheWinner.register{value: entranceFee}();
        vm.stopPrank();

        vm.startPrank(organizer);
        predictTheWinner.approvePlayer(player);
        vm.stopPrank();

        vm.startPrank(player);
        if (fuzzValue == predictionFee) {
            try predictTheWinner.makePrediction{value: predictionFee}(matchNumber, ScoreBoard.Result(0)) {
                // assume Result.Home = 0
                console.log("Prediction made successfully.");
            } catch Error(string memory) {
                revert("Prediction should not revert with correct prediction fee");
            }
        } else {
            try predictTheWinner.makePrediction{value: fuzzValue}(matchNumber, ScoreBoard.Result(0)) {
                // assume Result.Home = 0
                revert("Test should revert with incorrect prediction fee error");
            } catch Error(string memory reason) {
                assertEq(reason, "ThePredicter__IncorrectPredictionFee", "Unexpected revert reason");
            }
        }
        vm.stopPrank();
    }

    function testWithdrawPredictionFees() public {
        vm.startPrank(organizer);
        try predictTheWinner.withdrawPredictionFees() {
            console.log("Withdraw prediction fees successful.");
        } catch Error(string memory) {
            revert("Unexpected failure during withdrawal of prediction fees");
        }
        vm.stopPrank();
    }

    function testFuzzWithdraw(uint256 fuzzValue) public {
        address player = vm.addr(1);
        vm.deal(player, fuzzValue);

        vm.startPrank(player);
        predictTheWinner.register{value: entranceFee}();
        vm.stopPrank();

        vm.startPrank(organizer);
        predictTheWinner.approvePlayer(player);
        vm.stopPrank();

        vm.startPrank(player);
        if (scoreboard.isEligibleForReward(player)) {
            try predictTheWinner.withdraw() {
                console.log("Withdrawal successful.");
            } catch {
                revert("Unexpected failure during withdrawal");
            }
        } else {
            try predictTheWinner.withdraw() {
                revert("Test should revert with not eligible for withdraw error");
            } catch Error(string memory reason) {
                assertEq(reason, "ThePredicter__NotEligibleForWithdraw", "Unexpected revert reason");
            }
        }
        vm.stopPrank();
    }

    function playersCount() private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0;; i++) {
            try predictTheWinner.players(i) returns (address) {
                count++;
            } catch {
                break;
            }
        }
        return count;
    }
}
