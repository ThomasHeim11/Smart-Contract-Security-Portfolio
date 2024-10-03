// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// contract MockERC20 is IERC20 {
//     constructor(string memory name, string memory symbol, uint8 decimals) IERC20(name, symbol) {
//         _setupDecimals(decimals);
//     }

//     function mint(address to, uint256 amount) public {
//         _mint(to, amount);
//     }

//     function _setupDecimals(uint8 decimals_) internal {
//         // Solc 0.8.0 and later does not allow modifying decimals directly
//         assembly {
//             sstore(0x6, decimals_)
//         }
//     }
// }
