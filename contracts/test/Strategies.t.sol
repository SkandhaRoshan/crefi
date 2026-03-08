// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StrategyRouter.sol";
import "../src/strategies/IdleStrategy.sol";
import "./AutoPilotVault.t.sol";

contract StrategyRouterTest is Test {
    StrategyRouter public router;
    IdleStrategy public idleStrategy;
    MockUSDC public usdc;
    
    address public owner = address(0x1);
    address public cre = address(0x3);
    
    uint256 constant DEPOSIT_AMOUNT = 10_000 * 1e6;
    
    function setUp() public
    {
       usdc = new MockUSDC("USD Coin", "USDC", 6);

       vm.startPrank(owner);
       router = new StrategyRouter(address(usdc));
       router.transferOwnership(cre);
       vm.stopPrank();

       // Deploy strategy with router
       idleStrategy = new IdleStrategy(address(usdc), address(router));

       vm.prank(cre);
       router.approveStrategy(address(idleStrategy), "Idle Vault");

       usdc.mint(address(router), DEPOSIT_AMOUNT);
    }

    function testApproveStrategy() public {
        assertTrue(router.approvedStrategies(address(idleStrategy)));
        
        address[] memory strategies = router.getStrategies();
        assertEq(strategies.length, 1);
        assertEq(strategies[0], address(idleStrategy));
    }
    
    function testOnlyCRE() public {
        vm.expectRevert();
        vm.prank(address(0x99));
        router.rebalance(address(idleStrategy), DEPOSIT_AMOUNT, "");
    }
    
    function testCannotRebalanceToUnapproved() public {
        address badStrategy = address(0x999);
        
        vm.expectRevert();
        vm.prank(cre);
        router.rebalance(badStrategy, DEPOSIT_AMOUNT, "");
    }
    
    function testPause() public {
        vm.prank(cre);
        router.pause();
        
        assertTrue(router.paused());
        
        vm.expectRevert();
        vm.prank(cre);
        router.rebalance(address(idleStrategy), DEPOSIT_AMOUNT, "");
    }
}