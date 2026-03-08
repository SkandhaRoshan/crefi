// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

/// @title Idle Strategy
/// @notice Safe strategy that simply holds funds (no yield)
contract IdleStrategy is IStrategy {

    using SafeERC20 for IERC20;

    /// Strategy name
    string public constant override name = "Idle Strategy";

    /// Underlying asset (USDC)
    address public immutable override asset;

    /// Router controlling deposits/withdrawals
    address public immutable router;

    /// Fixed APY for demo (3%)
    uint256 public constant FIXED_APY = 300;

    /// Current APY
    uint256 public override currentApy = FIXED_APY;

    modifier onlyRouter() {
        require(msg.sender == router, "Only router");
        _;
    }

    constructor(address _asset, address _router) {
        require(_asset != address(0), "zero asset");
        require(_router != address(0), "zero router");

        asset = _asset;
        router = _router;
    }

    /// Router deposits funds here
    function deposit(uint256 amount) external override onlyRouter {
        require(amount > 0, "zero amount");

        IERC20(asset).safeTransferFrom(router, address(this), amount);
    }

    /// Router deposits all available funds
    function depositAll() external override onlyRouter {
        uint256 balance = IERC20(asset).balanceOf(router);

        if (balance > 0) {
            IERC20(asset).safeTransferFrom(router, address(this), balance);
        }
    }

    /// Withdraw funds back to router
    function withdraw(uint256 amount)
        external
        override
        onlyRouter
        returns (uint256)
    {
        require(amount > 0, "zero amount");

        IERC20(asset).safeTransfer(router, amount);

        return amount;
    }

    /// Withdraw everything
    function withdrawAll()
        external
        override
        onlyRouter
        returns (uint256 total)
    {
        total = IERC20(asset).balanceOf(address(this));

        if (total > 0) {
            IERC20(asset).safeTransfer(router, total);
        }
    }

    /// Emergency exit
    function emergencyExit() external override onlyRouter {

        uint256 balance = IERC20(asset).balanceOf(address(this));

        if (balance > 0) {
            IERC20(asset).safeTransfer(router, balance);
        }
    }

    /// Total assets held
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }
}