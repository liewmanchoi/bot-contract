/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IERC20} from "@openzeppelin-contracts-5.2.0-rc.0/token/ERC20/IERC20.sol";

interface IBorrower {
    function makeFlashloan(uint256[] calldata amounts, bytes calldata callback) external;
    function onFlashloan(uint256[] calldata amounts, bytes calldata callback) external;
}