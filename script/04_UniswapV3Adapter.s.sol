/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Script} from "forge-std/Script.sol";
import {UniswapV3Adapter} from "../src/adapter/UniswapV3Adapter.sol";
import {console2} from "forge-std/console2.sol";

contract UniswapV3AdapterScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UniswapV3Adapter adapter = new UniswapV3Adapter();

        vm.stopBroadcast();

        console2.log("UniswapV3Adapter:", address(adapter));
    }
}
