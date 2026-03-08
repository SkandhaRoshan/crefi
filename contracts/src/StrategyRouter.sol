// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IStrategy} from "./interfaces/IStrategy.sol";
import {IStrategyRouter} from "./interfaces/IStrategyRouter.sol";

contract StrategyRouter is
    IStrategyRouter,
    ReentrancyGuard,
    Pausable,
    Ownable
{
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;

    mapping(address => bool) public approvedStrategies;
    address[] public strategyList;

    IStrategy public override activeStrategy;

    uint256 public maxRebalanceAmount = type(uint256).max;

    // 50 = 0.5% APY difference required before switching
    uint256 public rebalanceBuffer = 50;

    event StrategyApproved(address indexed strategy, string name);
    event StrategyRevoked(address indexed strategy);

    event StrategySwitched(
        address indexed oldStrategy,
        address indexed newStrategy,
        uint256 amount,
        string reason
    );

    constructor(address _asset) Ownable(msg.sender) {
        require(_asset != address(0), "zero asset");
        asset = IERC20(_asset);
    }

    modifier onlyApprovedStrategy(address strategy) {
        require(approvedStrategies[strategy], "unapproved strategy");
        _;
    }

    // --------------------------------------------------
    // STRATEGY MANAGEMENT
    // --------------------------------------------------

    function approveStrategy(address strategy, string calldata name)
        external
        onlyOwner
    {
        require(strategy != address(0), "zero strategy");
        require(!approvedStrategies[strategy], "already approved");

        require(
            IStrategy(strategy).asset() == address(asset),
            "asset mismatch"
        );

        approvedStrategies[strategy] = true;
        strategyList.push(strategy);

        emit StrategyApproved(strategy, name);
    }

    function revokeStrategy(address strategy) external onlyOwner {
        require(approvedStrategies[strategy], "not approved");
        require(address(activeStrategy) != strategy, "cannot revoke active");

        approvedStrategies[strategy] = false;

        for (uint256 i = 0; i < strategyList.length; i++) {
            if (strategyList[i] == strategy) {
                strategyList[i] = strategyList[strategyList.length - 1];
                strategyList.pop();
                break;
            }
        }

        emit StrategyRevoked(strategy);
    }

    // --------------------------------------------------
    // DEPOSIT
    // --------------------------------------------------

    function deposit(uint256 amount)
        external
        whenNotPaused
    {
        require(amount > 0, "zero amount");

        asset.safeTransferFrom(msg.sender, address(this), amount);

        if (address(activeStrategy) != address(0)) {
            asset.forceApprove(address(activeStrategy), amount);
            activeStrategy.deposit(amount);
        }
    }

    // --------------------------------------------------
    // WITHDRAW
    // --------------------------------------------------

    function withdraw(uint256 amount, address to)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(to != address(0), "zero to");
        require(amount > 0, "zero amount");

        uint256 balance = asset.balanceOf(address(this));

        if (balance < amount && address(activeStrategy) != address(0)) {
            activeStrategy.withdraw(amount - balance);
        }

        asset.safeTransfer(to, amount);

        return amount;
    }

    // --------------------------------------------------
    // REBALANCE
    // --------------------------------------------------

    function rebalance(
        address newStrategy,
        uint256 amount,
        string memory reason
    )
        public
        onlyOwner
        nonReentrant
        whenNotPaused
        onlyApprovedStrategy(newStrategy)
    {
        require(newStrategy != address(0), "zero strategy");
        require(address(activeStrategy) != newStrategy, "already active");

        uint256 moveAmount = amount;

        if (moveAmount == 0 || moveAmount > totalAssets()) {
            moveAmount = totalAssets();
        }

        require(moveAmount > 0, "zero move");
        require(moveAmount <= maxRebalanceAmount, "exceeds max");

        address oldStrategy = address(activeStrategy);

        // APY safety buffer
        if (oldStrategy != address(0)) {

            uint256 oldApy = activeStrategy.currentApy();
            uint256 newApy = IStrategy(newStrategy).currentApy();

            require(
                newApy > oldApy + rebalanceBuffer,
                "APY improvement too small"
            );

            activeStrategy.withdraw(moveAmount);
        }

        asset.forceApprove(newStrategy, moveAmount);
        IStrategy(newStrategy).deposit(moveAmount);

        activeStrategy = IStrategy(newStrategy);

        emit StrategySwitched(oldStrategy, newStrategy, moveAmount, reason);
    }

    // --------------------------------------------------
    // AUTOMATION
    // --------------------------------------------------

    function checkUpkeep(bytes calldata)
        external
        view
        returns (bool upkeepNeeded, bytes memory)
    {
        if (strategyList.length < 2) {
            return (false, "");
        }

        uint256 bestApy = 0;
        address bestStrategy;

        for (uint i = 0; i < strategyList.length; i++) {

            uint256 apy = IStrategy(strategyList[i]).currentApy();

            if (apy > bestApy) {
                bestApy = apy;
                bestStrategy = strategyList[i];
            }
        }

        if (bestStrategy != address(activeStrategy)) {
            upkeepNeeded = true;
        }
    }

    function performUpkeep(bytes calldata) external {

        uint256 bestApy = 0;
        address bestStrategy;

        for (uint i = 0; i < strategyList.length; i++) {

            uint256 apy = IStrategy(strategyList[i]).currentApy();

            if (apy > bestApy) {
                bestApy = apy;
                bestStrategy = strategyList[i];
            }
        }

        if (bestStrategy != address(activeStrategy)) {
            rebalance(bestStrategy, 0, "Auto Yield Optimization");
        }
    }

    // --------------------------------------------------
    // VIEW FUNCTIONS
    // --------------------------------------------------

    function totalAssets() public view override returns (uint256) {

        uint256 assetsInRouter = asset.balanceOf(address(this));

        if (address(activeStrategy) != address(0)) {
            assetsInRouter += activeStrategy.totalAssets();
        }

        return assetsInRouter;
    }

    function getStrategies() external view returns (address[] memory) {
        return strategyList;
    }

    // --------------------------------------------------
    // ADMIN
    // --------------------------------------------------

    function setMaxRebalanceAmount(uint256 newMax) external onlyOwner {
        maxRebalanceAmount = newMax;
    }

    function setRebalanceBuffer(uint256 newBuffer) external onlyOwner {
        rebalanceBuffer = newBuffer;
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function paused()
        public
        view
        override(IStrategyRouter, Pausable)
        returns (bool)
    {
        return super.paused();
    }
}