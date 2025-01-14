// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {UniswapV3Adapter} from "../src/adapter/UniswapV3Adapter.sol";
import {IUniswapV3Pool} from "../src/interface/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract UniswapV3Adapter2Test is Test {
    UniswapV3Adapter adapter;
    address receiver = address(0xD6938AeD0FA532C19c8fA50Db2AD33C1e2C4f9DF);

    function setUp() public {
        string memory BASE_RPC_URL = vm.envString("BASE_RPC_URL");
        adapter = new UniswapV3Adapter();
        vm.createSelectFork(BASE_RPC_URL, 24748857);
    }

    function testSwap1() public {
        IUniswapV3Pool pool = IUniswapV3Pool(0x14E0D45c7B0d82E226990E9DDf260e06bb9Cd78A);
        address fromToken = address(0x4200000000000000000000000000000000000006);
        address toToken = address(0xBA5eDF631828EBbe81B850F476FA5936e3C15783);

        uint256 amount = 26231999195282584;
        deal(fromToken, address(adapter), amount);

        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(fromToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);

        console2.log(amountIn, amountOut);
    }

    function testSwap2() public {
        IUniswapV3Pool pool = IUniswapV3Pool(0x68a1f6B6A725Bb74B6aBE41379a0e77031C0C5f5);
        address fromToken = address(0x4200000000000000000000000000000000000006);
        address toToken = address(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);

        uint256 amount = 746647240156011648;
        deal(fromToken, address(adapter), amount);
        console2.log("liquidity:", pool.liquidity());
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        ) = pool.slot0();
        console2.log("sqrtPriceX96:", sqrtPriceX96);
        console2.log("tick:", tick);

        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(fromToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
        console2.log("liquidity:", pool.liquidity());
        (
            sqrtPriceX96,
            tick,
            observationIndex,
            observationCardinality,
            observationCardinalityNext,
            feeProtocol,
            unlocked
        ) = pool.slot0();
        console2.log("sqrtPriceX96:", sqrtPriceX96);
        console2.log("tick:", tick);
        console2.log(amountIn, amountOut);
    }

    function testSwap3() public {
        IUniswapV3Pool pool = IUniswapV3Pool(0x310FEc07824b292B6Ac880b6422BAa43e1Ae4A97);
        address fromToken = address(0x4200000000000000000000000000000000000006);
        address toToken = address(0xF878e27aFB649744EEC3c5c0d03bc9335703CFE3);

        uint256 amount = 43075895661266872000;
        deal(fromToken, address(adapter), amount);

        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(fromToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);

        console2.log(amountIn, amountOut);
    }
}
