;; Appointment Manager Contract
;; Handles repair appointments, diagnostics, and service coordination

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-APPOINTMENT-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-INVALID-STATUS (err u203))
(define-constant ERR-NOT-CUSTOMER (err u204))

;; Status constants
(define-constant STATUS-SCHEDULED u1)
(define-constant STATUS-IN-PROGRESS u2)
(define-constant STATUS-DIAGNOSTIC-COMPLETE u3)
(define-constant STATUS-REPAIR-COMPLETE u4)
(define-constant STATUS-CANCELLED u5)

;; Data Variables
(define-data-var next-appointment-id uint u1)
(define-data-var authorized-technicians (list 20 principal) (list))

;; Data Maps
(define-map appointments
  { appointment-id: uint }
  {
    customer: principal,
    bike-id: uint,
    service-type: (string-ascii 100),
    scheduled-date: uint,
    technician: (optional principal),
    status: uint,
    diagnostic-notes: (optional (string-ascii 500)),
    estimated-cost: (optional uint),
    actual-cost: (optional uint),
    completion-date: (optional uint)
  }
)

(define-map customer-appointments
  { customer: principal }
  { appointment-ids: (list 50 uint) }
)

(define-map technician-appointments
  { technician: principal }
  { appointment-ids: (list 100 uint) }
)

;; Public Functions

;; Schedule a new appointment
(define-public (schedule-appointment (bike-id uint) (service-type (string-ascii 100)) (scheduled-date uint))
  (let
    (
      (appointment-id (var-get next-appointment-id))
    )
    (asserts! (> (len service-type) u0) ERR-INVALID-INPUT)
    (asserts! (> scheduled-date block-height) ERR-INVALID-INPUT)

    ;; Create appointment record
    (map-set appointments
      { appointment-id: appointment-id }
      {
        customer: tx-sender,
        bike-id: bike-id,
        service-type: service-type,
        scheduled-date: scheduled-date,
        technician: none,
        status: STATUS-SCHEDULED,
        diagnostic-notes: none,
        estimated-cost: none,
        actual-cost: none,
        completion-date: none
      }
    )

    ;; Update customer's appointment list
    (let
      (
        (current-appointments (default-to (list) (get appointment-ids (map-get? customer-appointments { customer: tx-sender }))))
        (updated-appointments (unwrap! (as-max-len? (append current-appointments appointment-id) u50) ERR-INVALID-INPUT))
      )
      (map-set customer-appointments { customer: tx-sender } { appointment-ids: updated-appointments })
    )

    ;; Increment next appointment ID
    (var-set next-appointment-id (+ appointment-id u1))

    (ok appointment-id)
  )
)

;; Assign technician to appointment
(define-public (assign-technician (appointment-id uint) (technician principal))
  (let
    (
      (appointment-data (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
    )
    (asserts! (is-authorized-technician technician) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status appointment-data) STATUS-SCHEDULED) ERR-INVALID-STATUS)

    ;; Update appointment with technician
    (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment-data {
        technician: (some technician),
        status: STATUS-IN-PROGRESS
      })
    )

    ;; Add to technician's appointment list
    (let
      (
        (current-tech-appointments (default-to (list) (get appointment-ids (map-get? technician-appointments { technician: technician }))))
        (updated-tech-appointments (unwrap! (as-max-len? (append current-tech-appointments appointment-id) u100) ERR-INVALID-INPUT))
      )
      (map-set technician-appointments { technician: technician } { appointment-ids: updated-tech-appointments })
    )

    (ok true)
  )
)

;; Complete diagnostic
(define-public (complete-diagnostic (appointment-id uint) (diagnostic-notes (string-ascii 500)) (estimated-cost uint))
  (let
    (
      (appointment-data (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
      (assigned-technician (unwrap! (get technician appointment-data) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq tx-sender assigned-technician) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status appointment-data) STATUS-IN-PROGRESS) ERR-INVALID-STATUS)
    (asserts! (> (len diagnostic-notes) u0) ERR-INVALID-INPUT)
    (asserts! (> estimated-cost u0) ERR-INVALID-INPUT)

    (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment-data {
        status: STATUS-DIAGNOSTIC-COMPLETE,
        diagnostic-notes: (some diagnostic-notes),
        estimated-cost: (some estimated-cost)
      })
    )

    (ok true)
  )
)

;; Complete repair
(define-public (complete-repair (appointment-id uint) (actual-cost uint))
  (let
    (
      (appointment-data (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
      (assigned-technician (unwrap! (get technician appointment-data) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq tx-sender assigned-technician) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status appointment-data) STATUS-DIAGNOSTIC-COMPLETE) ERR-INVALID-STATUS)
    (asserts! (> actual-cost u0) ERR-INVALID-INPUT)

    (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment-data {
        status: STATUS-REPAIR-COMPLETE,
        actual-cost: (some actual-cost),
        completion-date: (some block-height)
      })
    )

    (ok true)
  )
)

;; Cancel appointment
(define-public (cancel-appointment (appointment-id uint))
  (let
    (
      (appointment-data (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
      (customer (get customer appointment-data))
    )
    (asserts! (is-eq tx-sender customer) ERR-NOT-CUSTOMER)
    (asserts! (< (get status appointment-data) STATUS-REPAIR-COMPLETE) ERR-INVALID-STATUS)

    (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment-data { status: STATUS-CANCELLED })
    )

    (ok true)
  )
)

;; Add authorized technician (admin only)
(define-public (add-technician (technician principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (let
      (
        (current-techs (var-get authorized-technicians))
        (updated-techs (unwrap! (as-max-len? (append current-techs technician) u20) ERR-INVALID-INPUT))
      )
      (var-set authorized-technicians updated-techs)
      (ok true)
    )
  )
)

;; Read-only Functions

;; Get appointment details
(define-read-only (get-appointment (appointment-id uint))
  (map-get? appointments { appointment-id: appointment-id })
)

;; Get customer appointments
(define-read-only (get-customer-appointments (customer principal))
  (map-get? customer-appointments { customer: customer })
)

;; Get technician appointments
(define-read-only (get-technician-appointments (technician principal))
  (map-get? technician-appointments { technician: technician })
)

;; Check if technician is authorized
(define-read-only (is-authorized-technician (technician principal))
  (is-some (index-of (var-get authorized-technicians) technician))
)

;; Get appointment status
(define-read-only (get-appointment-status (appointment-id uint))
  (match (map-get? appointments { appointment-id: appointment-id })
    appointment-data (get status appointment-data)
    u0
  )
)
