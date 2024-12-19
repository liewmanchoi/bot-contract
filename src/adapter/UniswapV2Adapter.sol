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
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pool).getReserves();
        require(reserve0 > 0 && reserve1 > 0, "UniswapV2Adapter:INSUFFICIENT_LIQUIDITY");
        address token0 = IUniswapV2Pair(pool).token0();

        bool isZeroForOne = fromToken == token0;
        (uint256 reserveIn, uint256 reserveOut) = isZeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        amountIn = IERC20(fromToken).balanceOf(pool) - reserveIn;

        // 解码出fee（百分比 * 10000）
        uint256 fee = abi.decode(moreInfo, (uint256));
        uint256 amountInWithFee = amountIn * (10000 - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10000 + amountInWithFee;
        uint256 quoteAmountOut = numerator / denominator;

        if (quoteAmountOut == 0) {
            return (amountIn, 0);
        }

        uint256 balanceBefore = IERC20(toToken).balanceOf(receiver);
        // 发起调用
        if (isZeroForOne) {
            IUniswapV2Pair(pool).swap(0, quoteAmountOut, receiver, new bytes(0));
        } else {
            IUniswapV2Pair(pool).swap(quoteAmountOut, 0, receiver, new bytes(0));
        }

        // 获取receiver实际接收到的数量
        amountOut = IERC20(toToken).balanceOf(receiver) - balanceBefore;
    }
}
