CREATE TABLE IF NOT EXISTS female_starter (
    identifier VARCHAR(50) NOT NULL PRIMARY KEY,
    discord_id VARCHAR(32) DEFAULT NULL,
    redeemed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_discord_id (discord_id)
);
