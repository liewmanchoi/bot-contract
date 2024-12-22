// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {SolidlyAdapter} from "../src/adapter/SolidlyAdapter.sol";
import {UniswapV2Adapter} from "../src/adapter/UniswapV2Adapter.sol";
import {UniswapV3Adapter} from "../src/adapter/UniswapV3Adapter.sol";
import {BalancerV2Borrower} from "../src/borrower/BalancerV2Borrower.sol";
import {RouterV1} from "../src/router/RouterV1.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract OverallTest is Test {
    function setUp() external {
        // 部署合约
        address uniswapV2Adapter = makeAddr("UniswapV2Adapter");
        deployCodeTo("UniswapV2Adapter.sol", uniswapV2Adapter);
        console2.log("uniswapV2Adapter", uniswapV2Adapter);

        address uniswapV3Adapter = makeAddr("UniswapV3Adapter");
        deployCodeTo("UniswapV3Adapter.sol", uniswapV3Adapter);
        console2.log("uniswapV3Adapter", uniswapV3Adapter);

        address solidlyAdapter = makeAddr("SolidlyAdapter");
        deployCodeTo("SolidlyAdapter.sol", solidlyAdapter);
        console2.log("solidlyAdapter", solidlyAdapter);

        address balancerV2Borrower = makeAddr("BalancerV2Borrower");
        deployCodeTo(
            "BalancerV2Borrower.sol", abi.encode(0xBA12222222228d8Ba445958a75a0704d566BF2C8), balancerV2Borrower
        );
        console2.log("balancerV2Borrower", balancerV2Borrower);

        address routerV1 = makeAddr("RouterV1");
        deployCodeTo("RouterV1.sol", abi.encode(0xC3F0B5159e725D112C709b31E30F8e7e6af25fD4), routerV1);
        console2.log("routerV1", routerV1);
    }

    function test() external {}
}
