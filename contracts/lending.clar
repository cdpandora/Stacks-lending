;; title: lending
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant owner tx-sender)
(define-constant INTEREST_RATE u5)
(define-constant LTV u75)

;; Error Messages
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-DEPOSIT-FAILED (err u101))
(define-constant ERR-ZERO-AMOUNT (err u102))
(define-constant ERR-BURN-FAILED (err u103))

;; data vars
;;
(define-data-var totalCollateral uint u0)
(define-data-var totalDebt uint u0)

;; (define-data-var position 
;; {collateral: uint,
;; debt: uint,
;; liquidity: uint,
;; lastInterestAccrual: uint}

;; {collateral: u0,
;; debt: u0,
;; liquidity: u0,
;; lastInterestAccrual: u0})

;; data maps
;;
(define-map positions
    principal
    {
        collateral: uint,
        debt: uint,
        liquidity: uint,
        lastInterestAccrual: uint,
    }
)

;; public functions
;; Supply, borrow, withdraw, liquidate, accrueinterest, supplycollateral, withdrawcollateral
;; isPositionHealthy, pendingInterest, repay
(define-public (supply (amount uint))
    (let (
            ;; (sTokenAmount 0)
            ;; Transfer sBTC from User to our Contract
            (success (try! (contract-call? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
                transfer amount contract-caller current-contract none
            )))
            (sbtc-total-supply (unwrap!
                (contract-call?
                    'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
                    get-balance current-contract
                )
                (err u100)
            ))
        )
        ;; checks
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)

        ;; calculate lp token amount to be minted
        (if (is-eq sbtc-total-supply u0)
            ;; First time deposit
            (let ((sTokenAmount amount))
                sTokenAmount
                ;; Mint tokens to user
                (ok (contract-call? .stoken mint contract-caller sTokenAmount))
            )
            (let ((sTokenAmount (/
                    (* amount
                        (unwrap! (contract-call? .stoken get-total-supply)
                            (err u100)
                        ))
                    sbtc-total-supply
                )))
                sTokenAmount
                ;; Mint tokens to user
                (ok (contract-call? .stoken mint contract-caller sTokenAmount))
            )
        )
    )
)

(define-public (withdraw (amount uint))
    (let (
            (stTotalSup (unwrap! (contract-call? .stoken get-total-supply) (err u0)))
            (totalsbtc (unwrap!
                (contract-call?
                    'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
                    get-balance current-contract
                )
                (err u0)
            ))
            (sbtcAmount (/ (* amount totalsbtc) stTotalSup))
            (burnt (unwrap! (contract-call? .stoken burn contract-caller amount)
                ERR-BURN-FAILED
            ))
        )
        ;; Minor checks, not completing full user auth
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        (asserts! (> totalsbtc amount) ERR-ZERO-AMOUNT)

        ;; Send tokens to user and return response
        (ok (contract-call? 'SM3VDXK3WZZSA84XXFKAFAF15NNZX32CTSG82JFQ4.sbtc-token
            transfer amount current-contract contract-caller none
        ))
    )
)

;; write the accrue interest function then the borrow function
(define-private (accrue (who principal))
    (let (
            (position (unwrap! (map-get? positions tx-sender) u288))
            ;; calculate interest owed
            (interest (pendingInterest (get lastInterestAccrual position)
                (get debt position)
            ))
        )
        (map-set position (get debt position) (+ (get deb position) interest))
        (var-set totalDebt (+ (var-get totalDebt) interest))
        (ok true)
    )
)

;; calculate interest owed
(define-private (pendingInterest
        (lastInterestAccrual uint)
        (debt uint)
    )
    (let (
            (timeElasped (- stacks-block-time lastInterestAccrual))
            ;; Time based interest calc
            (interest (/ (/ (* debt INTEREST_RATE timeElasped) u31536000) u100))
        )
        (ok interest)
    )
)

;; read only functions
;;

;; private functions
;;
(define-private (auth-check)
    (ok (asserts! (is-eq contract-caller owner) ERR-OWNER-ONLY))
)
