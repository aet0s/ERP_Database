-- Migration 010: Vendor & Customer Portal Users
-- Vendor and customer portal users are stored per tenant database (per company).
-- Auth tokens are separate from internal user JWTs \u2014 portal tokens cannot access internal routes.

-- ─────────────────────────────────────────────────────────────────────────────
-- VENDOR PORTAL USERS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vendor_portal_users (
    id                  VARCHAR(36)  PRIMARY KEY,
    vendor_id           VARCHAR(36)  NOT NULL,
    name                VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    password_hash       VARCHAR(255),
    status              VARCHAR(50)  NOT NULL DEFAULT 'Active',
    invite_token        VARCHAR(255),
    invite_expires_at   DATETIME,
    invite_accepted_at  DATETIME,
    last_login_at       DATETIME,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
    UNIQUE KEY unique_vendor_portal_email (email),
    INDEX idx_vendor_portal_vendor  (vendor_id),
    INDEX idx_vendor_portal_token   (invite_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- CUSTOMER PORTAL USERS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customer_portal_users (
    id                  VARCHAR(36)  PRIMARY KEY,
    customer_id         VARCHAR(36)  NOT NULL,
    name                VARCHAR(255) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    password_hash       VARCHAR(255),
    status              VARCHAR(50)  NOT NULL DEFAULT 'Active',
    invite_token        VARCHAR(255),
    invite_expires_at   DATETIME,
    invite_accepted_at  DATETIME,
    last_login_at       DATETIME,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    UNIQUE KEY unique_customer_portal_email (email),
    INDEX idx_customer_portal_customer (customer_id),
    INDEX idx_customer_portal_token    (invite_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- MIGRATION TRACKING
-- ─────────────────────────────────────────────────────────────────────────────

