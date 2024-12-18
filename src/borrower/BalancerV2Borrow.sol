/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IBorrower} from "../interface/IBorrower.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IFlashLoanRecipient} from "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import {IVault} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

contract BalancerV2Borrower is IBorrower, IFlashLoanRecipient {
    IVault private immutable vault;

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    function makeFlashloan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override {}

    function onFlashloan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override {}

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {}
}
