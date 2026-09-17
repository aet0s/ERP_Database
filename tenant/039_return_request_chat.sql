-- Migration 039: Return Request Chat Messages
-- Adds per-return-request chat thread between ERP staff and vendor/customer.
-- Each return request gets its own isolated thread.
-- Chat is open while status = Pending; locked after Approved/Rejected.

CREATE TABLE IF NOT EXISTS return_request_messages (
    id                  VARCHAR(36)     PRIMARY KEY,
    return_request_id   VARCHAR(36)     NOT NULL,

    -- Who sent the message
    sender_type         VARCHAR(30)     NOT NULL,
    -- Values: 'erp_user' (internal staff), 'vendor' (vendor portal user),
    --         'customer' (customer portal user), 'system' (auto-generated)

    sender_id           VARCHAR(36)     NOT NULL,
    sender_name         VARCHAR(200)    NOT NULL DEFAULT 'System',

    message             TEXT            NOT NULL,

    -- 1 = auto-generated system event message (shown differently in UI)
    is_system           TINYINT(1)      NOT NULL DEFAULT 0,

    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_rrm_request_id    (return_request_id),
    INDEX idx_rrm_created_at    (created_at),
    INDEX idx_rrm_sender_type   (sender_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
