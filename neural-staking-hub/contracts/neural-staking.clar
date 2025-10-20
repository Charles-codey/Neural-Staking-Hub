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

;; Public functions
;; #[allow(unchecked_data)]
(define-public (create-pool (name (string-ascii 50)) (reward-multiplier uint))
  (let
    (
      (pool-id (var-get next-pool-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set pools
      { pool-id: pool-id }
      {
        name: name,
        total-staked: u0,
        reward-multiplier: reward-multiplier,
        active: true
      }
    )
    (var-set next-pool-id (+ pool-id u1))
    (ok pool-id)
  )
)

(define-public (stake (pool-id uint) (amount uint))
  (let
    (
      (pool-info (unwrap! (get-pool pool-id) err-invalid-pool))
      (existing-stake (get-stake tx-sender pool-id))
    )
    (asserts! (get active pool-info) err-invalid-pool)
    (asserts! (>= amount min-stake-amount) err-invalid-amount)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (match existing-stake
      stake-data
        (map-set stakes
          { staker: tx-sender, pool-id: pool-id }
          {
            amount: (+ (get amount stake-data) amount),
            start-block: (get start-block stake-data),
            last-claim-block: stacks-block-height
          }
        )
      (map-set stakes
        { staker: tx-sender, pool-id: pool-id }
        {
          amount: amount,
          start-block: stacks-block-height,
          last-claim-block: stacks-block-height
        }
      )
    )
    
    (map-set pools
      { pool-id: pool-id }
      (merge pool-info { total-staked: (+ (get total-staked pool-info) amount) })
    )
    
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true)
  )
)

(define-public (request-unstake (pool-id uint) (amount uint))
  (let
    (
      (stake-info (unwrap! (get-stake tx-sender pool-id) err-no-stake-found))
    )
    (asserts! (>= (get amount stake-info) amount) err-insufficient-stake)
    (asserts! (> amount u0) err-invalid-amount)
    
    (map-set unstake-requests
      { staker: tx-sender, pool-id: pool-id }
      {
        amount: amount,
        request-block: stacks-block-height
      }
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (complete-unstake (pool-id uint))
  (let
    (
      (request (unwrap! (map-get? unstake-requests { staker: tx-sender, pool-id: pool-id }) err-no-stake-found))
      (stake-info (unwrap! (get-stake tx-sender pool-id) err-no-stake-found))
      (pool-info (unwrap! (get-pool pool-id) err-invalid-pool))
      (amount (get amount request))
    )
    (asserts! (>= (- stacks-block-height (get request-block request)) cooldown-blocks) err-cooldown-active)
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (map-set stakes
      { staker: tx-sender, pool-id: pool-id }
      (merge stake-info { amount: (- (get amount stake-info) amount) })
    )
    
    (map-set pools
      { pool-id: pool-id }
      (merge pool-info { total-staked: (- (get total-staked pool-info) amount) })
    )
    
    (map-delete unstake-requests { staker: tx-sender, pool-id: pool-id })
    (var-set total-staked (- (var-get total-staked) amount))
    (ok true)
  )
)

(define-public (claim-rewards (pool-id uint))
  (let
    (
      (stake-info (unwrap! (get-stake tx-sender pool-id) err-no-stake-found))
      (pool-info (unwrap! (get-pool pool-id) err-invalid-pool))
      (rewards (unwrap! (calculate-rewards tx-sender pool-id) err-insufficient-rewards))
      (current-stats (default-to 
        { total-staked: u0, total-rewards-claimed: u0, pools-participated: u0 }
        (get-staker-stats tx-sender)
      ))
      (current-pool-stats (default-to
        { total-stakers: u0, total-rewards-distributed: u0, created-at: u0 }
        (get-pool-stats pool-id)
      ))
    )
    (asserts! (> rewards u0) err-insufficient-rewards)
    (asserts! (get active pool-info) err-pool-inactive)
    
    (try! (as-contract (stx-transfer? rewards tx-sender tx-sender)))
    
    ;; Update last claim block
    (map-set stakes
      { staker: tx-sender, pool-id: pool-id }
      (merge stake-info { last-claim-block: stacks-block-height })
    )
    
    ;; Update staker statistics
    (map-set staker-stats
      { staker: tx-sender }
      (merge current-stats { 
        total-rewards-claimed: (+ (get total-rewards-claimed current-stats) rewards)
      })
    )
    
    ;; Update pool statistics
    (map-set pool-stats
      { pool-id: pool-id }
      (merge current-pool-stats {
        total-rewards-distributed: (+ (get total-rewards-distributed current-pool-stats) rewards)
      })
    )
    
    (var-set total-rewards-paid (+ (var-get total-rewards-paid) rewards))
    (ok rewards)
  )
)

(define-public (compound-rewards (pool-id uint))
  (let
    (
      (stake-info (unwrap! (get-stake tx-sender pool-id) err-no-stake-found))
      (pool-info (unwrap! (get-pool pool-id) err-invalid-pool))
      (rewards (unwrap! (calculate-rewards tx-sender pool-id) err-insufficient-rewards))
    )
    (asserts! (> rewards u0) err-insufficient-rewards)
    (asserts! (get active pool-info) err-pool-inactive)
    
    ;; Add rewards to stake amount
    (map-set stakes
      { staker: tx-sender, pool-id: pool-id }
      (merge stake-info { 
        amount: (+ (get amount stake-info) rewards),
        last-claim-block: stacks-block-height
      })
    )
    
    ;; Update pool total
    (map-set pools
      { pool-id: pool-id }
      (merge pool-info { total-staked: (+ (get total-staked pool-info) rewards) })
    )
    
    (var-set total-staked (+ (var-get total-staked) rewards))
    (ok rewards)
  )
)