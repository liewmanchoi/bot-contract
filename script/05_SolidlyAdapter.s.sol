/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Script} from "forge-std/Script.sol";
import {SolidlyAdapter} from "../src/adapter/SolidlyAdapter.sol";
import {console2} from "forge-std/console2.sol";

contract SolidlyAdapterScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SolidlyAdapter adapter = new SolidlyAdapter();

        vm.stopBroadcast();

        console2.log("SolidlyAdapter:", address(adapter));
    }
}
