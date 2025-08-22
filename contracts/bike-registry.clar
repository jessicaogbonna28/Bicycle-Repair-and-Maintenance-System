;; Bicycle Registry Contract
;; Manages bike registration, ownership, and theft prevention

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-BIKE-NOT-FOUND (err u101))
(define-constant ERR-BIKE-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-INPUT (err u103))
(define-constant ERR-NOT-OWNER (err u104))

;; Data Variables
(define-data-var next-bike-id uint u1)

;; Data Maps
(define-map bikes
  { bike-id: uint }
  {
    owner: principal,
    make: (string-ascii 50),
    model: (string-ascii 50),
    year: uint,
    serial-number: (string-ascii 100),
    color: (string-ascii 30),
    registration-date: uint,
    is-stolen: bool,
    theft-report-date: (optional uint)
  }
)

(define-map owner-bikes
  { owner: principal }
  { bike-ids: (list 50 uint) }
)

;; Public Functions

;; Register a new bike
(define-public (register-bike (make (string-ascii 50)) (model (string-ascii 50)) (year uint) (serial-number (string-ascii 100)) (color (string-ascii 30)))
  (let
    (
      (bike-id (var-get next-bike-id))
      (current-block-height block-height)
    )
    (asserts! (> (len make) u0) ERR-INVALID-INPUT)
    (asserts! (> (len model) u0) ERR-INVALID-INPUT)
    (asserts! (> year u1900) ERR-INVALID-INPUT)
    (asserts! (< year u2100) ERR-INVALID-INPUT)
    (asserts! (> (len serial-number) u0) ERR-INVALID-INPUT)

    ;; Create bike record
    (map-set bikes
      { bike-id: bike-id }
      {
        owner: tx-sender,
        make: make,
        model: model,
        year: year,
        serial-number: serial-number,
        color: color,
        registration-date: current-block-height,
        is-stolen: false,
        theft-report-date: none
      }
    )

    ;; Update owner's bike list
    (let
      (
        (current-bikes (default-to (list) (get bike-ids (map-get? owner-bikes { owner: tx-sender }))))
        (updated-bikes (unwrap! (as-max-len? (append current-bikes bike-id) u50) ERR-INVALID-INPUT))
      )
      (map-set owner-bikes { owner: tx-sender } { bike-ids: updated-bikes })
    )

    ;; Increment next bike ID
    (var-set next-bike-id (+ bike-id u1))

    (ok bike-id)
  )
)

;; Transfer bike ownership
(define-public (transfer-bike (bike-id uint) (new-owner principal))
  (let
    (
      (bike-data (unwrap! (map-get? bikes { bike-id: bike-id }) ERR-BIKE-NOT-FOUND))
      (current-owner (get owner bike-data))
    )
    (asserts! (is-eq tx-sender current-owner) ERR-NOT-OWNER)
    (asserts! (not (is-eq current-owner new-owner)) ERR-INVALID-INPUT)

    ;; Update bike owner
    (map-set bikes
      { bike-id: bike-id }
      (merge bike-data { owner: new-owner })
    )

    ;; Remove from current owner's list
    (let
      (
        (current-owner-bikes (default-to (list) (get bike-ids (map-get? owner-bikes { owner: current-owner }))))
        (filtered-bikes (filter is-not-bike-id current-owner-bikes))
      )
      (map-set owner-bikes { owner: current-owner } { bike-ids: filtered-bikes })
    )

    ;; Add to new owner's list
    (let
      (
        (new-owner-bikes (default-to (list) (get bike-ids (map-get? owner-bikes { owner: new-owner }))))
        (updated-bikes (unwrap! (as-max-len? (append new-owner-bikes bike-id) u50) ERR-INVALID-INPUT))
      )
      (map-set owner-bikes { owner: new-owner } { bike-ids: updated-bikes })
    )

    (ok true)
  )
)

;; Report bike as stolen
(define-public (report-stolen (bike-id uint))
  (let
    (
      (bike-data (unwrap! (map-get? bikes { bike-id: bike-id }) ERR-BIKE-NOT-FOUND))
      (bike-owner (get owner bike-data))
    )
    (asserts! (is-eq tx-sender bike-owner) ERR-NOT-OWNER)
    (asserts! (not (get is-stolen bike-data)) ERR-INVALID-INPUT)

    (map-set bikes
      { bike-id: bike-id }
      (merge bike-data {
        is-stolen: true,
        theft-report-date: (some block-height)
      })
    )

    (ok true)
  )
)

;; Mark bike as recovered
(define-public (mark-recovered (bike-id uint))
  (let
    (
      (bike-data (unwrap! (map-get? bikes { bike-id: bike-id }) ERR-BIKE-NOT-FOUND))
      (bike-owner (get owner bike-data))
    )
    (asserts! (is-eq tx-sender bike-owner) ERR-NOT-OWNER)
    (asserts! (get is-stolen bike-data) ERR-INVALID-INPUT)

    (map-set bikes
      { bike-id: bike-id }
      (merge bike-data {
        is-stolen: false,
        theft-report-date: none
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get bike details
(define-read-only (get-bike (bike-id uint))
  (map-get? bikes { bike-id: bike-id })
)

;; Get bikes owned by a principal
(define-read-only (get-owner-bikes (owner principal))
  (map-get? owner-bikes { owner: owner })
)

;; Check if bike is stolen
(define-read-only (is-bike-stolen (bike-id uint))
  (match (map-get? bikes { bike-id: bike-id })
    bike-data (get is-stolen bike-data)
    false
  )
)

;; Get next available bike ID
(define-read-only (get-next-bike-id)
  (var-get next-bike-id)
)

;; Private Functions

;; Helper function for filtering bike IDs
(define-private (is-not-bike-id (id uint))
  (not (is-eq id (var-get next-bike-id)))
)
