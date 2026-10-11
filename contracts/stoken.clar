;; title: stoken
;; version:
;; summary:
;; description:

;; traits
;;
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; token definitions
;;
(define-fungible-token sToken u1000000000)

;; constants
;;
(define-constant owner tx-sender)

;; data vars
;;

;; data maps
;;

;; public functions
;;
;;;;  Transfer from the caller to a new principal
(define-public (transfer
        (amount uint)
        (sender principal)
        (recipient principal)
        (memo (optional (buff 34)))
    )
    (let ((balance (unwrap! (get-balance sender) (err u200))))
        (begin
            (asserts! (> balance u0) (err u101))
            (asserts! (> amount u0) (err u101))
            (asserts! (is-eq sender contract-caller) (err u100))

            (try! (ft-transfer? sToken amount sender recipient))
            (match memo
                sender-text (print sender-text)
                0x
            )
            (ok true)
        )
    )
)
(define-public (burn
        (recipient principal)
        (amount uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-caller) (err 200))
        ;; burn tokens from sender
        (ok (ft-burn? sToken amount recipient))
    )
)

(define-public (mint
        (recipient principal)
        (amount uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-caller) (err 200))
        ;; mint tokens to recipient
        (ok (ft-mint? sToken amount recipient))
    )
)

;; read only functions
(define-read-only (get-name)
    (ok "sToken")
)

;;;;  the ticker symbol, or empty if none
(define-read-only (get-symbol)
    (ok "sT")
)

;;;;  the number of decimals used, e.g. 6 would mean 1_000_000 represents 1 token
(define-read-only (get-decimals)
    (ok u6)
)

;;;;  the balance of the passed principal
(define-read-only (get-balance (acc principal))
    (ok (ft-get-balance sToken acc))
)

;;;;  the current total supply (which does not need to be a constant)
(define-read-only (get-total-supply)
    (ok (ft-get-supply sToken))
)

;;;;  an optional URI that represents metadata of this token
;; (get-token-uri () (response (optional (string-utf8 256)) uint))
(define-read-only (get-token-uri)
    (ok none)
)

;; private functions
;;
