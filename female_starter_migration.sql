-- Run once if upgrading from an older version of this resource
ALTER TABLE female_starter ADD COLUMN discord_id VARCHAR(32) DEFAULT NULL;
ALTER TABLE female_starter ADD COLUMN redeemed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE female_starter ADD UNIQUE KEY idx_discord_id (discord_id);
