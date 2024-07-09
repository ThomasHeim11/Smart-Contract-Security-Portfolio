// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../../../libraries/Client.sol";
import "forge-std/Test.sol";

contract ClientTest is Test {
  // Test _argsToBytes with EVMExtraArgsV1 using fuzzing
  function testArgsToBytesV1Fuzzing(uint256 gasLimit) public {
    // Setup
    Client.EVMExtraArgsV1 memory argsV1;
    argsV1.gasLimit = gasLimit;

    // Execute & Assert
    bytes memory result = Client._argsToBytes(argsV1);
    assertEq(result.length, 36, "Incorrect length for encoded args V1"); // 4 bytes selector + 32 bytes data
  }

  // Test _argsToBytes with EVMExtraArgsV2 using fuzzing
  function testArgsToBytesV2Fuzzing(uint256 gasLimit, bool allowOutOfOrderExecution) public {
    // Setup
    Client.EVMExtraArgsV2 memory argsV2;
    argsV2.gasLimit = gasLimit;
    argsV2.allowOutOfOrderExecution = allowOutOfOrderExecution;

    // Execute & Assert
    bytes memory result = Client._argsToBytes(argsV2);
    assertEq(result.length, 68, "Incorrect length for encoded args V2"); // 4 bytes selector + 32 bytes data + 32 byte bool
  }
}
