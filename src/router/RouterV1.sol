/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Multicall} from "@openzeppelin/utils/Multicall.sol";
import {IRouter} from "../interface/IRouter.sol";
import {FlashloanInfo} from "../interface/IRouter.sol";
import {SwapGroup} from "../interface/IRouter.sol";
import {Swap} from "../interface/IRouter.sol";
import {GroupResult} from "../interface/IRouter.sol";
import {IBorrower} from "../interface/IBorrower.sol";
import {IAdapter} from "../interface/IAdapter.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

// todo: 所有接口都需要加上任意字符串，防止abi泄露
contract RouterV1 is IRouter, Owned, Multicall {
    using SafeTransferLib for ERC20;

    // 暂定每次交易的钱都会转到这个地址，防止交易被复制
    address private receiver;
    address private _borrower = address(0);

    constructor(address _owner, address _receiver) Owned(_owner) {
        receiver = _receiver;
    }

    function execute(IBorrower borrower, FlashloanInfo calldata flashloanInfo, SwapGroup[] calldata swapGroups)
        external
        override
        onlyOwner
        returns (IERC20[] memory baseTokens, uint256[] memory profits)
    {
        // 确保没有重入
        require(_borrower == address(0), "reentrancy guard");
        // 设置borrower地址
        _borrower = address(borrower);

        baseTokens = flashloanInfo.tokens;
        uint256 baseTokenLength = baseTokens.length;
        uint256[] memory balances = new uint256[](baseTokenLength);

        for (uint256 i = 0; i < baseTokenLength;) {
            balances[i] = baseTokens[i].balanceOf(address(this));
            unchecked {
                ++i;
            }
        }

        // 发起闪电贷，传入套利逻辑
        bytes memory data = abi.encode(
            address(this), abi.encodePacked(this.executeGroupsByBorrower.selector, abi.encode(swapGroups, false))
        );

        borrower.makeFlashloan(flashloanInfo.tokens, flashloanInfo.amounts, data);

        // 恢复borrower地址
        _borrower = address(0);

        // 计算返回结果
        bool isProfitable = false;
        profits = new uint256[](baseTokenLength);
        for (uint256 i = 0; i < baseTokenLength;) {
            uint256 balance = baseTokens[i].balanceOf(address(this));
            require(balance >= balances[i], "NO_TOKEN_PROFIT");

            uint256 profit = balance - balances[i];
            profits[i] = profit;
            if (profit > 0) {
                if (!isProfitable) {
                    isProfitable = true;
                }

                // 转钱到receiver
                ERC20(address(baseTokens[i])).safeTransfer(receiver, profit);
            }

            unchecked {
                ++i;
            }
        }

        // 确保有利润
        require(isProfitable, "NO_OVERALL_PROFIT");
    }

    function quoteExecute(IBorrower borrower, FlashloanInfo calldata flashloanInfo, SwapGroup[] calldata swapGroups)
        external
        override
        onlyOwner
        returns (GroupResult[] memory results)
    {
        // 进行闪电贷，在还款之前主动revert，获取结果
        bytes memory data = abi.encode(
            address(this), abi.encodePacked(this.executeGroupsByBorrower.selector, abi.encode(swapGroups, true))
        );
        try borrower.makeFlashloan(flashloanInfo.tokens, flashloanInfo.amounts, data) {}
        catch (bytes memory reason) {
            // parse revert reason
            return parseRevertReason(reason);
        }
    }

    function parseRevertReason(bytes memory reason) private pure returns (GroupResult[] memory results) {
        return abi.decode(reason, (GroupResult[]));
    }

    function executeGroupsByBorrower(SwapGroup[] calldata swapGroups, bool is_quote) external {
        require(msg.sender == _borrower, "ONLY_BORROWER");

        uint256 swapGroupLength = swapGroups.length;
        GroupResult[] memory results = new GroupResult[](swapGroupLength);

        for (uint256 i = 0; i < swapGroupLength;) {
            SwapGroup calldata swapGroup = swapGroups[i];
            // 使用try-catch机制将无效的swapGroup回滚（防止亏钱）
            try this.executeGroup({swapGroup: swapGroup, is_quote: is_quote}) returns (GroupResult memory result) {
                results[i] = result;
            } catch {}

            unchecked {
                ++i;
            }
        }

        if (is_quote) {
            // 故意revert，返回结果
            bytes memory encodedData = abi.encode(results);

            // 使用内联汇编返回编码后的复杂结构
            assembly {
                let ptr := add(encodedData, 0x20) // 跳过长度字段，指向实际数据
                let size := mload(encodedData) // 获取编码数据的大小
                revert(ptr, size) // 通过 revert 返回完整的编码数据
            }
        }
    }

    function executeGroup(SwapGroup calldata swapGroup, bool is_quote)
        external
        onlyOwner
        returns (GroupResult memory result)
    {
        uint256 swapLength = swapGroup.swaps.length;
        uint256[2][] memory swapResults = new uint256[2][](swapLength);

        for (uint256 i = 0; i < swapLength;) {
            Swap calldata swap = swapGroup.swaps[i];
            IAdapter adapter = swapGroup.adapters[i];
            uint256 amountIn;
            uint256 amountOut;
            // 依次执行swap操作
            (amountIn, amountOut) = adapter.swap(swap.receiver, swap.pool, swap.fromToken, swap.toToken, swap.moreInfo);
            swapResults[i] = [amountIn, amountOut];
            if (amountOut == 0) {
                // 提前中断无效swap
                break;
            }

            unchecked {
                ++i;
            }
        }

        uint256 baseTokenAmount = swapGroup.baseToken.balanceOf(address(this));
        result.profit = int256(baseTokenAmount) - int256(swapGroup.initialAmount);
        result.swapResults = swapResults;

        if (!is_quote) {
            // 非查询，必须保证有利润
            require(result.profit > 0);
        }
    }

    function changeReceiver(address _receiver) external onlyOwner {
        receiver = _receiver;
    }

    /**
     * @notice 提取合约中剩余的ERC20代币
     */
    function withdrawToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "NO_TOKEN_BALANCE");
        token.safeTransfer(receiver, balance);
    }

    /**
     * @notice 提取合约中剩余的原生代币
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NO_ETH_BALANCE");
        SafeTransferLib.safeTransferETH(receiver, balance);
    }
}
