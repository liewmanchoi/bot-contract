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
import {BalancerV2Borrower} from "../src/borrower/BalancerV2Borrower.sol";
import {RouterV1} from "../src/router/RouterV1.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract OverallTest is Test {
    UniswapV2Adapter uniswapV2Adapter;
    UniswapV3Adapter uniswapV3Adapter;
    SolidlyAdapter solidlyAdapter;
    BalancerV2Borrower balancerV2Borrower;
    RouterV1 routerV1;

    function setUp() external {
        string memory BASE_RPC_URL = vm.envString("BASE_RPC_URL");
        vm.createSelectFork(BASE_RPC_URL, 24028115);

        // 部署合约
        uniswapV2Adapter = new UniswapV2Adapter();
        console2.log("uniswapV2Adapter", address(uniswapV2Adapter));

        uniswapV3Adapter = new UniswapV3Adapter();
        console2.log("uniswapV3Adapter", address(uniswapV3Adapter));

        solidlyAdapter = new SolidlyAdapter();
        console2.log("solidlyAdapter", address(solidlyAdapter));

        balancerV2Borrower = new BalancerV2Borrower(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        console2.log("balancerV2Borrower", address(balancerV2Borrower));

        routerV1 = new RouterV1(0xC3F0B5159e725D112C709b31E30F8e7e6af25fD4);
        console2.log("routerV1", address(routerV1));
    }

    function test_execute() external {
        address[] memory tokens = new address[](1);
        tokens[0] = 0x4200000000000000000000000000000000000006;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 209082130110312710;

        IAdapter[] memory adapters = new IAdapter[](2);
        adapters[0] = uniswapV2Adapter;
        adapters[1] = uniswapV3Adapter;

        Swap[] memory swaps = new Swap[](2);
        swaps[0] = Swap({
            receiver: 0x01204Ea51961591236000cc709Cd79dB16069369,
            pool: 0xe7Cc983d87777b51137e6cf88D7a054dA0c9dB76,
            fromToken: 0x4200000000000000000000000000000000000006,
            toToken: 0xEB319ea07cA67a9D96d57DE91503F85E4fe386B3,
            moreInfo: hex"000000000000000000000000000000000000000000000000000000000000001e"
        });
        swaps[1] = Swap({
            receiver: 0x006362D43e228A8F7e0EA527455DEe7e2755567a,
            pool: 0x01204Ea51961591236000cc709Cd79dB16069369,
            fromToken: 0xEB319ea07cA67a9D96d57DE91503F85E4fe386B3,
            toToken: 0x4200000000000000000000000000000000000006,
            moreInfo: hex"000000000000000000000000000000000000000000000000000000000000001e"
        });

        SwapGroup memory swapGroup = SwapGroup({
            baseToken: 0x4200000000000000000000000000000000000006,
            initialAmount: 63512644790154384,
            fundReceiver: 0xe7Cc983d87777b51137e6cf88D7a054dA0c9dB76,
            adapters: adapters,
            swaps: swaps
        });
        SwapGroup[] memory swapGroups = new SwapGroup[](1);
        swapGroups[0] = swapGroup;

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
        amounts[0] = 209082130110312710;

        IAdapter[] memory adapters = new IAdapter[](2);
        adapters[0] = uniswapV2Adapter;
        adapters[1] = uniswapV3Adapter;

        Swap[] memory swaps = new Swap[](2);
        swaps[0] = Swap({
            receiver: 0x01204Ea51961591236000cc709Cd79dB16069369,
            pool: 0xe7Cc983d87777b51137e6cf88D7a054dA0c9dB76,
            fromToken: 0x4200000000000000000000000000000000000006,
            toToken: 0xEB319ea07cA67a9D96d57DE91503F85E4fe386B3,
            moreInfo: hex"000000000000000000000000000000000000000000000000000000000000001e"
        });
        swaps[1] = Swap({
            receiver: 0x006362D43e228A8F7e0EA527455DEe7e2755567a,
            pool: 0x01204Ea51961591236000cc709Cd79dB16069369,
            fromToken: 0xEB319ea07cA67a9D96d57DE91503F85E4fe386B3,
            toToken: 0x4200000000000000000000000000000000000006,
            moreInfo: hex"000000000000000000000000000000000000000000000000000000000000001e"
        });

        SwapGroup memory swapGroup = SwapGroup({
            baseToken: 0x4200000000000000000000000000000000000006,
            initialAmount: 63512644790154384,
            fundReceiver: 0xe7Cc983d87777b51137e6cf88D7a054dA0c9dB76,
            adapters: adapters,
            swaps: swaps
        });
        SwapGroup[] memory swapGroups = new SwapGroup[](1);
        swapGroups[0] = swapGroup;

        GroupResult[] memory results = routerV1.quoteExecute({
            borrower: balancerV2Borrower,
            flashloanInfo: FlashloanInfo({tokens: tokens, amounts: amounts}),
            swapGroups: swapGroups
        });
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
