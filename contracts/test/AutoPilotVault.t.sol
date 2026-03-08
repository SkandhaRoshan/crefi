// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AutoPilotVault.sol";
import "../src/StrategyRouter.sol";
import "../src/strategies/IdleStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock USDC token
contract MockUSDC is ERC20 {
    uint8 private _decimals;
    
    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

contract AutoPilotVaultTest is Test {
    AutoPilotVault public vault;
    StrategyRouter public router;
    IdleStrategy public idleStrategy;
    MockUSDC public usdc;
    
    address public owner = address(0x1);
    address public user = address(0x2);
    address public cre = address(0x3);
    
    uint256 constant INITIAL_BALANCE = 100_000 * 1e6;
    uint256 constant DEPOSIT_AMOUNT = 10_000 * 1e6;
    
    function setUp() public 
    {
       vm.startPrank(owner);

       usdc = new MockUSDC("USD Coin", "USDC", 6);

       // Deploy router FIRST
       router = new StrategyRouter(address(usdc));

       // Deploy vault
       vault = new AutoPilotVault(address(usdc), "AutoPilot USDC", "apUSDC");

       // Set router in vault
       vault.setRouter(address(router));

       // 🔥 Transfer router ownership to vault
       router.transferOwnership(address(vault));

       vm.stopPrank();

       // Deploy strategy with router
       idleStrategy = new IdleStrategy(address(usdc), address(router));

       // Approve strategy via vault (since vault owns router now)
       vm.prank(address(vault));
       router.approveStrategy(address(idleStrategy), "Idle Vault");

       // Fund user
       usdc.mint(user, INITIAL_BALANCE);

       vm.prank(user);
       usdc.approve(address(vault), type(uint256).max);
    }
    
    function testDeposit() public {
        vm.prank(user);
        uint256 shares = vault.deposit(DEPOSIT_AMOUNT, user);
        
        uint256 expectedShares = DEPOSIT_AMOUNT - vault.MINIMUM_FIRST_DEPOSIT();
        assertEq(shares, expectedShares);
        assertEq(vault.balanceOf(user), expectedShares);
        assertEq(vault.totalAssets(), DEPOSIT_AMOUNT);
    }
    
    function testPreviewDeposit() public {
        uint256 preview = vault.previewDeposit(DEPOSIT_AMOUNT);
        
        vm.prank(user);
        uint256 actual = vault.deposit(DEPOSIT_AMOUNT, user);
        
        assertEq(actual, preview);
    }
    
    function testMultipleDeposits() public {
        vm.prank(user);
        vault.deposit(DEPOSIT_AMOUNT, user);
        
        address user2 = address(0x4);
        usdc.mint(user2, DEPOSIT_AMOUNT);
        vm.prank(user2);
        usdc.approve(address(vault), DEPOSIT_AMOUNT);
        
        vm.prank(user2);
        uint256 shares2 = vault.deposit(DEPOSIT_AMOUNT, user2);
        
        assertApproxEqAbs(shares2, DEPOSIT_AMOUNT, 1000);
    }
    
    function testCannotDepositZero() public {
        vm.expectRevert();
        vm.prank(user);
        vault.deposit(0, user);
    }
    
    function testCannotWithdrawMoreThanBalance() public {
        vm.prank(user);
        vault.deposit(DEPOSIT_AMOUNT, user);
        
        vm.expectRevert();
        vm.prank(user);
        vault.withdraw(DEPOSIT_AMOUNT + 1, user);
    }
    
    function testFirstDepositMinimum() public {
        uint256 smallDeposit = 500;
        
        vm.expectRevert();
        vm.prank(user);
        vault.deposit(smallDeposit, user);
    }
}