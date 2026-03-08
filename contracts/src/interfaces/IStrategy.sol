// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Strategy Interface
/// @notice Standard interface for all yield strategies
interface IStrategy {

    /// @notice Returns strategy name
    function name() external view returns (string memory);

    /// @notice Returns asset used by strategy
    function asset() external view returns (address);

    /// @notice Deposit assets
    function deposit(uint256 amount) external;

    /// @notice Deposit all assets held by caller
    function depositAll() external;

    /// @notice Withdraw specific amount
    function withdraw(uint256 amount) external returns (uint256);

    /// @notice Withdraw everything
    function withdrawAll() external returns (uint256);

    /// @notice Total assets inside strategy
    function totalAssets() external view returns (uint256);

    /// @notice Current APY for strategy (used by automation)
    function currentApy() external view returns (uint256);

    /// @notice Emergency exit for safety
    function emergencyExit() external;
}