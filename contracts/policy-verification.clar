;; Policy Verification Contract
;; Validates active insurance coverage

(define-data-var admin principal tx-sender)

;; Map to store policy information
(define-map policies
  { policy-id: (string-ascii 20) }
  {
    owner: principal,
    active: bool,
    coverage-amount: uint,
    expiration-block: uint
  }
)

;; Function to add a new policy
(define-public (add-policy (policy-id (string-ascii 20)) (owner principal) (coverage-amount uint) (duration uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (is-none (map-get? policies { policy-id: policy-id })) (err u2))
    (ok (map-set policies
      { policy-id: policy-id }
      {
        owner: owner,
        active: true,
        coverage-amount: coverage-amount,
        expiration-block: (+ block-height duration)
      }
    ))
  )
)

;; Function to check if a policy is active
(define-read-only (is-policy-active (policy-id (string-ascii 20)))
  (let ((policy (map-get? policies { policy-id: policy-id })))
    (if (is-some policy)
      (let ((policy-data (unwrap-panic policy)))
        (and
          (get active policy-data)
          (<= block-height (get expiration-block policy-data))
        )
      )
      false
    )
  )
)

;; Function to get policy details
(define-read-only (get-policy (policy-id (string-ascii 20)))
  (map-get? policies { policy-id: policy-id })
)

;; Function to deactivate a policy
(define-public (deactivate-policy (policy-id (string-ascii 20)))
  (let ((policy (map-get? policies { policy-id: policy-id })))
    (begin
      (asserts! (is-some policy) (err u3))
      (asserts! (or
                  (is-eq tx-sender (var-get admin))
                  (is-eq tx-sender (get owner (unwrap-panic policy)))
                )
                (err u4))
      (ok (map-set policies
        { policy-id: policy-id }
        (merge (unwrap-panic policy) { active: false })
      ))
    )
  )
)

;; Function to transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u5))
    (ok (var-set admin new-admin))
  )
)
