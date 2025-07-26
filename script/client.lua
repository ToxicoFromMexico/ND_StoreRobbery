local robberyActive = false
local robbing = false
local robbedShopCoords = nil
local deathCheckThread = nil
local distanceCheckThread = nil


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
        Start = "~r~Press ~w~E ~r~to start the robbery",
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

RegisterNetEvent('ShopRobbery:IsActive:Return')
AddEventHandler('ShopRobbery:IsActive:Return', function(bool)
    robberyActive = bool
end)

local function stopRobbery()
    robbing = false
    TriggerServerEvent("ShopRobbery:Cancel")
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if not robberyActive and config then
            for _, shopcoords in pairs(config.shopcoords) do
                DrawMarker(27, shopcoords.x, shopcoords.y, shopcoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, .2, 255, 0, 0, 255, false, true, 2, false, nil, nil, false)
            end
        end

        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if config then
            for _, shopcoords in pairs(config.shopcoords) do
                if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, shopcoords.x, shopcoords.y, shopcoords.z, true) < 5.0 then
                    DisplayNotification(locale.Start or "Press E to start robbery")
                    if IsControlJustReleased(0, 38) and not robberyActive then -- E
                        TriggerServerEvent('ShopRobbery:SetActive', true)
                        TriggerServerEvent("ShopRobbery:Disps")
                        TriggerServerEvent("ShopRobbery:Ann")
                        robbing = true
                        robbedShopCoords = shopcoords

                        -- Death check thread
                        if deathCheckThread == nil then
                            deathCheckThread = Citizen.CreateThread(function()
                                while robbing do
                                    Citizen.Wait(500)
                                    if IsEntityDead(playerPed) then
                                        TriggerServerEvent("ShopRobbery:Fail")
                                        stopRobbery()
                                        break
                                    end
                                end
                                deathCheckThread = nil
                            end)
                        end

                        -- Distance check thread
                        if distanceCheckThread == nil then
                            distanceCheckThread = Citizen.CreateThread(function()
                                while robbing do
                                    Citizen.Wait(1000)
                                    local playerCoords = GetEntityCoords(PlayerPedId())
                                    if #(playerCoords - vector3(robbedShopCoords.x, robbedShopCoords.y, robbedShopCoords.z)) > 20.0 then
                                        TriggerServerEvent("ShopRobbery:Fail")
                                        stopRobbery()
                                        break
                                    end
                                end
                                distanceCheckThread = nil
                            end)
                        end

                        Citizen.Wait(1000 * 60 * config.timeToRob)
                        if robbing then
                            TriggerServerEvent("ShopRobbery:Success")
                            robbing = false
                        end
                    end
                end
            end
        end
    end
end)

function DisplayNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        TriggerServerEvent('ShopRobbery:IsActive')
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        robberyActive = false
        robbing = false
        robbedShopCoords = nil
        deathCheckThread = nil
        distanceCheckThread = nil
        print("^2[ShopRobbery]^7 Client cleanup completed")
    end
end)