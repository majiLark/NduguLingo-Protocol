;; Ancestral Language Preservation Protocol Smart Contract - v2.0.0 (Preservation Centers)
;; Facilitates patronage to endangered language documentation projects and manages preservation center eligibility

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CENTER-ALREADY-REGISTERED (err u101))
(define-constant ERR-CENTER-NOT-REGISTERED (err u102))
(define-constant ERR-RESOURCES-UNAVAILABLE (err u103))
(define-constant ERR-PATRONAGE-TOO-SMALL (err u104))
(define-constant ERR-PROGRAM-PAUSED (err u105))
(define-constant ERR-INVALID-LINGUIST-ADDRESS (err u108))

;; Core Program Variables
(define-data-var head-linguist principal tx-sender)
(define-data-var preservation-fund uint u0)
(define-data-var program-is-active bool true)
(define-data-var patronage-minimum uint u1000000) ;; 1 STX

;; Data Storage
(define-map preservation-centers 
    principal 
    {
        center-active: bool,
        resources-allocated: uint,
        last-allocation-block: uint
    }
)

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

(define-read-only (get-center-info (center-address principal))
    (map-get? preservation-centers center-address)
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

(define-private (can-be-head-linguist (candidate-address principal))
    (and 
        (not (is-eq candidate-address (var-get head-linguist)))
        (not (is-eq candidate-address (as-contract tx-sender)))
    )
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

;; Center Management
(define-public (register-preservation-center (center-address principal))
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? preservation-centers center-address)) ERR-CENTER-ALREADY-REGISTERED)
        
        (map-set preservation-centers 
            center-address
            {
                center-active: true,
                resources-allocated: u0,
                last-allocation-block: u0
            }
        )
        (ok true)
    )
)

(define-public (allocate-resources (center-address principal) (resource-amount uint))
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (asserts! (check-program-status) ERR-PROGRAM-PAUSED)
        (asserts! (>= (var-get preservation-fund) resource-amount) ERR-RESOURCES-UNAVAILABLE)
        (asserts! 
            (is-some (map-get? preservation-centers center-address)) 
            ERR-CENTER-NOT-REGISTERED
        )
        
        (try! (as-contract (stx-transfer? resource-amount tx-sender center-address)))
        (var-set preservation-fund (- (var-get preservation-fund) resource-amount))
        
        (let (
            (center-info (unwrap! (map-get? preservation-centers center-address) ERR-CENTER-NOT-REGISTERED))
        )
        (map-set preservation-centers
            center-address
            {
                center-active: (get center-active center-info),
                resources-allocated: (+ (get resources-allocated center-info) resource-amount),
                last-allocation-block: block-height
            }
        )
        (ok resource-amount))
    )
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
        (asserts! (can-be-head-linguist new-linguist-address) ERR-INVALID-LINGUIST-ADDRESS)
        (var-set head-linguist new-linguist-address)
        (ok true)
    )
)