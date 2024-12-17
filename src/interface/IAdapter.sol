/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

interface IAdapter {
    function swap(address receiver, address pool, address fromToken, address toToken, bytes calldata moreInfo) external payable returns (uint256);
    // todo: 需不需要直接指定amountsIn
    function getAmountsOut(address pool, address fromToken, address toToken, bytes calldata moreInfo) external returns (uint256);
}
