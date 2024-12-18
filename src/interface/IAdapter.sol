/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

interface IAdapter {
    function swap(address receiver, address pool, address fromToken, address toToken, bytes calldata moreInfo)
        external
        returns (uint256 amountIn, uint256 amountOut);
    // todo: 需不需要直接指定amountIn
    function getAmountOut(address pool, address fromToken, address toToken, uint256 amountIn, bytes calldata moreInfo)
        external
        returns (uint256 amountOut);
}
