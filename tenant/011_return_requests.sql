-- Migration 011: Return Requests (Order Return & Cancellation Queue)
-- Unified request queue for purchase returns, purchase cancellations,
-- sales returns, and sales cancellations. Supports internal staff requests
-- and requests submitted via vendor/customer portals.

CREATE TABLE IF NOT EXISTS return_requests (
    id                  VARCHAR(36)     PRIMARY KEY,
    request_number      VARCHAR(100)    NOT NULL UNIQUE,
    request_type        VARCHAR(50)     NOT NULL,
    -- Values: purchase_return, purchase_cancellation, sales_return, sales_cancellation

    reference_id        VARCHAR(36)     NOT NULL,   -- procurement_id or sale_id or invoice_id
    reference_type      VARCHAR(50)     NOT NULL,   -- 'procurement', 'sale', 'invoice'

    -- Who submitted the request
    requested_by_type   VARCHAR(50)     NOT NULL DEFAULT 'internal',
    -- Values: internal, vendor_portal, customer_portal
    requested_by_id     VARCHAR(36),    -- portal_user.id or internal user.id

    -- Which party is involved
    vendor_id           VARCHAR(36),
    customer_id         VARCHAR(36),

    -- Request content
    reason              TEXT            NOT NULL,
    items               JSON,           -- snapshot of items/quantities being returned

    -- Review outcome
    status              VARCHAR(50)     NOT NULL DEFAULT 'Pending',
    -- Values: Pending, Approved, Rejected
    reviewed_by         VARCHAR(36),    -- internal user.id who acted on it
    reviewed_at         DATETIME,
    review_notes        TEXT,

    -- Document created on approval
    outcome_document_type  VARCHAR(50), -- 'debit_note', 'credit_note', null (for cancellations)
    outcome_document_id    VARCHAR(36),

    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_return_requests_status    (status),
    INDEX idx_return_requests_vendor    (vendor_id),
    INDEX idx_return_requests_customer  (customer_id),
    INDEX idx_return_requests_type      (request_type),
    INDEX idx_return_requests_created   (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Numbering series for return requests
INSERT IGNORE INTO numbering_series (document_type, prefix, next_number, padding_digits, reset_period)
VALUES ('return_request', 'RR-', 1, 4, 'FY');

-- Migration tracking

