# Female Starter Pack Redeem System

A simple FiveM ESX server script that allows users with a specific Discord role to redeem a one-time starter pack.

## Features
- Checks if a player has a specific Discord role before allowing redemption
- Prevents multiple redemptions per character or Discord account
- Gives configurable starter items
- Notifies users of success, errors, or missing requirements
- Discord role check caching to reduce API calls
- Redeem attempt cooldown to prevent spam
- Discord webhook logging for staff
- Admin commands to check, reset, or force redemption

## Requirements
- [ESX](https://github.com/esx-framework/esx-legacy)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib) (notifications)
- A Discord bot token with `Guild Members` intent enabled
- Your Discord server and role IDs

## Installation
1. Place this resource folder in your `resources` directory.
2. Import the database table:
   ```sql
   -- Run this in your database (fresh install)
   CREATE TABLE IF NOT EXISTS female_starter (
       identifier VARCHAR(50) NOT NULL PRIMARY KEY,
       discord_id VARCHAR(32) DEFAULT NULL,
       redeemed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       UNIQUE KEY idx_discord_id (discord_id)
   );
   ```
   If upgrading from an older version, run `female_starter_migration.sql` instead.
3. Add the convars below and `ensure abstract_redeem` to your `server.cfg` after `es_extended` and `oxmysql`.

## Configuration
Add these to `server.cfg` (use `set`, not `setr`, so secrets stay server-side only):
```
set abstract_redeem:discord_bot_token "YOUR_DISCORD_BOT_TOKEN_HERE"
set abstract_redeem:discord_guild_id "YOUR_DISCORD_SERVER_ID_HERE"
set abstract_redeem:female_role_id "YOUR_DISCORD_ROLE_ID_HERE"
set abstract_redeem:discord_webhook_url "YOUR_DISCORD_WEBHOOK_URL_HERE"
```

Starter items and other settings in `config.lua`:
```lua
Config.AdminGroups = { 'admin', 'superadmin' }
Config.RoleCacheSeconds = 300
Config.RedeemCooldownSeconds = 30

Config.StarterPack = {
    {item = "bread", count = 10},
    {item = "water", count = 10},
}
```

- **abstract_redeem:discord_bot_token**: Your Discord bot's token
- **abstract_redeem:discord_guild_id**: Your Discord server's ID
- **abstract_redeem:female_role_id**: The Discord role ID required to redeem
- **abstract_redeem:discord_webhook_url**: Optional webhook URL for redeem logs (leave empty to disable)
- **AdminGroups**: ESX groups allowed to use admin commands
- **RoleCacheSeconds**: How long Discord role data is cached per player
- **RedeemCooldownSeconds**: Seconds between redeem attempts
- **StarterPack**: List of items and amounts to give

## Usage
### Players
- Use `/femaleredeem` in-game.
- If their Discord is linked and they have the required role, they receive the starter pack.
- Each character and Discord account can only redeem once.

### Admins
- `/redeemstatus [player id]` — Check if a player has redeemed
- `/redeemreset [player id]` — Clear a player's redemption so they can claim again
- `/redeemforce [player id]` — Grant the starter pack without a Discord role check

Admin commands also work from the server console (source `0`).
