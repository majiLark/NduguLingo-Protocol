;; Ancestral Language Preservation Protocol Smart Contract - v1.0.0 (Basic Patronage)
;; Facilitates basic patronage to endangered language documentation projects

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PATRONAGE-TOO-SMALL (err u104))
(define-constant ERR-PROGRAM-PAUSED (err u105))

;; Core Program Variables
(define-data-var head-linguist principal tx-sender)
(define-data-var preservation-fund uint u0)
(define-data-var program-is-active bool true)
(define-data-var patronage-minimum uint u1000000) ;; 1 STX

;; Data Storage
(define-map patron-registry
    principal
    {
        total-contributions: uint,
        latest-contribution-block: uint
    }
)

;; Read-only Functions
(define-read-only (get-head-linguist)
    (var-get head-linguist)
)

(define-read-only (get-preservation-fund)
    (var-get preservation-fund)
)

(define-read-only (get-patron-info (patron-address principal))
    (map-get? patron-registry patron-address)
)

(define-read-only (check-program-status)
    (var-get program-is-active)
)

;; Helper Functions
(define-private (is-head-linguist)
    (is-eq tx-sender (var-get head-linguist))
)

(define-private (record-patronage (patron-address principal) (patronage-amount uint))
    (let (
        (patron-record (default-to 
            { total-contributions: u0, latest-contribution-block: u0 } 
            (map-get? patron-registry patron-address)
        ))
    )
    (map-set patron-registry
        patron-address
        {
            total-contributions: (+ (get total-contributions patron-record) patronage-amount),
            latest-contribution-block: block-height
        }
    ))
)

;; Public Functions
(define-public (support-language-preservation)
    (let (
        (patronage-amount (stx-get-balance tx-sender))
    )
    (asserts! (>= patronage-amount (var-get patronage-minimum)) ERR-PATRONAGE-TOO-SMALL)
    (asserts! (check-program-status) ERR-PROGRAM-PAUSED)
    
    (try! (stx-transfer? patronage-amount tx-sender (as-contract tx-sender)))
    (var-set preservation-fund (+ (var-get preservation-fund) patronage-amount))
    (record-patronage tx-sender patronage-amount)
    (ok patronage-amount))
)

;; Administrative Functions
(define-public (set-patronage-minimum (new-minimum uint))
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (var-set patronage-minimum new-minimum)
        (ok true)
    )
)

(define-public (toggle-program-status)
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (var-set program-is-active (not (var-get program-is-active)))
        (ok true)
    )
)

;; Governance Function
(define-public (change-head-linguist (new-linguist-address principal))
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq new-linguist-address (var-get head-linguist))) ERR-NOT-AUTHORIZED)
        (var-set head-linguist new-linguist-address)
        (ok true)
    )
)