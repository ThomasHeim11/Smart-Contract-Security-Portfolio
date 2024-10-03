// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol"; // Import console for logging
import "./BobAttack.sol"; // Correct path from test/ to src/
import "./mocks/MockERC20Token.sol"; // Correct path from test/ to src/mocks/
import "../src/core/TokenManager.sol" as CoreTokenManager; // Use alias to avoid name conflict

contract FuzzTokenManagerTest is Test {
    CoreTokenManager.TokenManager tokenManager;
    MockERC20Token mockERC20Token;
    BobAttack bobAttack;

    event LogInitialBalances(uint256 bobBalance, uint256 tokenManagerBalance);
    event LogRevertReason(string reason);
    event LogRevertReasonBytes(bytes reason);

    function setUp() public {
        tokenManager = new CoreTokenManager.TokenManager();
        mockERC20Token = new MockERC20Token();
        bobAttack = new BobAttack(address(tokenManager), address(mockERC20Token));

        // Assuming TokenManager requires some setup for its wrapped native token
    }

    function testTillInFunctionWithFuzzValues(uint256 fuzzValue) public {
        vm.assume(fuzzValue > 0 && fuzzValue < 100 ether);

        uint256 managerFundAmount = fuzzValue / 10;
        vm.deal(address(tokenManager), managerFundAmount);

        // Fund BobAttack contract with fuzzing value
        vm.deal(address(bobAttack), fuzzValue);

        emit log_named_uint("BobAttack balance before exploit:", address(bobAttack).balance);
        emit log_named_uint("TokenManager balance before exploit:", address(tokenManager).balance);

        // Execute attack
        vm.prank(address(bobAttack));

        try bobAttack.exploitTillIn{value: fuzzValue}(fuzzValue) {
            emit log("Exploit succeeded without revert");
        } catch Error(string memory reason) {
            emit LogRevertReason(reason);
        } catch (bytes memory lowLevelData) {
            emit LogRevertReasonBytes(lowLevelData);
        }

        emit log_named_uint("BobAttack balance after exploit:", address(bobAttack).balance);
        emit log_named_uint("TokenManager balance after exploit:", address(tokenManager).balance);
        emit log_named_uint("MockERC20Token balance:", mockERC20Token.balanceOf(address(tokenManager)));
    }
}
