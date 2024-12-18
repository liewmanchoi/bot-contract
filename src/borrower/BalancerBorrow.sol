/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IBorrower} from "../interface/IBorrower.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract BalancerBorrower is IBorrower {
    address private immutable vault;

    constructor(address _vault) {
        vault = _vault;
    }

    function makeFlashloan(IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external {}

    // 回调函数注意权限控制
    function onFlashloan(IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external {}
}
