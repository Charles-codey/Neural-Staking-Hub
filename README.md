# NeuralStaking Hub

A decentralized staking protocol built on Stacks blockchain that enables users to stake STX tokens in support of AI projects and researchers while earning rewards.

## Overview

NeuralStaking Hub creates a transparent and incentivized ecosystem where community members can financially support AI development while earning passive rewards. The protocol implements performance-based multipliers to reward contributions to high-performing projects.

## Features

- **Flexible Staking**: Stake STX tokens to support specific AI projects
- **Dynamic Rewards**: Earn rewards based on stake amount, duration, and project performance
- **Performance Multipliers**: High-performing projects offer better reward rates
- **Secure Unstaking**: Built-in cooldown period protects against market manipulation
- **Pool Management**: Administrative controls for creating and managing project pools

## Smart Contract Functions

### Read-Only Functions

- `get-pool (pool-id uint)`: Retrieve information about a specific pool
- `get-stake (staker principal, pool-id uint)`: View stake details for a user
- `get-total-staked ()`: Get total amount staked across all pools
- `calculate-rewards (staker principal, pool-id uint)`: Calculate pending rewards

### Public Functions

- `create-pool (name, reward-multiplier)`: Create a new staking pool (owner only)
- `stake (pool-id, amount)`: Stake STX tokens to a pool
- `request-unstake (pool-id, amount)`: Initiate unstaking process
- `complete-unstake (pool-id)`: Complete unstaking after cooldown period
- `update-pool-multiplier (pool-id, new-multiplier)`: Adjust pool rewards (owner only)

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- STX tokens for staking

### Installation
```bash
git clone <repository-url>
cd neural-staking-hub
clarinet check
```

### Testing
```bash
clarinet test
clarinet console
```

## Usage Example
```clarity
;; Create a new pool (owner only)
(contract-call? .neural-staking create-pool "AI Research Lab" u150)

;; Stake 10 STX to pool 0
(contract-call? .neural-staking stake u0 u10000000)

;; Check rewards
(contract-call? .neural-staking calculate-rewards tx-sender u0)

;; Request unstake
(contract-call? .neural-staking request-unstake u0 u5000000)

;; Complete unstake after cooldown (144 blocks)
(contract-call? .neural-staking complete-unstake u0)
```

## Technical Details

- **Minimum Stake**: 1 STX (1,000,000 microSTX)
- **Cooldown Period**: 144 blocks (~24 hours)
- **Reward Calculation**: Based on blocks staked × amount × multiplier

## Security Considerations

- Only contract owner can create pools and adjust multipliers
- Cooldown period prevents rapid stake/unstake manipulation
- All stake amounts are validated before processing
- Contract holds staked funds securely