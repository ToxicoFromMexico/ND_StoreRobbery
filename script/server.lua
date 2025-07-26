NDCore = exports["ND_Core"]:GetCoreObject()
local inventory = exports["ox_inventory"]
Dispatch = exports["ND_MDT"]


local locale = {}
local function loadLocale()
    if config and config.language then
        local localeFile = LoadResourceFile(GetCurrentResourceName(), "locales/"..config.language..".lua")
        if localeFile then
            local chunk, err = load("return " .. localeFile)
            if chunk then
                local result = chunk()
                if result and result.locale then
                    locale = result.locale
                    return true
                end
            else
                print("^1[LANG ERROR]^7 Error loading language: "..tostring(err))
            end
        else
            print("^1[LANG ERROR]^7 Language file not found: locales/"..config.language..".lua")
        end
    end
    
    -- Fallback locale
    locale = {
        Start = "Press E to start the robbery",
        Success = "You successfully stole $%s!",
        FailRobbery = "Robbery failed!",
        Begin = "You will receive the money when the timer runs out! Stay inside the store!",
        Info = "Store Robbery",
        Dispatch = "Store robbery in progress"
    }
    return false
end

Citizen.CreateThread(function()
    while not config do
        Citizen.Wait(100)
    end
    loadLocale()
end)

robberyActive = false

RegisterNetEvent('ShopRobbery:IsActive')
AddEventHandler('ShopRobbery:IsActive', function()
    if robberyActive then
        TriggerClientEvent('ShopRobbery:IsActive:Return', source, true)
    else
        TriggerClientEvent('ShopRobbery:IsActive:Return', source, false)
    end
end)

RegisterNetEvent("ShopRobbery:Success")
AddEventHandler("ShopRobbery:Success", function()
    local player = NDCore.getPlayer(source)
    if not player then return end
    
    local reward = 0
    if config.robbery.useRandomReward then
        reward = math.random(config.robbery.minReward, config.robbery.maxReward)
    else
        reward = config.robbery.fixedReward
    end

    local success = player.addMoney("cash", reward, "illegal")

    player.notify({
        title = locale.Info or "Store Robbery",
        description = string.format(locale.Success or "You successfully stole $%s!", reward),
        type = "success",
        position = "top",
        duration = 5000
    })
end)

RegisterNetEvent("ShopRobbery:Ann")
AddEventHandler("ShopRobbery:Ann", function()
    local player = NDCore.getPlayer(source)
    if not player then return end
    
    player.notify({
        title = locale.Info or "Store Robbery",
        description = locale.Begin or "You will receive the money when the timer runs out! Stay inside the store!",
        position = "top",
        duration = 1000 * 60 * config.timeToRob,
        showDuration = true,
        style = {
            backgroundColor = '#141517',
            color = '#C1C2C5',
            ['.description'] = {
                color = '#909296'
            }
        },
        icon = 'sack-dollar',
        iconColor = '#559857',
        id = 'robbery_progress' 
    })
end)

RegisterNetEvent("ShopRobbery:Cancel")
AddEventHandler("ShopRobbery:Cancel", function()
    local player = NDCore.getPlayer(source)
    if not player then return end
    
    player.notify({
        id = 'robbery_progress',
        duration = 1
    })
end)

RegisterNetEvent("ShopRobbery:Fail")
AddEventHandler("ShopRobbery:Fail", function()
    local player = NDCore.getPlayer(source)
    if not player then return end
    
    player.notify({
        id = 'robbery_progress',
        duration = 1
    })
    
    player.notify({
        title = locale.Info or "Store Robbery",
        description = locale.Fail or "Robbery failed!",
        type = "error",
        position = "top",
        duration = 3000
    })
end)

RegisterNetEvent("ShopRobbery:Disps")
AddEventHandler("ShopRobbery:Disps", function()
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    exports["ND_MDT"]:createDispatch({
        caller = "24/7",
        callDescription = locale.Dispatch or "Store robbery in progress",
        coords = coords
    })
end)

RegisterNetEvent('ShopRobbery:SetActive')
AddEventHandler('ShopRobbery:SetActive', function(bool)
    robberyActive = bool
    if bool then
        Wait((1000 * 60 * config.robberyCooldown))
        robberyActive = false
    end
end)

RegisterNetEvent('Print:PrintDebug')
AddEventHandler('Print:PrintDebug', function(msg)
    print(msg)
    TriggerClientEvent('chatMessage', -1, "^1DEBUG" .. msg)
end)

RegisterNetEvent('PrintBR:PrintMessage')
AddEventHandler('PrintBR:PrintMessage', function(msg)
    TriggerClientEvent('chatMessage', -1, msg)
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local players = GetPlayers()
        for _, playerId in pairs(players) do
            local player = NDCore.getPlayer(tonumber(playerId))
            if player then
                player.notify({
                    id = 'robbery_progress',
                    duration = 1
                })
            end
        end
        
        robberyActive = false
        print("^2[ShopRobbery]^7 Script stopped - All notifications cleared")
    end
end)