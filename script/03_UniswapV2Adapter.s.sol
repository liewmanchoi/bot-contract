/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Script} from "forge-std/Script.sol";
import {UniswapV2Adapter} from "../src/adapter/UniswapV2Adapter.sol";
import {console2} from "forge-std/console2.sol";

contract UniswapV2AdapterScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UniswapV2Adapter adapter = new UniswapV2Adapter();

        vm.stopBroadcast();

        console2.log("UniswapV2Adapter:", address(adapter));
    }
}
