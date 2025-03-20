;; Usage Scheduling Contract
;; Manages reservations for tools in the workshop

;; Define data maps
(define-map reservations
  { tool-id: uint, day: uint }
  {
    reserver: principal,
    start-time: uint,
    end-time: uint
  }
)

;; Contract dependencies
(define-constant tool-inventory-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.tool-inventory)
(define-constant member-verification-contract 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.member-verification)

;; Reserve a tool
(define-public (reserve-tool (tool-id uint) (day uint) (start-time uint) (end-time uint))
  (let (
    (sender tx-sender)
    (is-member (contract-call? member-verification-contract is-active-member sender))
    (tool (contract-call? tool-inventory-contract get-tool tool-id))
    (requires-training (default-to false (get requires-training tool)))
  )
    (if (and is-member (is-some tool))
      (if (and
            (< start-time end-time)
            (is-time-available tool-id day start-time end-time)
            (or
              (not requires-training)
              (contract-call? member-verification-contract is-certified sender tool-id)
            )
          )
        (begin
          (map-set reservations
            { tool-id: tool-id, day: day }
            { reserver: sender, start-time: start-time, end-time: end-time }
          )
          (ok true)
        )
        (err u3) ;; Invalid reservation parameters
      )
      (err u4) ;; Not a member or tool doesn't exist
    )
  )
)

;; Cancel a reservation
(define-public (cancel-reservation (tool-id uint) (day uint))
  (let (
    (sender tx-sender)
    (reservation (map-get? reservations { tool-id: tool-id, day: day }))
  )
    (if (and
          (is-some reservation)
          (is-eq sender (get reserver (unwrap-panic reservation)))
        )
      (begin
        (map-delete reservations { tool-id: tool-id, day: day })
        (ok true)
      )
      (err u5) ;; Not your reservation or doesn't exist
    )
  )
)

;; Check if a time slot is available
(define-read-only (is-time-available (tool-id uint) (day uint) (start-time uint) (end-time uint))
  (let ((reservation (map-get? reservations { tool-id: tool-id, day: day })))
    (if (is-some reservation)
      (let (
        (existing-start (get start-time (unwrap-panic reservation)))
        (existing-end (get end-time (unwrap-panic reservation)))
      )
        (or
          (>= start-time existing-end)
          (<= end-time existing-start)
        )
      )
      true ;; No existing reservation
    )
  )
)

;; Get reservation details
(define-read-only (get-reservation (tool-id uint) (day uint))
  (map-get? reservations { tool-id: tool-id, day: day })
)

