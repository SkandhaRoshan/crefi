// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Aave V3 Pool Interface
/// @notice Minimal interface for Aave V3 pool operations
interface IAavePool {
    /// @notice Supply assets to Aave
    /// @param asset Asset address
    /// @param amount Amount to supply
    /// @param onBehalfOf Address to receive aTokens
    /// @param referralCode Referral code (0 for none)
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    
    /// @notice Withdraw assets from Aave
    /// @param asset Asset address
    /// @param amount Amount to withdraw (type(uint256).max for all)
    /// @param to Address to receive assets
    /// @return withdrawn Actual amount withdrawn
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
    
    /// @notice Get reserve data including current liquidity rate
    /// @param asset Asset address
    /// @return configuration Reserve configuration
    /// @return liquidityIndex Current liquidity index
    /// @return variableBorrowIndex Current variable borrow index
    /// @return currentLiquidityRate Current liquidity rate (in ray, 1e27)
    /// @return currentVariableBorrowRate Current variable borrow rate
    /// @return currentStableBorrowRate Current stable borrow rate
    /// @return lastUpdateTimestamp Last update timestamp
    /// @return id Reserve ID
    /// @return aTokenAddress aToken address
    /// @return stableDebtTokenAddress Stable debt token address
    /// @return variableDebtTokenAddress Variable debt token address
    /// @return interestRateStrategyAddress Interest rate strategy address
    /// @return accruedToTreasury Accrued to treasury
    /// @return unbacked Unbacked amount
    /// @return isolationModeTotalDebt Isolation mode total debt
    function getReserveData(address asset) external view returns (
        uint256 configuration,
        uint128 liquidityIndex,
        uint128 variableBorrowIndex,
        uint128 currentLiquidityRate,
        uint128 currentVariableBorrowRate,
        uint128 currentStableBorrowRate,
        uint40 lastUpdateTimestamp,
        uint16 id,
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress,
        uint128 accruedToTreasury,
        uint128 unbacked,
        uint128 isolationModeTotalDebt
    );
}