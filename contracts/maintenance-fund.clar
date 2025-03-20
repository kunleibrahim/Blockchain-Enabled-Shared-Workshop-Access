;; Maintenance Fund Contract
;; Manages shared costs for equipment upkeep

;; Define data vars
(define-data-var total-funds uint u0)
(define-data-var monthly-fee uint u10) ;; Default monthly fee in STX

;; Define data maps
(define-map contributions
  { member: principal }
  {
    total-contributed: uint,
    last-payment: uint
  }
)

(define-map maintenance-expenses
  { expense-id: uint }
  {
    amount: uint,
    description: (string-ascii 100),
    paid-to: principal,
    paid-at: uint
  }
)

;; Counter for expense IDs
(define-data-var expense-counter uint u0)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Pay monthly fee
(define-public (pay-monthly-fee)
  (let (
    (sender tx-sender)
    (fee (var-get monthly-fee))
    (contribution (default-to { total-contributed: u0, last-payment: u0 }
                  (map-get? contributions { member: sender })))
  )
    (begin
      (try! (stx-transfer? fee sender (as-contract tx-sender)))
      (var-set total-funds (+ (var-get total-funds) fee))
      (map-set contributions
        { member: sender }
        {
          total-contributed: (+ (get total-contributed contribution) fee),
          last-payment: block-height
        }
      )
      (ok true)
    )
  )
)

;; Record a maintenance expense
(define-public (record-expense (amount uint) (description (string-ascii 100)) (recipient principal))
  (let (
    (sender tx-sender)
    (expense-id (var-get expense-counter))
    (current-funds (var-get total-funds))
  )
    (if (is-eq sender (var-get contract-owner))
      (if (>= current-funds amount)
        (begin
          (try! (as-contract (stx-transfer? amount tx-sender recipient)))
          (var-set total-funds (- current-funds amount))
          (var-set expense-counter (+ expense-id u1))
          (map-set maintenance-expenses
            { expense-id: expense-id }
            {
              amount: amount,
              description: description,
              paid-to: recipient,
              paid-at: block-height
            }
          )
          (ok expense-id)
        )
        (err u6) ;; Insufficient funds
      )
      (err u2) ;; Not authorized
    )
  )
)

;; Update monthly fee
(define-public (update-monthly-fee (new-fee uint))
  (let ((sender tx-sender))
    (if (is-eq sender (var-get contract-owner))
      (begin
        (var-set monthly-fee new-fee)
        (ok true)
      )
      (err u2) ;; Not authorized
    )
  )
)

;; Get fund balance
(define-read-only (get-fund-balance)
  (var-get total-funds)
)

;; Get member contribution history
(define-read-only (get-member-contributions (member principal))
  (map-get? contributions { member: member })
)

;; Get expense details
(define-read-only (get-expense (expense-id uint))
  (map-get? maintenance-expenses { expense-id: expense-id })
)

