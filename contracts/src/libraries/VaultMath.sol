// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title VaultMath
/// @notice Safe math utilities used by AutoPilotVault
library VaultMath {

    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;

    /// 100% = 10000
    uint256 internal constant BASIS_POINTS = 10000;

    /// Minimum shares burned on first deposit
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;

    /// ------------------------------------------------
    /// SHARE CALCULATIONS
    /// ------------------------------------------------

    /// @notice Calculate shares minted during deposit
    function calculateMintShares(
        uint256 assets,
        uint256 totalAssets,
        uint256 totalSupply
    ) internal pure returns (uint256 shares) {

        if (totalSupply == 0 || totalAssets == 0) {

            // Prevent inflation attack
            require(
                assets > MINIMUM_LIQUIDITY,
                "VaultMath: first deposit too small"
            );

            shares = assets - MINIMUM_LIQUIDITY;

        } else {

            shares = (assets * totalSupply) / totalAssets;

            require(shares > 0, "VaultMath: shares too small");
        }
    }

    /// ------------------------------------------------
    /// WITHDRAW CALCULATIONS
    /// ------------------------------------------------

    function calculateWithdrawAssets(
        uint256 shares,
        uint256 totalAssets,
        uint256 totalSupply
    ) internal pure returns (uint256 assets) {

        require(shares <= totalSupply, "VaultMath: insufficient shares");

        assets = (shares * totalAssets) / totalSupply;

        require(assets > 0, "VaultMath: assets too small");
    }

    /// ------------------------------------------------
    /// APY HELPERS
    /// ------------------------------------------------

    /// Convert % APY → basis points
    function apyToBasisPoints(uint256 apyPercent)
        internal
        pure
        returns (uint256)
    {
        return apyPercent * 100;
    }

    /// Compare APY with buffer
    function isApyHigher(
        uint256 apy1,
        uint256 apy2,
        uint256 buffer
    ) internal pure returns (bool) {

        return apy1 > apy2 + buffer;
    }
}