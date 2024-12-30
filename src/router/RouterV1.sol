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

// todo: 所有接口都需要加上任意字符串，防止abi泄露
contract RouterV1 is IRouter, Owned, Multicall {
    using SafeTransferLib for ERC20;

    // 暂定每次交易的钱都会转到这个地址，防止交易被复制
    address private receiver;
    address private _borrower = address(0);

    constructor(address _receiver) Owned(msg.sender) {
        receiver = _receiver;
    }

    function multicall(bytes[] calldata data)
        external
        virtual
        override(Multicall)
        onlyOwner
        returns (bytes[] memory results)
    {
        // 调用父合约中的 multicall 实现
        return this.multicall(data);
    }

    function execute(IBorrower borrower, FlashloanInfo calldata flashloanInfo, SwapGroup[] calldata swapGroups)
        external
        override
        onlyOwner
        returns (address[] memory baseTokens, uint256[] memory profits)
    {
        // 确保没有重入攻击
        require(_borrower == address(0), "ROUTER:REENTRY_ATTACK");
        // 设置borrower地址
        _borrower = address(borrower);

        baseTokens = flashloanInfo.tokens;
        uint256 baseTokenLength = baseTokens.length;
        uint256[] memory balances = new uint256[](baseTokenLength);

        for (uint256 i = 0; i < baseTokenLength;) {
            balances[i] = ERC20(baseTokens[i]).balanceOf(receiver);
            unchecked {
                ++i;
            }
        }

        // 发起闪电贷，传入套利逻辑
        bytes memory data = abi.encode(receiver, address(this), swapGroups, false);

        borrower.makeFlashloan(flashloanInfo.tokens, flashloanInfo.amounts, data);

        // 恢复borrower地址
        _borrower = address(0);

        // 计算返回结果
        bool isProfitable = false;
        profits = new uint256[](baseTokenLength);
        for (uint256 i = 0; i < baseTokenLength;) {
            uint256 balance = ERC20(baseTokens[i]).balanceOf(receiver);
            require(balance >= balances[i], "ROUTER:TOKEN_LOSS");

            uint256 profit = balance - balances[i];
            profits[i] = profit;
            if (profit > 0) {
                if (!isProfitable) {
                    isProfitable = true;
                }
            }

            unchecked {
                ++i;
            }
        }

        // 确保有利润
        require(isProfitable, "ROUTER:TX_UNPROFITABLE");
    }

    function quoteExecute(IBorrower borrower, FlashloanInfo calldata flashloanInfo, SwapGroup[] calldata swapGroups)
        external
        override
        onlyOwner
        returns (uint256 gasEstimate, GroupResult[] memory results)
    {
        uint256 gasBefore = gasleft();

        // 确保没有重入攻击
        require(_borrower == address(0), "ROUTER:REENTRY_ATTACK");
        // 设置borrower地址
        _borrower = address(borrower);

        // 进行闪电贷，在还款之前主动revert，获取结果
        bytes memory data = abi.encode(receiver, address(this), swapGroups, true);
        try borrower.makeFlashloan(flashloanInfo.tokens, flashloanInfo.amounts, data) {}
        catch (bytes memory reason) {
            _borrower = address(0);

            gasEstimate = gasBefore - gasleft();
            // parse revert reason
            return (gasEstimate, parseRevertReason(reason));
        }
    }

    function parseRevertReason(bytes memory reason) private pure returns (GroupResult[] memory results) {
        return abi.decode(reason, (GroupResult[]));
    }

    function executeGroupsByBorrower(SwapGroup[] calldata swapGroups, bool is_quote) external {
        require(msg.sender == _borrower, "ROUTER:ONLY_BY_BORROWER");

        uint256 swapGroupLength = swapGroups.length;
        GroupResult[] memory results = new GroupResult[](swapGroupLength);

        for (uint256 i = 0; i < swapGroupLength;) {
            SwapGroup calldata swapGroup = swapGroups[i];
            // 使用try-catch机制将无效的swapGroup回滚（防止亏钱）
            try this.executeGroup({borrower: _borrower, swapGroup: swapGroup, is_quote: is_quote}) returns (
                GroupResult memory result
            ) {
                results[i] = result;
            } catch {
                results[i] = GroupResult(0, new uint256[2][](swapGroup.swaps.length));
            }

            unchecked {
                ++i;
            }
        }

        if (is_quote) {
            // 故意revert，返回结果
            bytes memory encodedData = abi.encode(results);
            assembly {
                let ptr := mload(0x40) // 当前空闲内存位置
                let length := mload(encodedData) // 获取 bytes 长度
                mstore(ptr, length) // 写入长度
                revert(add(encodedData, 32), length) // 跳过长度部分，只抛出实际数据
            }
        }
    }

    function executeGroup(address borrower, SwapGroup calldata swapGroup, bool is_quote)
        external
        returns (GroupResult memory result)
    {
        // 仅允许this调用
        require(msg.sender == address(this), "ROUTER:ONLY_ROUTER");

        uint256 swapLength = swapGroup.swaps.length;
        uint256[2][] memory swapResults = new uint256[2][](swapLength);

        // 资金的起点和终点都是borrower，交易前后borrower的资金必须增加
        ERC20 baseToken = ERC20(swapGroup.baseToken);
        uint256 beforeSwapBalance = baseToken.balanceOf(borrower);
        // 初始资金转移给fundReceiver
        baseToken.safeTransferFrom(borrower, swapGroup.fundReceiver, swapGroup.initialAmount);

        // 依次执行swap操作
        for (uint256 i = 0; i < swapLength;) {
            Swap calldata swap = swapGroup.swaps[i];
            IAdapter adapter = swapGroup.adapters[i];
            (uint256 amountIn, uint256 amountOut) =
                adapter.swap(swap.receiver, swap.pool, swap.fromToken, swap.toToken, swap.moreInfo);
            swapResults[i][0] = amountIn;
            swapResults[i][1] = amountOut;

            if (amountOut == 0) {
                // 提前中断无效swap
                break;
            }

            unchecked {
                ++i;
            }
        }

        uint256 afterSwapBalance = baseToken.balanceOf(borrower);
        result.profit = int256(afterSwapBalance) - int256(beforeSwapBalance);
        result.swapResults = swapResults;

        if (!is_quote) {
            // 非查询，必须保证有利润
            require(result.profit > 0, "ROUTER:LOOP_UNPROFITABLE");
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
        require(balance > 0, "ROUTER:NO_TOKEN");
        token.safeTransfer(receiver, balance);
    }

    /**
     * @notice 提取合约中剩余的原生代币
     */
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ROUTER:NO_ETH");
        SafeTransferLib.safeTransferETH(receiver, balance);
    }
}
