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

;; Read-only functions
(define-read-only (get-pool (pool-id uint))
  (map-get? pools { pool-id: pool-id })
)

(define-read-only (get-stake (staker principal) (pool-id uint))
  (map-get? stakes { staker: staker, pool-id: pool-id })
)

(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)

(define-read-only (get-staker-stats (staker principal))
  (map-get? staker-stats { staker: staker })
)

(define-read-only (get-pool-stats (pool-id uint))
  (map-get? pool-stats { pool-id: pool-id })
)

(define-read-only (get-delegation (delegator principal) (pool-id uint))
  (map-get? delegations { delegator: delegator, pool-id: pool-id })
)

(define-read-only (get-unstake-request (staker principal) (pool-id uint))
  (map-get? unstake-requests { staker: staker, pool-id: pool-id })
)

(define-read-only (is-emergency-shutdown)
  (ok (var-get emergency-shutdown))
)

(define-read-only (get-total-rewards-paid)
  (ok (var-get total-rewards-paid))
)

(define-read-only (calculate-rewards (staker principal) (pool-id uint))
  (let
    (
      (stake-info (unwrap! (get-stake staker pool-id) err-no-stake-found))
      (pool-info (unwrap! (get-pool pool-id) err-invalid-pool))
      (blocks-staked (- stacks-block-height (get last-claim-block stake-info)))
      (base-reward (/ (* (get amount stake-info) blocks-staked) u100000))
      (multiplier (get reward-multiplier pool-info))
    )
    (ok (/ (* base-reward multiplier) u100))
  )
)