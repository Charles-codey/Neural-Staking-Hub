;; NeuralStaking Hub - Stake STX to support AI projects and earn rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-pool (err u101))
(define-constant err-insufficient-stake (err u102))
(define-constant err-no-stake-found (err u103))
(define-constant err-cooldown-active (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-pool-inactive (err u106))
(define-constant err-insufficient-rewards (err u107))
(define-constant err-already-delegated (err u108))
(define-constant err-not-delegated (err u109))
(define-constant err-self-delegation (err u110))

;; Minimum stake amount in microSTX
(define-constant min-stake-amount u1000000)

;; Cooldown period in blocks
(define-constant cooldown-blocks u144)

;; Data Variables
(define-data-var next-pool-id uint u0)
(define-data-var total-staked uint u0)
(define-data-var total-rewards-paid uint u0)
(define-data-var emergency-shutdown bool false)

;; Data Maps
(define-map pools
  { pool-id: uint }
  {
    name: (string-ascii 50),
    total-staked: uint,
    reward-multiplier: uint,
    active: bool
  }
)

(define-map stakes
  { staker: principal, pool-id: uint }
  {
    amount: uint,
    start-block: uint,
    last-claim-block: uint
  }
)

(define-map unstake-requests
  { staker: principal, pool-id: uint }
  {
    amount: uint,
    request-block: uint
  }
)

(define-map staker-stats
  { staker: principal }
  {
    total-staked: uint,
    total-rewards-claimed: uint,
    pools-participated: uint
  }
)

(define-map delegations
  { delegator: principal, pool-id: uint }
  {
    delegate: principal,
    active: bool
  }
)

(define-map pool-stats
  { pool-id: uint }
  {
    total-stakers: uint,
    total-rewards-distributed: uint,
    created-at: uint
  }
)