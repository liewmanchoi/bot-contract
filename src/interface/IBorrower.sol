/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

interface IBorrower {
    function makeFlashloan(IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
    // 回调函数注意权限控制
    function onFlashloan(IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
}
