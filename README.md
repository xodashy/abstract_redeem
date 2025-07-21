# Female Starter Pack Redeem System

A simple FiveM ESX server script that allows users with a specific Discord role to redeem a one-time starter pack.

## Features
- Checks if a player has a specific Discord role before allowing redemption
- Prevents multiple redemptions per player
- Gives configurable starter items
- Notifies users of success, errors, or missing requirements

## Requirements
- [ESX](https://github.com/esx-framework/esx-legacy)
- [oxmysql](https://github.com/overextended/oxmysql)
- A Discord bot token with `Guild Members` intent enabled
- Your Discord server and role IDs

## Installation
1. Place this resource folder in your `resources` directory.
2. Import the database table:
   ```sql
   -- Run this in your database
   CREATE TABLE IF NOT EXISTS female_starter (
       identifier VARCHAR(50) NOT NULL PRIMARY KEY
   );
   ```
3. Add `ensure abstract_redeem` to your `server.cfg` after `es_extended` and `oxmysql`.

## Configuration
Edit `config.lua`:
```lua
Config.DiscordBotToken = "YOUR_DISCORD_BOT_TOKEN_HERE"
Config.DiscordGuildID = "YOUR_DISCORD_SERVER_ID_HERE"
Config.FemaleRoleID = "YOUR_DISCORD_ROLE_ID_HERE"

Config.StarterPack = {
    {item = "bread", count = 10},
    {item = "water", count = 10},
}
```
- **DiscordBotToken**: Your Discord bot's token
- **DiscordGuildID**: Your Discord server's ID
- **FemaleRoleID**: The Discord role ID required to redeem
- **StarterPack**: List of items and amounts to give

## Usage
- Players use `/redeem` in-game.
- If their Discord is linked and they have the required role, they receive the starter pack.
- Each player can only redeem once.
