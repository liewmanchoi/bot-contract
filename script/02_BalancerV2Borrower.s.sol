/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Script} from "forge-std/Script.sol";
import {BalancerV2Borrower} from "../src/borrower/BalancerV2Borrower.sol";
import {console2} from "forge-std/console2.sol";

contract BalancerV2BorrowerScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // vault: 0xBA12222222228d8Ba445958a75a0704d566BF2C8
        BalancerV2Borrower borrower = new BalancerV2Borrower(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

        vm.stopBroadcast();

        console2.log("borrower:", address(borrower));
    }
}
