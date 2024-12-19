// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {UniswapV2Adapter} from "../src/adapter/UniswapV2Adapter.sol";
import {IUniswapV2Pair} from "@uniswap-v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract UniswapV2AdapterTest is Test {
    string private BASE_RPC_URL = vm.envString("BASE_RPC_URL");
    UniswapV2Adapter adapter;
    // WETH-USDC
    address receiver = address(0xD6938AeD0FA532C19c8fA50Db2AD33C1e2C4f9DF);
    IUniswapV2Pair pool = IUniswapV2Pair(0x88A43bbDF9D098eEC7bCEda4e2494615dfD9bB9C);
    // WETH
    address fromToken = address(0x4200000000000000000000000000000000000006);
    // USDC
    address toToken = address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    bytes moreInfo = abi.encode(uint256(30)); // 0.3% fee

    function setUp() public {
        adapter = new UniswapV2Adapter();
        vm.createSelectFork(BASE_RPC_URL, 23912468);
    }

    function test_Swap() public {
        // todo: fuzz test

        // Transfer funds to the pool
        deal(fromToken, address(this), 110e18);
        IERC20(fromToken).transfer(address(pool), 110e18);
        console2.log("pool fromToken balance", IERC20(fromToken).balanceOf(address(pool)));
        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        console2.log("initialReceiverBalance", initialReceiverBalance);

        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, moreInfo);

        assertEq(amountIn, 110e18);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
        console2.log(amountIn, amountOut);
    }

    function testFuzz_Swap(uint256 amount) external {
        vm.assume(amount < 10000e18);
        // Transfer funds to the pool
        deal(fromToken, address(this), amount);
        IERC20(fromToken).transfer(address(pool), amount);
        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);

        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, moreInfo);

        assertEq(amountIn, amount);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
    }

    function test_SwapInsufficientLiquidity() public {
        // Empty the pool reserves
        vm.mockCall(
            address(pool),
            abi.encodeWithSelector(IUniswapV2Pair.getReserves.selector),
            abi.encode(uint112(0), uint112(0), uint32(0))
        );

        vm.expectRevert("UniswapV2Adapter:INSUFFICIENT_LIQUIDITY");
        adapter.swap(receiver, address(pool), fromToken, toToken, moreInfo);
    }
}
