-- 020_create_notifications_table.sql
CREATE TABLE IF NOT EXISTS notifications (
  id VARCHAR(36) PRIMARY KEY,
  user_type VARCHAR(50) NOT NULL,
  user_id VARCHAR(36) NULL,
  vendor_id VARCHAR(36) NULL,
  customer_id VARCHAR(36) NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  link VARCHAR(255) NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_notifications_user_type (user_type),
  INDEX idx_notifications_user_id (user_id),
  INDEX idx_notifications_vendor_id (vendor_id),
  INDEX idx_notifications_customer_id (customer_id),
  INDEX idx_notifications_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
