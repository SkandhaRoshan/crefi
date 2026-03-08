// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VaultMath} from "./libraries/VaultMath.sol";
import {IStrategyRouter} from "./interfaces/IStrategyRouter.sol";

/// @title AutoPilot Vault
/// @notice Non-custodial ERC20 vault that tokenizes yield-bearing positions
/// @dev ERC4626-style vault controlled by StrategyRouter
contract AutoPilotVault is ERC20, ReentrancyGuard, Ownable(msg.sender) {

    using SafeERC20 for IERC20;

    /// Underlying asset (USDC)
    IERC20 public immutable asset;

    /// Strategy Router
    IStrategyRouter public router;

    /// Minimum first deposit to avoid inflation attack
    uint256 public constant MINIMUM_FIRST_DEPOSIT = VaultMath.MINIMUM_LIQUIDITY;

    /// Events
    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 assets, uint256 shares);
    event RouterUpdated(address indexed oldRouter, address indexed newRouter);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {

        require(_asset != address(0), "AutoPilotVault: zero asset");

        asset = IERC20(_asset);
    }

    /// Set router address (can only be done once)
    function setRouter(address _router) external onlyOwner {

        require(address(router) == address(0), "AutoPilotVault: router already set");
        require(_router != address(0), "AutoPilotVault: zero router");

        router = IStrategyRouter(_router);

        emit RouterUpdated(address(0), _router);
    }

    /// Deposit assets and mint vault shares
    function deposit(
        uint256 assets,
        address receiver
    )
        external
        nonReentrant
        returns (uint256 shares)
    {

        require(receiver != address(0), "AutoPilotVault: zero receiver");
        require(assets > 0, "AutoPilotVault: zero assets");

        uint256 totalAssetsBefore = totalAssets();

        shares = VaultMath.calculateMintShares(
            assets,
            totalAssetsBefore,
            totalSupply()
        );

        asset.safeTransferFrom(msg.sender, address(router), assets);

        _mint(receiver, shares);

        emit Deposited(receiver, assets, shares);
    }

    /// Withdraw assets by burning shares
    function withdraw(
        uint256 shares,
        address receiver
    )
        external
        nonReentrant
        returns (uint256 assets)
    {

        require(receiver != address(0), "AutoPilotVault: zero receiver");
        require(shares > 0, "AutoPilotVault: zero shares");
        require(shares <= balanceOf(msg.sender), "AutoPilotVault: insufficient balance");

        uint256 totalAssetsBefore = totalAssets();

        assets = VaultMath.calculateWithdrawAssets(
            shares,
            totalAssetsBefore,
            totalSupply()
        );

        _burn(msg.sender, shares);

        uint256 received = router.withdraw(assets, receiver);

        emit Withdrawn(receiver, received, shares);
    }

    /// Preview shares minted
    function previewDeposit(uint256 assets)
        public
        view
        returns (uint256)
    {
        return VaultMath.calculateMintShares(
            assets,
            totalAssets(),
            totalSupply()
        );
    }

    /// Preview assets withdrawn
    function previewWithdraw(uint256 shares)
        public
        view
        returns (uint256)
    {
        return VaultMath.calculateWithdrawAssets(
            shares,
            totalAssets(),
            totalSupply()
        );
    }

    /// Total assets managed by router
    function totalAssets()
        public
        view
        returns (uint256)
    {
        return router.totalAssets();
    }

    /// Manual rebalance trigger
    function rebalanceRouter(
        address newStrategy,
        uint256 amount,
        string calldata reason
    )
        external
        onlyOwner
    {
        router.rebalance(newStrategy, amount, reason);
    }
}