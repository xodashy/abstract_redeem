if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

local roleCache = {}
local redeemCooldown = {}

local function notify(source, ntype, description)
    TriggerClientEvent('ox_lib:notify', source, {
        type = ntype,
        position = 'center-right',
        description = description
    })
end

local function getDiscordId(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
end

local function isAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local group = xPlayer.getGroup()
    for _, adminGroup in ipairs(Config.AdminGroups) do
        if group == adminGroup then
            return true
        end
    end

    return false
end

local function getTargetPlayer(source, args)
    local targetId = tonumber(args[1])
    if not targetId then
        notify(source, 'error', 'Usage: /command [player id]')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(targetId)
    if not xPlayer then
        notify(source, 'error', 'Player not found.')
        return
    end

    return targetId, xPlayer
end

local function hasRedeemed(identifier, discordId, cb)
    exports.oxmysql:scalar(
        'SELECT 1 FROM female_starter WHERE identifier = ? OR (discord_id IS NOT NULL AND discord_id = ?)',
        { identifier, discordId or '' },
        function(result)
            cb(result ~= nil)
        end
    )
end

local function getRedeemInfo(identifier, discordId, cb)
    exports.oxmysql:single(
        'SELECT identifier, discord_id, redeemed_at FROM female_starter WHERE identifier = ? OR (discord_id IS NOT NULL AND discord_id = ?)',
        { identifier, discordId or '' },
        function(result)
            cb(result)
        end
    )
end

local function markRedeemed(identifier, discordId)
    exports.oxmysql:execute(
        'INSERT INTO female_starter (identifier, discord_id) VALUES (?, ?)',
        { identifier, discordId }
    )
end

local function resetRedeemed(identifier, discordId)
    exports.oxmysql:execute(
        'DELETE FROM female_starter WHERE identifier = ? OR (discord_id IS NOT NULL AND discord_id = ?)',
        { identifier, discordId or '' }
    )
end

local function grantStarterPack(xPlayer)
    for _, item in ipairs(Config.StarterPack) do
        xPlayer.addInventoryItem(item.item, item.count)
    end
end

local function sendWebhook(playerName, identifier, discordId)
    if Config.DiscordWebhookURL == '' then return end

    local items = {}
    for _, item in ipairs(Config.StarterPack) do
        items[#items + 1] = ('%sx %s'):format(item.count, item.item)
    end

    PerformHttpRequest(Config.DiscordWebhookURL, function() end, 'POST', json.encode({
        embeds = {{
            title = 'Starter Pack Redeemed',
            color = 5763719,
            fields = {
                { name = 'Player', value = playerName, inline = true },
                { name = 'Identifier', value = identifier, inline = false },
                { name = 'Discord ID', value = discordId or 'N/A', inline = true },
                { name = 'Items', value = table.concat(items, '\n'), inline = false },
            },
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
        }}
    }), { ['Content-Type'] = 'application/json' })
end

local function playerHasFemaleRole(roles)
    for _, role in pairs(roles or {}) do
        if tostring(role) == tostring(Config.FemaleRoleID) then
            return true
        end
    end

    return false
end

local function fetchDiscordRoles(discordId, cb)
    local cached = roleCache[discordId]
    if cached and os.time() < cached.expires then
        cb(true, cached.roles)
        return
    end

    PerformHttpRequest(
        ('https://discord.com/api/v10/guilds/%s/members/%s'):format(Config.DiscordGuildID, discordId),
        function(code, data)
            if code ~= 200 or not data then
                cb(false)
                return
            end

            local success, member = pcall(json.decode, data)
            if not success then
                cb(false)
                return
            end

            roleCache[discordId] = {
                roles = member.roles or {},
                expires = os.time() + Config.RoleCacheSeconds,
            }

            cb(true, member.roles or {})
        end,
        'GET', '', {
            ['Authorization'] = 'Bot ' .. Config.DiscordBotToken
        }
    )
end

local function isOnCooldown(source)
    local lastAttempt = redeemCooldown[source]
    if not lastAttempt then return false end

    local elapsed = os.time() - lastAttempt
    if elapsed >= Config.RedeemCooldownSeconds then
        return false
    end

    return true, Config.RedeemCooldownSeconds - elapsed
end

local function setCooldown(source)
    redeemCooldown[source] = os.time()
end

local function completeRedeem(source, xPlayer, identifier, discordId)
    grantStarterPack(xPlayer)
    markRedeemed(identifier, discordId)
    sendWebhook(GetPlayerName(source), identifier, discordId)
    notify(source, 'success', 'You got your female starter pack!')
end

local function processRedeem(source, skipRoleCheck)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local discordId = getDiscordId(source)

    if not skipRoleCheck then
        local onCooldown, remaining = isOnCooldown(source)
        if onCooldown then
            notify(source, 'error', ('Please wait %d seconds before trying again.'):format(remaining))
            return
        end

        if not discordId then
            notify(source, 'inform', 'Discord not linked. You need the female role to redeem.')
            return
        end

        setCooldown(source)
    end

    local function tryGrant()
        hasRedeemed(identifier, discordId, function(redeemed)
            if redeemed then
                notify(source, 'inform', 'You already claimed your starter pack.')
                return
            end

            completeRedeem(source, xPlayer, identifier, discordId)
        end)
    end

    if skipRoleCheck then
        tryGrant()
        return
    end

    fetchDiscordRoles(discordId, function(ok, roles)
        if not ok then
            notify(source, 'error', 'Error checking Discord. Try again later.')
            return
        end

        if not playerHasFemaleRole(roles) then
            notify(source, 'error', 'You don\'t have the required Discord role.')
            return
        end

        tryGrant()
    end)
end

-- GLobal redeem command
RegisterCommand('femaleredeem', function(source)
    processRedeem(source, false)
end, false)

-- Reset a player's redeem status
-- RegisterCommand('redeemreset', function(source, args)
--     if source ~= 0 and not isAdmin(source) then
--         notify(source, 'error', 'You do not have permission to use this command.')
--         return
--     end

--     local targetId, xPlayer = getTargetPlayer(source, args)
--     if not targetId then return end

--     local identifier = xPlayer.getIdentifier()
--     local discordId = getDiscordId(targetId)

--     resetRedeemed(identifier, discordId)

--     local message = ('Reset redemption for %s.'):format(GetPlayerName(targetId))
--     if source == 0 then
--         print(('[abstract_redeem] %s'):format(message))
--     else
--         notify(source, 'success', message)
--     end
-- end, false)

-- Force redeem a starter pack for a player with no choice
-- RegisterCommand('redeemforce', function(source, args)
--     if source ~= 0 and not isAdmin(source) then
--         notify(source, 'error', 'You do not have permission to use this command.')
--         return
--     end

--     local targetId, xPlayer = getTargetPlayer(source, args)
--     if not targetId then return end

--     local identifier = xPlayer.getIdentifier()
--     local discordId = getDiscordId(targetId)

--     hasRedeemed(identifier, discordId, function(redeemed)
--         if redeemed then
--             local message = ('%s has already redeemed.'):format(GetPlayerName(targetId))
--             if source == 0 then
--                 print(('[abstract_redeem] %s'):format(message))
--             else
--                 notify(source, 'inform', message)
--             end
--             return
--         end

--         completeRedeem(targetId, xPlayer, identifier, discordId)

--         local message = ('Forced starter pack for %s.'):format(GetPlayerName(targetId))
--         if source == 0 then
--             print(('[abstract_redeem] %s'):format(message))
--         else
--             notify(source, 'success', message)
--         end
--     end)
-- end, false)

AddEventHandler('playerDropped', function()
    redeemCooldown[source] = nil
end)
