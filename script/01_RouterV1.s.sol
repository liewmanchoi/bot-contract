/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Script} from "forge-std/Script.sol";
import {RouterV1} from "../src/router/RouterV1.sol";
import {console2} from "forge-std/console2.sol";

contract RouterV1Script is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        RouterV1 router = new RouterV1(0xC3F0B5159e725D112C709b31E30F8e7e6af25fD4);

        vm.stopBroadcast();

        console2.log("router:", address(router));
    }
}
