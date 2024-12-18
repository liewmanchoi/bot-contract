/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBorrower} from "../interface/IBorrower.sol";
import {IFlashLoanRecipient, IERC20} from "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import {IVault} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";

contract BalancerV2Borrower is IFlashLoanRecipient, IBorrower {
    using SafeTransferLib for ERC20;

    address private immutable vault;

    constructor(address _vault) {
        vault = _vault;
    }

    function makeFlashloan(address[] calldata tokens, uint256[] calldata amounts, bytes calldata data)
        external
        override
    {
        IERC20[] memory _tokens = new IERC20[](tokens.length);
        for (uint256 i = 0; i < tokens.length;) {
            _tokens[i] = IERC20(tokens[i]);

            unchecked {
                ++i;
            }
        }
        IVault(vault).flashLoan(this, _tokens, amounts, data);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        // 注意权限控制
        require(msg.sender == vault, "NOT_VAULT");

        // 调用router业务逻辑
        (address router, bytes memory data) = abi.decode(userData, (address, bytes));

        // 调用router
        (bool success,) = address(router).call(data);
        require(success, "ROUTER_CALL_FAILED");

        uint256 length = tokens.length;
        for (uint256 i = 0; i < length;) {
            IERC20 token = tokens[i];
            uint256 repayAmount = amounts[i] + feeAmounts[i];
            // 主动向vault还款
            token.transfer(vault, repayAmount);

            // 将剩余款项转回router
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                ERC20(address(token)).safeTransfer(router, balance);
            }

            unchecked {
                ++i;
            }
        }
    }
}
