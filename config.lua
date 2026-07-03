Config = {}

Config.DiscordBotToken = GetConvar('abstract_redeem:discord_bot_token', '')
Config.DiscordGuildID = GetConvar('abstract_redeem:discord_guild_id', '')
Config.FemaleRoleID = GetConvar('abstract_redeem:female_role_id', '')
Config.DiscordWebhookURL = GetConvar('abstract_redeem:discord_webhook_url', '')

Config.AdminGroups = { 'admin', 'superadmin' }
Config.RoleCacheSeconds = 300
Config.RedeemCooldownSeconds = 30

Config.StarterPack = {
    {item = "bread", count = 10},
    {item = "water", count = 10},
}

--[[ example in cfg to set convars
set abstract_redeem:discord_bot_token "YOUR_DISCORD_BOT_TOKEN_HERE"
set abstract_redeem:discord_guild_id "YOUR_DISCORD_GUILD_ID_HERE"
set abstract_redeem:female_role_id "YOUR_DISCORD_ROLE_ID_HERE"
set abstract_redeem:discord_webhook_url "YOUR_DISCORD_WEBHOOK_URL_HERE"
]]