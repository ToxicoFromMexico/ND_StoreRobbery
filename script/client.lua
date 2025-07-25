local robberyActive = false
local robbing = false
local robbedShopCoords = nil
local deathCheckThread = nil
local distanceCheckThread = nil

-- Load language
local langFile = LoadResourceFile(GetCurrentResourceName(), "locales/"..config.language..".lua")
assert(load(langFile))()

RegisterNetEvent('ShopRobbery:IsActive:Return')
AddEventHandler('ShopRobbery:IsActive:Return', function(bool)
	robberyActive = bool
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if not robberyActive then
			for _, shopcoords in pairs(config.shopcoords) do
				DrawMarker(27, shopcoords.x, shopcoords.y, shopcoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, .2, 255, 0, 0, 255, false, true, 2, false, nil, nil, false)
			end
		end

		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		for _, shopcoords in pairs(config.shopcoords) do
				if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, shopcoords.x, shopcoords.y, shopcoords.z, true) < 5.0 then
					DisplayNotification(locale.Start)
					if IsControlJustReleased(0, 38) and not robberyActive then -- E
						TriggerServerEvent('ShopRobbery:SetActive', true)
						TriggerServerEvent("ShopRobbery:Disps")
						TriggerEvent("ShopRobbery:Ann")
						robbing = true
						robbedShopCoords = shopcoords

						-- Death check thread
						if deathCheckThread == nil then
							deathCheckThread = Citizen.CreateThread(function()
								while robbing do
									Citizen.Wait(500)
									if IsEntityDead(playerPed) then
										TriggerServerEvent("ShopRobbery:Fail")
										robbing = false
										TriggerServerEvent("ShopRobbery:Cancel")
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
										robbing = false
										TriggerServerEvent("ShopRobbery:Cancel")
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
