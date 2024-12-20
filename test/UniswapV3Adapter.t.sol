// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {UniswapV3Adapter} from "../src/adapter/UniswapV3Adapter.sol";
import {IUniswapV3Pool} from "../src/interface/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract UniswapV3AdapterTest is Test {
    UniswapV3Adapter adapter;
    address receiver = address(0xD6938AeD0FA532C19c8fA50Db2AD33C1e2C4f9DF);
    IUniswapV3Pool pool = IUniswapV3Pool(0xd0b53D9277642d899DF5C87A3966A349A798F224); // Example pool address
    address fromToken = address(0x4200000000000000000000000000000000000006); // WETH
    address toToken = address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913); // USDC

    function setUp() public {
        string memory BASE_RPC_URL = vm.envString("BASE_RPC_URL");
        adapter = new UniswapV3Adapter();
        vm.createSelectFork(BASE_RPC_URL, 23912468);
    }

    function testSwap() public {
        uint256 amount = 1000e18;
        deal(fromToken, address(adapter), amount);

        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(fromToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);

        console2.log(amountIn, amountOut);
    }

    function testFuzz_Swap(uint256 amount) external {
        vm.assume(amount < 100000e18);
        // Transfer funds to the pool
        deal(fromToken, address(adapter), amount);
        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);

        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(fromToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
    }

    function testSwap2() public {
        uint256 amount = 1500e6;
        deal(toToken, address(adapter), amount);

        uint256 initialReceiverBalance = IERC20(fromToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), toToken, fromToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(toToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(fromToken).balanceOf(receiver) - initialReceiverBalance);

        console2.log(amountIn, amountOut);
    }
}
