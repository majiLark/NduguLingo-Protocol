;; Ancestral Language Preservation Protocol Smart Contract - v3.0.0 (Full Feature)
;; Facilitates patronage to endangered language documentation projects, manages preservation center eligibility,
;; and provides transparent distribution of resources to verified linguistic initiatives

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CENTER-ALREADY-REGISTERED (err u101))
(define-constant ERR-CENTER-NOT-REGISTERED (err u102))
(define-constant ERR-RESOURCES-UNAVAILABLE (err u103))
(define-constant ERR-PATRONAGE-TOO-SMALL (err u104))
(define-constant ERR-PROGRAM-PAUSED (err u105))
(define-constant ERR-PATRONAGE-INVALID (err u106))
(define-constant ERR-PRESERVATION-STATUS-INVALID (err u107))
(define-constant ERR-INVALID-LINGUIST-ADDRESS (err u108))

;; Core Program Variables
(define-data-var head-linguist principal tx-sender)
(define-data-var preservation-fund uint u0)
(define-data-var program-is-active bool true)
(define-data-var patronage-minimum uint u1000000) ;; 1 STX
(define-data-var priority-mode-active bool false)

;; Data Storage
(define-map preservation-centers 
    principal 
    {
        center-active: bool,
        resources-allocated: uint,
        last-allocation-block: uint,
        documentation-status: (string-ascii 20)
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
    (and (var-get program-is-active) (not (var-get priority-mode-active)))
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

;; Validation Functions
(define-private (is-patronage-valid (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Upper limit for sanity check
    )
)

(define-private (is-documentation-status-valid (status-code (string-ascii 20)))
    (or 
        (is-eq status-code "documented")
        (is-eq status-code "in-progress")
        (is-eq status-code "endangered")
        (is-eq status-code "stable")
    )
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
                last-allocation-block: u0,
                documentation-status: "endangered"
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
                last-allocation-block: block-height,
                documentation-status: (get documentation-status center-info)
            }
        )
        (ok resource-amount))
    )
)

;; Administrative Functions
(define-public (set-patronage-minimum (new-minimum uint))
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (asserts! (is-patronage-valid new-minimum) ERR-PATRONAGE-INVALID)
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

(define-public (set-priority-mode-on)
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (var-set priority-mode-active true)
        (ok true)
    )
)

(define-public (set-priority-mode-off)
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (var-set priority-mode-active false)
        (ok true)
    )
)

(define-public (update-documentation-status (center-address principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (is-head-linguist) ERR-NOT-AUTHORIZED)
        (asserts! (is-documentation-status-valid new-status) ERR-PRESERVATION-STATUS-INVALID)
        (asserts! 
            (is-some (map-get? preservation-centers center-address)) 
            ERR-CENTER-NOT-REGISTERED
        )
        
        (let (
            (current-info (unwrap! (map-get? preservation-centers center-address) ERR-CENTER-NOT-REGISTERED))
        )
        (map-set preservation-centers
            center-address
            {
                center-active: (get center-active current-info),
                resources-allocated: (get resources-allocated current-info),
                last-allocation-block: (get last-allocation-block current-info),
                documentation-status: new-status
            }
        )
        (ok true))
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