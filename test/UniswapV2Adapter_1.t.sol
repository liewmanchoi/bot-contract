// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {UniswapV2Adapter} from "../src/adapter/UniswapV2Adapter.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract UniswapV2Adapter1Test is Test {
    UniswapV2Adapter adapter;
    address receiver = address(0xD6938AeD0FA532C19c8fA50Db2AD33C1e2C4f9DF);

    function setUp() public {
        string memory BASE_RPC_URL = vm.envString("BASE_RPC_URL");
        adapter = new UniswapV2Adapter();
        vm.createSelectFork(BASE_RPC_URL, 24748857);
    }

    function testSwap1() public {
        IUniswapV2Pair pool = IUniswapV2Pair(0x7960fB2002a75B8ae552b5E539D42714225A3B60);
        address fromToken = address(0x4200000000000000000000000000000000000006);
        address toToken = address(0x4acC81dc9c03e5329a2c19763A1D10ba9308339F);

        uint256 amount = 34617287671394560;
        deal(fromToken, address(this), amount);
        IERC20(fromToken).transfer(address(pool), amount);

        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) =
            adapter.swap(receiver, address(pool), fromToken, toToken, abi.encode(30));

        assertEq(amountIn, amount);
        assertEq(IERC20(fromToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);

        console2.log(amountIn, amountOut);
    }
}
