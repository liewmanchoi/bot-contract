/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IAdapter} from "../interface/IAdapter.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract UniswapV2Adapter is IAdapter {
    function swap(address receiver, address pool, address fromToken, address toToken, bytes calldata moreInfo)
        external
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        // 解码出fee
        uint256 fee = abi.decode(moreInfo, (uint256));

        address baseToken = IUniswapV2Pair(pool).token0();
        (uint256 reserveIn, uint256 reserveOut,) = IUniswapV2Pair(pool).getReserves();
        require(reserveIn > 0 && reserveOut > 0, "UniAdapter: INSUFFICIENT_LIQUIDITY");

        uint256 balance0 = IERC20(baseToken).balanceOf(pool);
        uint256 sellBaseAmount = balance0 - reserveIn;

        uint256 sellBaseAmountWithFee = sellBaseAmount * 997;
        uint256 numerator = sellBaseAmountWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + sellBaseAmountWithFee;
        uint256 receiveQuoteAmount = numerator / denominator;
        IUniswapV2Pair(pool).swap(0, receiveQuoteAmount, receiver, new bytes(0));
    }

    function getAmountOut(address pool, address fromToken, address toToken, uint256 amountIn, bytes calldata moreInfo)
        external
        override
        returns (uint256 amountOut)
    {}
}
