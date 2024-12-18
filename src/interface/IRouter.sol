/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
pragma abicoder v2;

import {IAdapter} from "./IAdapter.sol";
import {IBorrower} from "./IBorrower.sol";

struct Swap {
    address receiver;
    address pool;
    address fromToken;
    address toToken;
    bytes moreInfo;
}

struct FlashloanInfo {
    address[] tokens;
    uint256[] amounts;
}

struct SwapGroup {
    address baseToken;
    uint256 initialAmount;
    IAdapter[] adapters;
    Swap[] swaps;
}

struct GroupResult {
    int256 profit;
    // 实际执行的交易金额（长度必须与SwapGroup.swaps一致, [amountIn, amountOut]）
    uint256[2][] swapResults;
}

interface IRouter {
    function execute(IBorrower borrower, FlashloanInfo calldata flashloanInfo, SwapGroup[] calldata swapGroups)
        external
        returns (address[] memory baseTokens, uint256[] memory profits);

    function quoteExecute(IBorrower borrower, FlashloanInfo calldata flashloanInfo, SwapGroup[] calldata swapGroups)
        external
        returns (GroupResult[] memory results);

    function executeGroupsByBorrower(SwapGroup[] calldata swapGroups, bool is_quote) external;
}
