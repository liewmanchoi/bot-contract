/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IAdapter} from "../interface/IAdapter.sol";
import {IPancakeV3Pool} from "../interface/IPancakeV3Pool.sol";
import {IPancakeV3SwapCallback} from "../interface/IPancakeV3SwapCallback.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract PancakeV3Adapter is IAdapter, IPancakeV3SwapCallback {
    using SafeTransferLib for ERC20;

    function swap(address receiver, address pool, address fromToken, address toToken, bytes calldata)
        external
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        address token0 = IPancakeV3Pool(pool).token0();
        bool isZeroForOne = fromToken == token0;

        // token要提前转到adapter合约，然后在回调函数中将资金转入pool合约
        amountIn = ERC20(fromToken).balanceOf(address(this));
        if (amountIn == 0) {
            return (0, 0);
        }

        uint160 sqrtPriceLimitX96;
        if (isZeroForOne) {
            // TickMath.MIN_SQRT_RATIO + 1
            sqrtPriceLimitX96 = 4295128739 + 1;
        } else {
            // TickMath.MAX_SQRT_RATIO - 1
            sqrtPriceLimitX96 = 1461446703485210103287273052203988822378723970342 - 1;
        }

        uint256 balanceBefore = ERC20(toToken).balanceOf(receiver);

        // 发起调用
        IPancakeV3Pool(pool).swap(
            receiver, isZeroForOne, int256(amountIn), sqrtPriceLimitX96, abi.encode(fromToken, toToken)
        );

        // 获取receiver实际接收到的数量
        amountOut = ERC20(toToken).balanceOf(receiver) - balanceBefore;
    }

    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut) = abi.decode(data, (address, address));

        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0 ? (tokenIn < tokenOut, uint256(amount0Delta)) : (tokenOut < tokenIn, uint256(amount1Delta));

        // msg.sender是pool合约地址
        if (isExactInput) {
            ERC20(tokenIn).safeTransfer(msg.sender, amountToPay);
        } else {
            // swap in/out because exact output swaps are reversed
            tokenIn = tokenOut;
            ERC20(tokenIn).safeTransfer(msg.sender, amountToPay);
        }
    }
}
