// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IAavePool} from "../interfaces/IAavePool.sol";

contract AaveStrategy is IStrategy {
    using SafeERC20 for IERC20;

    string public constant override name = "Aave V3";

    address public immutable override asset;
    IAavePool public immutable aavePool;
    address public immutable aToken;
    address public immutable router;

    uint16 public constant REFERRAL_CODE = 0;
    uint256 public override currentApy;

    modifier onlyRouter() {
        require(msg.sender == router, "Only router");
        _;
    }

    constructor(
        address _asset,
        address _aavePool,
        address _aToken,
        address _router
    ) {
        require(_asset != address(0), "zero asset");
        require(_aavePool != address(0), "zero pool");
        require(_aToken != address(0), "zero aToken");
        require(_router != address(0), "zero router");

        asset = _asset;
        aavePool = IAavePool(_aavePool);
        aToken = _aToken;
        router = _router;

        // Approve Aave pool once for max amount
        IERC20(asset).forceApprove(_aavePool, type(uint256).max);
    }

    /// @notice Deposit funds into Aave
    /// Router must transfer USDC to this contract before calling
    function deposit(uint256 amount) external override onlyRouter {
        require(amount > 0, "zero amount");

        aavePool.supply(asset, amount, address(this), REFERRAL_CODE);

        _fetchCurrentApy();
    }

    /// @notice Withdraw specific amount back to router
    function withdraw(uint256 amount)
        external
        override
        onlyRouter
        returns (uint256 received)
    {
        received = aavePool.withdraw(asset, amount, router);
    }

    /// @notice Withdraw everything back to router
    function withdrawAll()
        external
        override
        onlyRouter
        returns (uint256 total)
    {
        total = totalAssets();
        if (total > 0) {
            aavePool.withdraw(asset, total, router);
        }
    }

    /// @notice Emergency exit
    function emergencyExit() external override onlyRouter {
        uint256 balance = totalAssets();
        if (balance > 0) {
            aavePool.withdraw(asset, balance, router);
        }
    }

    /// @notice Returns total value held in Aave (aUSDC balance)
    function totalAssets() public view override returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    /// @notice Deposits entire USDC balance held by strategy
    function depositAll() external override onlyRouter {
        uint256 balance = IERC20(asset).balanceOf(address(this));
        if (balance > 0) {
            aavePool.supply(asset, balance, address(this), REFERRAL_CODE);
            _fetchCurrentApy();
        }
    }

    /// @notice Fetch current APY from Aave reserve data
    function _fetchCurrentApy() internal {
        (
            ,
            ,
            ,
            uint128 currentLiquidityRate,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = aavePool.getReserveData(asset);

        // Aave liquidity rate is in ray (1e27)
        // Convert to percentage-like readable value
        currentApy = uint256(currentLiquidityRate) / 1e23;
    }
}