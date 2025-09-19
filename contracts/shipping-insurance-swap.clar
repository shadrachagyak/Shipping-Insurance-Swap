(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSURANCE-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-SWAPPED (err u102))
(define-constant ERR-CANNOT-SWAP-OWN (err u103))
(define-constant ERR-SWAP-NOT-FOUND (err u104))
(define-constant ERR-INVALID-AMOUNT (err u105))
(define-constant ERR-INSUFFICIENT-BALANCE (err u106))

(define-data-var next-insurance-id uint u1)
(define-data-var next-swap-id uint u1)

(define-map insurance-contracts
  { insurance-id: uint }
  {
    owner: principal,
    cargo-type: (string-ascii 50),
    value: uint,
    premium: uint,
    destination: (string-ascii 100),
    expiry-block: uint,
    is-active: bool
  }
)

(define-map swap-proposals
  { swap-id: uint }
  {
    proposer: principal,
    proposer-insurance-id: uint,
    target-insurance-id: uint,
    additional-payment: uint,
    expiry-block: uint,
    is-active: bool
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-private (get-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-private (set-balance (user principal) (new-balance uint))
  (begin
    (map-set user-balances { user: user } { balance: new-balance })
    true
  )
)

(define-public (deposit (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (if (> amount u0)
      (match (stx-transfer? amount tx-sender (as-contract tx-sender))
        success (begin
          (set-balance tx-sender (+ current-balance amount))
          (ok amount)
        )
        error (err ERR-INSUFFICIENT-BALANCE)
      )
      (err ERR-INVALID-AMOUNT)
    )
  )
)

(define-public (withdraw (amount uint))
  (let ((current-balance (get-balance tx-sender)))
    (if (and (> amount u0) (>= current-balance amount))
      (match (as-contract (stx-transfer? amount tx-sender tx-sender))
        success (begin
          (set-balance tx-sender (- current-balance amount))
          (ok amount)
        )
        error (err ERR-INSUFFICIENT-BALANCE)
      )
      (err ERR-INSUFFICIENT-BALANCE)
    )
  )
)

(define-public (create-insurance-contract (cargo-type (string-ascii 50)) (value uint) (premium uint) (destination (string-ascii 100)) (duration-blocks uint))
  (let ((insurance-id (var-get next-insurance-id)))
    (if (> premium u0)
      (begin
        (map-set insurance-contracts
          { insurance-id: insurance-id }
          {
            owner: tx-sender,
            cargo-type: cargo-type,
            value: value,
            premium: premium,
            destination: destination,
            expiry-block: (+ stacks-block-height duration-blocks),
            is-active: true
          }
        )
        (var-set next-insurance-id (+ insurance-id u1))
        (ok insurance-id)
      )
      (err ERR-INVALID-AMOUNT)
    )
  )
)

(define-public (propose-swap (my-insurance-id uint) (target-insurance-id uint) (additional-payment uint) (duration-blocks uint))
  (let (
    (my-insurance (unwrap! (map-get? insurance-contracts { insurance-id: my-insurance-id }) (err ERR-INSURANCE-NOT-FOUND)))
    (target-insurance (unwrap! (map-get? insurance-contracts { insurance-id: target-insurance-id }) (err ERR-INSURANCE-NOT-FOUND)))
    (swap-id (var-get next-swap-id))
    (my-balance (get-balance tx-sender))
  )
    (if (and 
          (is-eq (get owner my-insurance) tx-sender)
          (get is-active my-insurance)
          (get is-active target-insurance)
          (not (is-eq tx-sender (get owner target-insurance)))
          (>= my-balance additional-payment)
        )
      (begin
        (if (> additional-payment u0)
          (begin
            (set-balance tx-sender (- my-balance additional-payment))
            true
          )
          true
        )
        (map-set swap-proposals
          { swap-id: swap-id }
          {
            proposer: tx-sender,
            proposer-insurance-id: my-insurance-id,
            target-insurance-id: target-insurance-id,
            additional-payment: additional-payment,
            expiry-block: (+ stacks-block-height duration-blocks),
            is-active: true
          }
        )
        (var-set next-swap-id (+ swap-id u1))
        (ok swap-id)
      )
      (err ERR-NOT-AUTHORIZED)
    )
  )
)

(define-public (accept-swap (swap-id uint))
  (let (
    (swap-proposal (unwrap! (map-get? swap-proposals { swap-id: swap-id }) (err ERR-SWAP-NOT-FOUND)))
    (proposer-insurance (unwrap! (map-get? insurance-contracts { insurance-id: (get proposer-insurance-id swap-proposal) }) (err ERR-INSURANCE-NOT-FOUND)))
    (target-insurance (unwrap! (map-get? insurance-contracts { insurance-id: (get target-insurance-id swap-proposal) }) (err ERR-INSURANCE-NOT-FOUND)))
  )
    (if (and
          (is-eq (get owner target-insurance) tx-sender)
          (get is-active swap-proposal)
          (get is-active proposer-insurance)
          (get is-active target-insurance)
          (<= stacks-block-height (get expiry-block swap-proposal))
        )
      (begin
        (map-set insurance-contracts
          { insurance-id: (get proposer-insurance-id swap-proposal) }
          (merge proposer-insurance { owner: tx-sender })
        )
        (map-set insurance-contracts
          { insurance-id: (get target-insurance-id swap-proposal) }
          (merge target-insurance { owner: (get proposer swap-proposal) })
        )
        (if (> (get additional-payment swap-proposal) u0)
          (begin
            (set-balance tx-sender (+ (get-balance tx-sender) (get additional-payment swap-proposal)))
            true
          )
          true
        )
        (map-set swap-proposals
          { swap-id: swap-id }
          (merge swap-proposal { is-active: false })
        )
        (ok true)
      )
      (err ERR-NOT-AUTHORIZED)
    )
  )
)

(define-public (cancel-swap (swap-id uint))
  (let ((swap-proposal (unwrap! (map-get? swap-proposals { swap-id: swap-id }) (err ERR-SWAP-NOT-FOUND))))
    (if (and
          (is-eq (get proposer swap-proposal) tx-sender)
          (get is-active swap-proposal)
        )
      (begin
        (if (> (get additional-payment swap-proposal) u0)
          (begin
            (set-balance tx-sender (+ (get-balance tx-sender) (get additional-payment swap-proposal)))
            true
          )
          true
        )
        (map-set swap-proposals
          { swap-id: swap-id }
          (merge swap-proposal { is-active: false })
        )
        (ok true)
      )
      (err ERR-NOT-AUTHORIZED)
    )
  )
)

(define-public (deactivate-insurance (insurance-id uint))
  (let ((insurance (unwrap! (map-get? insurance-contracts { insurance-id: insurance-id }) (err ERR-INSURANCE-NOT-FOUND))))
    (if (is-eq (get owner insurance) tx-sender)
      (begin
        (map-set insurance-contracts
          { insurance-id: insurance-id }
          (merge insurance { is-active: false })
        )
        (ok true)
      )
      (err ERR-NOT-AUTHORIZED)
    )
  )
)

(define-read-only (get-insurance-contract (insurance-id uint))
  (map-get? insurance-contracts { insurance-id: insurance-id })
)

(define-read-only (get-swap-proposal (swap-id uint))
  (map-get? swap-proposals { swap-id: swap-id })
)

(define-read-only (get-user-balance (user principal))
  (get-balance user)
)

(define-read-only (get-next-insurance-id)
  (var-get next-insurance-id)
)

(define-read-only (get-next-swap-id)
  (var-get next-swap-id)
)
