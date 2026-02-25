---@diagnostic disable: cast-local-type
local mapData = require("data.mapData")
local debug = require("modules.utils.shared").debug
local config = require("config.shared")
local utility = require("modules.utils.shared")

local PlayerStatusThread = {}
PlayerStatusThread.__index = PlayerStatusThread

PlayerStatusThread.registry = {}

---@param identifier string
---@return table
function PlayerStatusThread.new(identifier)
	local self = setmetatable({}, PlayerStatusThread)
	self.identifier = identifier
	self.isVehicleThreadRunning = false

	PlayerStatusThread.registry[identifier] = self

	debug("(PlayerStatusThread:new) Created new instance with identifier: ", identifier)
	return self
end

function PlayerStatusThread:getIsVehicleThreadRunning()
	return self.isVehicleThreadRunning
end

---@param value boolean
function PlayerStatusThread:setIsVehicleThreadRunning(value)
	debug("(PlayerStatusThread:setIsVehicleThreadRunning) Setting: ", value)
	self.isVehicleThreadRunning = value
end

function PlayerStatusThread:start(vehicleStatusThread, seatbeltLogic, framework)
	CreateThread(function()
		while true do
			local ped = PlayerPedId()
			local coords = GetEntityCoords(ped)
			local currentStreet, currentArea = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

			currentStreet = GetStreetNameFromHashKey(currentStreet)
			currentArea = GetStreetNameFromHashKey(currentArea)

			local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

			if mapData.streets[currentStreet] then
				currentStreet = mapData.streets[currentStreet]
			end

			if mapData.areas[currentArea] then
				currentArea = mapData.areas[currentArea]
			end

			local pedArmor = GetPedArmour(ped)
			local pedHealthUnrestricted = math.floor(GetEntityHealth(ped) / GetEntityMaxHealth(ped) * 100)
			local pedHealth = math.max(0, math.min(pedHealthUnrestricted, 100))
		local pedHunger = math.floor(framework and framework:getPlayerHunger() or 100)
		local pedThirst = math.floor(framework and framework:getPlayerThirst() or 100)

			-- Stamina: GetPlayerSprintStaminaRemaining returns 0.0-100.0 (100 = full)
			local pedStamina = math.floor(GetPlayerSprintStaminaRemaining(PlayerId()))

			-- Oxygen: only relevant when underwater
			local isUnderwater = IsPedSwimmingUnderWater(ped)
			local pedOxygen = 100
			if isUnderwater then
				local remaining = GetPlayerUnderwaterTimeRemaining(PlayerId())
				pedOxygen = math.floor(math.max(0, math.min(remaining * 10, 100)))
			end

			local isInVehicle = IsPedInAnyVehicle(ped, false)

			-- Iniciar vehicle thread se em veículo
			if isInVehicle and not self:getIsVehicleThreadRunning() and vehicleStatusThread then
				vehicleStatusThread:start()
				debug("(playerStatus) (vehicleStatusThread) Vehicle status thread started.")
			end

		-- Se NÃO está em veículo, enviar estado base do veículo
		-- Usar 0 em vez de false (FiveM CEF perde booleans false)
		if not isInVehicle then
			SendNUIMessage({
				type = "updateVehicle",
				inVehicle = 0,
				speed = 0,
				fuel = 0,
				gear = "N",
				engineHealth = 100,
				seatbelt = 0,
				locked = 0,
			})
		end

			-- Enviar updateHUD (vitais)
			SendNUIMessage({
				type = "updateHUD",
				health = pedHealth,
				armor = pedArmor,
				hunger = pedHunger,
				thirst = pedThirst,
				stamina = pedStamina,
				oxygen = pedOxygen,
			})

			-- Enviar updateLocation
			SendNUIMessage({
				type = "updateLocation",
				street = currentStreet,
				zone = zone,
			})

		-- Enviar updateEnvironment (usar 1/0 em vez de boolean)
		SendNUIMessage({
			type = "updateEnvironment",
			isUnderwater = isUnderwater and 1 or 0,
		})

			Wait(1000)
		end
	end)
end

---@param identifier string
function PlayerStatusThread.getInstanceById(identifier)
	return PlayerStatusThread.registry[identifier]
end

return PlayerStatusThread
