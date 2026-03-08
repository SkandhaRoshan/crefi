# CREFi — Autonomous DeFi Vault using Chainlink CRE

CREFi is an autonomous DeFi vault powered by Chainlink CRE (Chainlink Runtime Environment).  
It automatically evaluates yield strategies and decides when to rebalance funds between DeFi protocols.

This project was built for a Chainlink hackathon to demonstrate how CRE can orchestrate intelligent offchain automation that interacts with onchain systems.

---

# Overview

Managing DeFi strategies manually is inefficient and risky.

Users constantly need to:
- monitor yield opportunities
- compare APYs across protocols
- withdraw and redeploy capital

CREFi automates this entire process.

A Chainlink CRE workflow continuously evaluates strategy conditions and triggers automated vault actions when better opportunities appear.

---

# How It Works

The system consists of two major parts:

1. Smart Contracts (Vault Infrastructure)
2. Chainlink CRE Workflow (Automation Layer)

The CRE workflow runs periodically and performs the following steps:

1. Fetch external market data
2. Evaluate strategy conditions
3. Decide the optimal strategy
4. Trigger vault rebalancing

This creates a fully autonomous DeFi vault.

---

# Architecture
User
│
▼
Vault Contract
│
▼
Strategy Router
│
├── Aave Strategy
└── Idle Strategy


Automation layer:


Chainlink CRE Workflow
│
▼
External Data (API)
│
▼
Strategy Decision
│
▼
Vault Rebalance


---

# Chainlink Integration

This project demonstrates how Chainlink CRE can orchestrate DeFi workflows.

### Chainlink CRE

CRE acts as the offchain execution layer that:

- runs automated workflows
- fetches external data
- evaluates strategy logic
- triggers actions onchain

### Automation (Cron Trigger)

The workflow runs automatically based on a schedule.

Example:


cron trigger → evaluate market → choose strategy → rebalance vault


### External Data

The workflow fetches real market data from an external API.

Example:
- ETH price from CoinGecko

This demonstrates CRE’s ability to integrate Web2 APIs with Web3 smart contracts.

---

# Workflow Logic

The CRE workflow performs the following logic:

1. Start automated cron execution
2. Fetch ETH price from external API
3. Evaluate strategy APYs
4. Compare available strategies
5. Select best strategy
6. Trigger vault rebalance if needed

---

# Example Simulation Output

Running the workflow simulation:


cre workflow simulate my-workflow


Example output:


🚀 CRE Autopilot started
Vault Assets: 1000000
Aave APY: 9.02
Idle APY: 3
Chosen Strategy: Aave
📈 Rebalance Triggered


This demonstrates autonomous strategy selection.

---

# Project Structure


crefi/
│
├── contracts/
│ ├── Vault.sol
│ ├── Router.sol
│ └── Strategy.sol
│
├── my-workflow/
│ └── main.ts
│
└── README.md


---

# How to Run

Install CRE CLI.

Then simulate the workflow:


cre workflow simulate my-workflow


This runs the automation logic locally.

---

# Demo

Demo Video:

(Add your YouTube video here)

---

# Future Improvements

Potential improvements for production deployment:

- integrate live APY data from DeFi APIs
- add multiple DeFi strategies
- enable cross-chain vault allocation
- integrate AI strategy optimization

---

# Why This Matters

DeFi is moving toward autonomous financial systems.

CREFi demonstrates how Chainlink CRE can power:

- autonomous vault management
- automated yield optimization
- intelligent offchain decision systems

---

# Built With

- Chainlink CRE
- Solidity
- TypeScript
- DeFi Strategy Logic

---

# Hackathon Submission

Built for the Chainlink Hackathon.