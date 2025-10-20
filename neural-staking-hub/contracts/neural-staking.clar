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