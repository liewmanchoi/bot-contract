/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

interface IBorrower {
    function makeFlashloan(address[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
}
