// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {PancakeV3Adapter} from "../src/adapter/PancakeV3Adapter.sol";
import {IPancakeV3Pool} from "../src/interface/IPancakeV3Pool.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract PancakeV3AdapterTest is Test {
    PancakeV3Adapter adapter;

    address receiver = address(0xD6938AeD0FA532C19c8fA50Db2AD33C1e2C4f9DF);
    IPancakeV3Pool pool = IPancakeV3Pool(0x75CC10fdcEa4b7D13c115ABB08240ac9c9Be6f2f);
    // WETH
    address fromToken = address(0x4200000000000000000000000000000000000006);
    // BRET
    address toToken = address(0x532f27101965dd16442E59d40670FaF5eBB142E4);

    function setUp() public {
        string memory BASE_RPC_URL = vm.envString("BASE_RPC_URL");
        adapter = new PancakeV3Adapter();
        vm.createSelectFork(BASE_RPC_URL, 24118402);
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
        uint256 amount = 1500e18;
        deal(toToken, address(adapter), amount);

        uint256 initialReceiverBalance = IERC20(fromToken).balanceOf(receiver);
        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), toToken, fromToken, "");

        assertEq(amountIn, amount);
        assertEq(IERC20(toToken).balanceOf(address(adapter)), 0);
        assertEq(amountOut, IERC20(fromToken).balanceOf(receiver) - initialReceiverBalance);

        console2.log(amountIn, amountOut);
    }
}
