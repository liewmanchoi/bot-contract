/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IBorrower} from "../interface/IBorrower.sol";
import {IRouter, SwapGroup} from "../interface/IRouter.sol";
import {IFlashLoanRecipient, IERC20} from "../interface/IFlashLoanRecipient.sol";
import {IBalancerV2Vault} from "../interface/IBalancerV2Vault.sol";

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
        IBalancerV2Vault(vault).flashLoan(this, _tokens, amounts, data);
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
        (address receiver, address router, SwapGroup[] memory swapGroups, bool is_quote) =
            abi.decode(userData, (address, address, SwapGroup[], bool));

        // 将闪电贷的资金授权给router使用
        for (uint256 i = 0; i < tokens.length;) {
            IERC20 token = tokens[i];
            token.approve(router, amounts[i]);

            unchecked {
                ++i;
            }
        }
        // 调用router
        IRouter(router).executeGroupsByBorrower({swapGroups: swapGroups, is_quote: is_quote});

        uint256 length = tokens.length;
        for (uint256 i = 0; i < length;) {
            IERC20 token = tokens[i];
            uint256 repayAmount = amounts[i] + feeAmounts[i];
            // 主动向vault还款
            token.transfer(vault, repayAmount);

            // 将剩余款项转回receiver
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                ERC20(address(token)).safeTransfer(receiver, balance);
            }

            unchecked {
                ++i;
            }
        }
    }
}
