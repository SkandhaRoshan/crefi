// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/MockUSDC.sol";
import "../src/StrategyRouter.sol";
import "../src/AutoPilotVault.sol";
import "../src/strategies/AaveStrategy.sol";
import "../src/strategies/IdleStrategy.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // ==============================
        // Deploy Mock USDC
        // ==============================
        MockUSDC mockUSDC = new MockUSDC();
        console.log("MockUSDC:", address(mockUSDC));

        address USDC = address(mockUSDC);

        // ==============================
        // Aave Sepolia Addresses
        // ==============================
        address AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
        address A_USDC = 0x16dA4541aD1807f4443d92D26044C1147406EB80;

        // ==============================
        // Deploy Router
        // ==============================
        StrategyRouter router = new StrategyRouter(USDC);
        console.log("Router:", address(router));

        // ==============================
        // Deploy Vault
        // ==============================
        AutoPilotVault vault = new AutoPilotVault(
            USDC,
            "AutoPilot USDC",
            "apUSDC"
        );
        console.log("Vault:", address(vault));

        // ==============================
        // Deploy Strategies
        // ==============================
        IdleStrategy idle = new IdleStrategy(USDC, address(router));
        console.log("Idle:", address(idle));

        AaveStrategy aave = new AaveStrategy(
            USDC,
            AAVE_POOL,
            A_USDC,
            address(router)
        );
        console.log("Aave:", address(aave));

        // ==============================
        // Approve strategies in Router
        // ==============================
        router.approveStrategy(address(idle), "Idle");
        router.approveStrategy(address(aave), "Aave");

        // ==============================
        // Connect Vault → Router
        // ==============================
        vault.setRouter(address(router));

        // ==============================
        // Transfer Router ownership → Vault
        // ==============================
        router.transferOwnership(address(vault));

        vm.stopBroadcast();
    }
}