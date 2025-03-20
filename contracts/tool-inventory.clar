;; Tool Inventory Contract
;; Manages the inventory of tools available in the workshop

;; Define data maps
(define-map tools
  { tool-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    available: bool,
    requires-training: bool
  }
)

;; Counter for tool IDs
(define-data-var tool-counter uint u0)

;; Add a new tool to the inventory
(define-public (add-tool (name (string-ascii 50)) (description (string-ascii 200)) (requires-training bool))
  (let ((tool-id (var-get tool-counter)))
    (begin
      (var-set tool-counter (+ tool-id u1))
      (map-set tools { tool-id: tool-id } { name: name, description: description, available: true, requires-training: requires-training })
      (ok tool-id)
    )
  )
)

;; Update tool availability
(define-public (set-tool-availability (tool-id uint) (available bool))
  (let ((tool (map-get? tools { tool-id: tool-id })))
    (if (is-some tool)
      (begin
        (map-set tools
          { tool-id: tool-id }
          (merge (unwrap-panic tool) { available: available })
        )
        (ok true)
      )
      (err u1) ;; Tool not found
    )
  )
)

;; Get tool details
(define-read-only (get-tool (tool-id uint))
  (map-get? tools { tool-id: tool-id })
)

;; Get total number of tools
(define-read-only (get-tool-count)
  (var-get tool-counter)
)

