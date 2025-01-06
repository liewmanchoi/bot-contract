// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {FlashloanInfo} from "../src/interface/IRouter.sol";
import {SwapGroup} from "../src/interface/IRouter.sol";
import {Swap} from "../src/interface/IRouter.sol";
import {GroupResult} from "../src/interface/IRouter.sol";
import {IAdapter} from "../src/interface/IAdapter.sol";
import {SolidlyAdapter} from "../src/adapter/SolidlyAdapter.sol";
import {UniswapV2Adapter} from "../src/adapter/UniswapV2Adapter.sol";
import {UniswapV3Adapter} from "../src/adapter/UniswapV3Adapter.sol";
import {PancakeV3Adapter} from "../src/adapter/PancakeV3Adapter.sol";
import {BalancerV2Borrower} from "../src/borrower/BalancerV2Borrower.sol";
import {RouterV1} from "../src/router/RouterV1.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract OverallTest is Test {
    UniswapV2Adapter uniswapV2Adapter;
    UniswapV3Adapter uniswapV3Adapter;
    SolidlyAdapter solidlyAdapter;
    PancakeV3Adapter pancakeV3Adapter;
    BalancerV2Borrower balancerV2Borrower;
    RouterV1 routerV1;
    string BASE_RPC_URL;

    function setUp() external {
        BASE_RPC_URL = vm.envString("BASE_RPC_URL");
        vm.createSelectFork(BASE_RPC_URL, 24251733);

        // 部署合约
        uniswapV2Adapter = new UniswapV2Adapter();
        console2.log("uniswapV2Adapter", address(uniswapV2Adapter));

        uniswapV3Adapter = new UniswapV3Adapter();
        console2.log("uniswapV3Adapter", address(uniswapV3Adapter));

        solidlyAdapter = new SolidlyAdapter();
        console2.log("solidlyAdapter", address(solidlyAdapter));

        pancakeV3Adapter = new PancakeV3Adapter();
        console2.log("pancakeV3Adapter", address(pancakeV3Adapter));

        balancerV2Borrower = new BalancerV2Borrower(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        console2.log("balancerV2Borrower", address(balancerV2Borrower));

        routerV1 = new RouterV1(0xC3F0B5159e725D112C709b31E30F8e7e6af25fD4);
        console2.log("routerV1", address(routerV1));
    }

    function test_execute() external {
        address[] memory tokens = new address[](1);
        tokens[0] = 0x4200000000000000000000000000000000000006;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2357747868672944640;

        IAdapter[] memory adapters = new IAdapter[](2);
        adapters[0] = uniswapV2Adapter;
        adapters[1] = uniswapV2Adapter;

        address pool1 = 0xEC0C2E40973E8B5cf1B083B917644F1fF57AfAc6;
        address pool2 = 0xC2dced7Ce908652d3b55D55555DcE96b6cdCB191;

        Swap[] memory swaps1 = new Swap[](2);
        swaps1[0] = Swap({
            receiver: pool2,
            pool: pool1,
            fromToken: 0x4200000000000000000000000000000000000006,
            toToken: 0x2DC1cDa9186a4993bD36dE60D08787c0C382BEAD,
            moreInfo: abi.encode(25)
        });

        swaps1[1] = Swap({
            receiver: address(balancerV2Borrower),
            pool: pool2,
            fromToken: 0x2DC1cDa9186a4993bD36dE60D08787c0C382BEAD,
            toToken: 0x4200000000000000000000000000000000000006,
            moreInfo: abi.encode(30)
        });

        SwapGroup memory swapGroup1 = SwapGroup({
            baseToken: 0x4200000000000000000000000000000000000006,
            initialAmount: 2357747868672944640,
            fundReceiver: pool1,
            adapters: adapters,
            swaps: swaps1
        });

        SwapGroup[] memory swapGroups = new SwapGroup[](1);
        swapGroups[0] = swapGroup1;

        (address[] memory baseTokens, uint256[] memory profits) = routerV1.execute({
            borrower: balancerV2Borrower,
            flashloanInfo: FlashloanInfo({tokens: tokens, amounts: amounts}),
            swapGroups: swapGroups
        });

        for (uint256 i = 0; i < baseTokens.length; i++) {
            console2.log("baseToken", baseTokens[i]);
            console2.log("profit", profits[i]);
        }
    }

    function test_quoteExecute() external {
        address[] memory tokens = new address[](1);
        tokens[0] = 0x4200000000000000000000000000000000000006;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10105418569764879;

        IAdapter[] memory adapters = new IAdapter[](3);
        adapters[0] = uniswapV3Adapter;
        adapters[1] = uniswapV2Adapter;
        adapters[2] = uniswapV3Adapter;

        Swap[] memory swaps1 = new Swap[](3);
        swaps1[0] = Swap({
            receiver: 0xB036D38073CE3cAcbd26AB9000d3653dbb296Abe,
            pool: 0x9c087Eb773291e50CF6c6a90ef0F4500e349B903,
            fromToken: 0x4200000000000000000000000000000000000006,
            toToken: 0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b,
            moreInfo: new bytes(0)
        });

        swaps1[1] = Swap({
            receiver: address(uniswapV3Adapter),
            pool: 0xB036D38073CE3cAcbd26AB9000d3653dbb296Abe,
            fromToken: 0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b,
            toToken: 0x8e3bFf1Abf376f7a5D036cC3D85766394744dd04,
            moreInfo: abi.encode(30)
        });

        swaps1[2] = Swap({
            receiver: address(balancerV2Borrower),
            pool: 0x320eD116F8684D0865b3b60CCeC399F8b871f2Ad,
            fromToken: 0x8e3bFf1Abf376f7a5D036cC3D85766394744dd04,
            toToken: 0x4200000000000000000000000000000000000006,
            moreInfo: new bytes(0)
        });

        SwapGroup memory swapGroup1 = SwapGroup({
            baseToken: 0x4200000000000000000000000000000000000006,
            initialAmount: 10105418569764879,
            fundReceiver: address(uniswapV3Adapter),
            adapters: adapters,
            swaps: swaps1
        });

        SwapGroup[] memory swapGroups = new SwapGroup[](1);
        swapGroups[0] = swapGroup1;

        (uint256 gasEstimate, GroupResult[] memory results) = routerV1.quoteExecute({
            borrower: balancerV2Borrower,
            flashloanInfo: FlashloanInfo({tokens: tokens, amounts: amounts}),
            swapGroups: swapGroups
        });
        console2.log("gasEstimate", gasEstimate);
        console2.log("results.length:", results.length);
        for (uint256 i = 0; i < results.length; i++) {
            console2.log("profit", results[i].profit);
            for (uint256 j = 0; j < results[i].swapResults.length; j++) {
                console2.log("amountIn", results[i].swapResults[j][0]);
                console2.log("amountOut", results[i].swapResults[j][1]);
            }
        }
    }
}
