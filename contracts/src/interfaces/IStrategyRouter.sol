// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "./IStrategy.sol";

/// @title Strategy Router Interface
/// @notice Router that manages strategy allocation
interface IStrategyRouter {

    /// @notice Rebalance funds into a new strategy
    /// @param newStrategy Address of new strategy
    /// @param amount Amount to move
    /// @param reason Reason provided by CRE automation
    function rebalance(
        address newStrategy,
        uint256 amount,
        string calldata reason
    ) external;

    /// @notice Returns currently active strategy
    function activeStrategy() external view returns (IStrategy);

    /// @notice Total assets managed by router
    function totalAssets() external view returns (uint256);

    /// @notice Withdraw assets for vault/user
    function withdraw(
        uint256 amount,
        address to
    ) external returns (uint256);

    /// @notice Pause system
    function pause() external;

    /// @notice Unpause system
    function unpause() external;

    /// @notice Check pause state
    function paused() external view returns (bool);
}