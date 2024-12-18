/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IFlashLoanRecipient} from "./IFlashLoanRecipient.sol";

interface IBalancerV2Vault {
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}
