// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

/// @title Mock Yield Strategy
/// @notice Simulates a strategy that generates artificial yield for demo purposes
contract MockYieldStrategy is IStrategy {

    using SafeERC20 for IERC20;

    /// Strategy name
    string public constant override name = "Mock Yield Strategy";

    /// Underlying asset (USDC)
    address public immutable override asset;

    /// Router controlling the strategy
    address public immutable router;

    /// Total assets managed
    uint256 private _totalAssets;

    /// Fake APY (for demo)
    uint256 public override currentApy = 800; // 8%

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

    /// Deposit funds into strategy
    function deposit(uint256 amount) external override onlyRouter {

        require(amount > 0, "zero amount");

        IERC20(asset).safeTransferFrom(router, address(this), amount);

        _totalAssets += amount;
    }

    /// Deposit all funds from router
    function depositAll() external override onlyRouter {

        uint256 balance = IERC20(asset).balanceOf(router);

        if (balance > 0) {
            IERC20(asset).safeTransferFrom(router, address(this), balance);
            _totalAssets += balance;
        }
    }

    /// Withdraw funds back to router
    function withdraw(uint256 amount)
        external
        override
        onlyRouter
        returns (uint256)
    {
        require(amount <= _totalAssets, "not enough");

        _totalAssets -= amount;

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
        total = _totalAssets;

        if (total > 0) {
            _totalAssets = 0;
            IERC20(asset).safeTransfer(router, total);
        }
    }

    /// Emergency exit
    function emergencyExit() external override onlyRouter {

        uint256 balance = _totalAssets;

        if (balance > 0) {
            _totalAssets = 0;
            IERC20(asset).safeTransfer(router, balance);
        }
    }

    /// Simulate yield growth (for demo)
    function simulateYield() external {

        uint256 yieldAmount = (_totalAssets * 5) / 100;

        _totalAssets += yieldAmount;
    }

    /// Total assets in strategy
    function totalAssets() public view override returns (uint256) {
        return _totalAssets;
    }
}