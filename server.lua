if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()
local Config = lib.require('config')

function hasRedeemed(identifier, cb)
    MySQL.scalar('SELECT 1 FROM female_starter WHERE identifier = ?', {identifier}, function(result)
        cb(result ~= nil)
    end)
end

function markRedeemed(identifier)
    MySQL.execute('INSERT INTO female_starter (identifier) VALUES (?)', {identifier})
end

RegisterCommand(Config.Command, function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local discordId
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 8) == 'discord:' then
            discordId = id:sub(9)
            break
        end
    end
    if not discordId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'inform',
            description = 'Discord not linked. You need the female role to redeem.'
        })
        return
    end

    PerformHttpRequest(('https://discord.com/api/v10/guilds/%s/members/%s'):format(Config.DiscordGuildID, discordId),
        function(code, data)
            if code ~= 200 or not data then
                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    description = 'Error checking Discord. Try again later.'
                })
                return
            end
            local member = json.decode(data)
            local hasRole = false
            for _, role in pairs(member.roles or {}) do
                if role == Config.FemaleRoleID then
                    hasRole = true
                    break
                end
            end
            if not hasRole then
                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'error',
                    description = 'You don\'t have the required Discord role.'
                })
                return
            end
            hasRedeemed(identifier, function(redeemed)
                if redeemed then
                    TriggerClientEvent('ox_lib:notify', source, {
                        type = 'inform',
                        description = 'You already claimed your starter pack.'
                    })
                    return
                end
                for _, item in ipairs(Config.StarterPack) do
                    xPlayer.addInventoryItem(item.item, item.count)
                end
                markRedeemed(identifier)
                TriggerClientEvent('ox_lib:notify', source, {
                    type = 'success',
                    description = 'You got your female starter pack!'
                })
            end)
        end,
        'GET', '', {
            ['Authorization'] = 'Bot ' .. Config.DiscordBotToken
        }
    )
end, false)
