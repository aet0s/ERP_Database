-- Migration 003: Subscription & Billing Lifecycle Schema for erp_master

ALTER TABLE companies ADD COLUMN subscription_id VARCHAR(255);
ALTER TABLE companies ADD COLUMN subscription_status VARCHAR(50) DEFAULT 'trialing';
ALTER TABLE companies ADD COLUMN current_period_end DATETIME;
ALTER TABLE companies ADD COLUMN trial_ends_at DATETIME;
ALTER TABLE companies ADD COLUMN canceled_at DATETIME;
ALTER TABLE companies ADD COLUMN graceful_read_only_until DATETIME;

-- Idempotency table for Billing Webhook Events
CREATE TABLE IF NOT EXISTS master_webhook_events (
    id VARCHAR(36) PRIMARY KEY,
    event_id VARCHAR(255) NOT NULL UNIQUE,
    provider VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSON NOT NULL,
    processed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_master_webhook_events_event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_companies_subscription_status ON companies(subscription_status);
