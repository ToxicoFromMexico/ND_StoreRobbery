NDCore = exports["ND_Core"]:GetCoreObject()
local inventory = exports["ox_inventory"]
Dispatch = exports["ND_MDT"]

-- Load language
local langFile = LoadResourceFile(GetCurrentResourceName(), "lang/"..config.language..".lua")
assert(load(langFile))()


robberyActive = false
RegisterNetEvent('ShopRobbery:IsActive')
AddEventHandler('ShopRobbery:IsActive', function()
	-- Check if active or not
	if robberyActive then
		-- One is active
		TriggerClientEvent('ShopRobbery:IsActive:Return', source, true)
	else
		-- One is not active
		TriggerClientEvent('ShopRobbery:IsActive:Return', source, false)
	end
end)

RegisterNetEvent("ShopRobbery:Success")
AddEventHandler("ShopRobbery:Success", function()
    local player = NDCore.getPlayer(source)
    local reward = 0

    if config.robbery.useRandomReward then
        reward = math.random(config.robbery.minReward, config.robbery.maxReward)
    else
        reward = config.robbery.fixedReward
    end

    local success = player.addMoney("cash", reward, "illegal")
    print(success)

    player.notify({
        title = locale.Info,
        description = string.format(locale.Success, reward),
        type = "inform",
        position = "top",
        duration = 5000
    })
end)

RegisterNetEvent("ShopRobbery:Ann") --Begin
AddEventHandler("ShopRobbery:Ann", function()
	local player = NDCore.getPlayer(source)
    player.notify({
        title = locale.Info,
        description = locale.Begin,
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
        iconColor = '#559857'
    })
end)

RegisterNetEvent("ShopRobbery:Cancel")
AddEventHandler("ShopRobbery:Cancel", function()
end)

RegisterNetEvent("ShopRobbery:Fail")
AddEventHandler("ShopRobbery:Fail", function()
	local player = NDCore.getPlayer(source)
	player.notify({
		title = locale.Info,
		description = locale.FailRobbery,
		type = "inform",
		position = "top",
		duration = 3000
	})
end)

RegisterNetEvent("ShopRobbery:Disps") --Dispatch
AddEventHandler("ShopRobbery:Disps", function()
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    exports["ND_MDT"]:createDispatch({
        caller = "24/7",
        callDescription = locale.Dispatch,
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