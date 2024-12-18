/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IAdapter} from "../interface/IAdapter.sol";
import {ISolidly} from "../interface/ISolidly.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract SolidlyAdapter is IAdapter {
    function swap(address receiver, address pool, address fromToken, address toToken, bytes calldata)
        external
        override
        returns (uint256 amountIn, uint256 amountOut)
    {
        address token0 = ISolidly(pool).token0();
        (uint256 _reserve0, uint256 _reserve1,) = ISolidly(pool).getReserves();
        require(_reserve0 > 0 && _reserve1 > 0, "Solidly: INSUFFICIENT_LIQUIDITY");

        bool isZeroForOne = fromToken == token0;
        uint256 reserveIn = isZeroForOne ? _reserve0 : _reserve1;
        amountIn = IERC20(fromToken).balanceOf(pool) - reserveIn;
        uint256 quoteAmountOut = ISolidly(pool).getAmountOut(amountIn, fromToken);

        uint256 balanceBefore = IERC20(toToken).balanceOf(receiver);
        // 发起调用
        if (isZeroForOne) {
            ISolidly(pool).swap(0, quoteAmountOut, receiver, new bytes(0));
        } else {
            ISolidly(pool).swap(quoteAmountOut, 0, receiver, new bytes(0));
        }

        // 获取receiver实际接收到的数量
        amountOut = IERC20(toToken).balanceOf(receiver) - balanceBefore;
    }
}
