// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {SolidlyAdapter} from "../src/adapter/SolidlyAdapter.sol";
import {ISolidlyPool} from "../src/interface/ISolidlyPool.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract SolidlyAdapterTest is Test {
    string private BASE_RPC_URL = vm.envString("BASE_RPC_URL");
    SolidlyAdapter adapter;
    address receiver = address(0xD6938AeD0FA532C19c8fA50Db2AD33C1e2C4f9DF);

    function setUp() public {
        adapter = new SolidlyAdapter();
        vm.createSelectFork(BASE_RPC_URL, 23912468);
    }

    function test_stable_Swap() public {
        // USR-USDC
        ISolidlyPool pool = ISolidlyPool(0xd3eE0a3B349237D68517DF30bFB66Be971f46Ad9);
        // USDC
        address fromToken = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        // USR
        address toToken = 0x35E5dB674D8e93a03d814FA0ADa70731efe8a4b9;

        // Transfer funds to the pool
        deal(fromToken, address(this), 20000e6);
        IERC20(fromToken).transfer(address(pool), 20000e6);
        console2.log("pool fromToken balance", IERC20(fromToken).balanceOf(address(pool)));
        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        console2.log("initialReceiverBalance", initialReceiverBalance);

        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, 20000e6);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
        console2.log(amountIn, amountOut);
    }

    function testFuzz_stable_Swap(uint256 amount) external {
        vm.assume(amount < 100000000e6);

        // USR-USDC
        ISolidlyPool pool = ISolidlyPool(0xd3eE0a3B349237D68517DF30bFB66Be971f46Ad9);
        // USDC
        address fromToken = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        // USR
        address toToken = 0x35E5dB674D8e93a03d814FA0ADa70731efe8a4b9;

        // Transfer funds to the pool
        deal(fromToken, address(this), amount);
        IERC20(fromToken).transfer(address(pool), amount);
        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);

        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, amount);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
    }

    function test_unstable_Swap() public {
        // USDC-AERO
        ISolidlyPool pool = ISolidlyPool(0x6cDcb1C4A4D1C3C6d054b27AC5B77e89eAFb971d);
        // AERO
        address fromToken = 0x940181a94A35A4569E4529A3CDfB74e38FD98631;
        // USDC
        address toToken = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

        // Transfer funds to the pool
        deal(fromToken, address(this), 20000e18);
        IERC20(fromToken).transfer(address(pool), 20000e18);
        console2.log("pool fromToken balance", IERC20(fromToken).balanceOf(address(pool)));
        uint256 initialReceiverBalance = IERC20(toToken).balanceOf(receiver);
        console2.log("initialReceiverBalance", initialReceiverBalance);

        (uint256 amountIn, uint256 amountOut) = adapter.swap(receiver, address(pool), fromToken, toToken, "");

        assertEq(amountIn, 20000e18);
        assertEq(amountOut, IERC20(toToken).balanceOf(receiver) - initialReceiverBalance);
        console2.log(amountIn, amountOut);
    }

    function test_SwapInsufficientLiquidity() public {
        // USR-USDC
        ISolidlyPool pool = ISolidlyPool(0xd3eE0a3B349237D68517DF30bFB66Be971f46Ad9);
        // USDC
        address fromToken = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        // USR
        address toToken = 0x35E5dB674D8e93a03d814FA0ADa70731efe8a4b9;

        // Empty the pool reserves
        vm.mockCall(
            address(pool),
            abi.encodeWithSelector(ISolidlyPool.getReserves.selector),
            abi.encode(uint112(0), uint112(0), uint32(0))
        );

        vm.expectRevert("Solidly: INSUFFICIENT_LIQUIDITY");
        adapter.swap(receiver, address(pool), fromToken, toToken, "");
    }
}
