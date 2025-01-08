/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Script} from "forge-std/Script.sol";
import {PancakeV3Adapter} from "../src/adapter/PancakeV3Adapter.sol";
import {console2} from "forge-std/console2.sol";

contract PancakeV3AdapterScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        PancakeV3Adapter adapter = new PancakeV3Adapter();

        vm.stopBroadcast();

        console2.log("PancakeV3Adapter:", address(adapter));
    }
}
