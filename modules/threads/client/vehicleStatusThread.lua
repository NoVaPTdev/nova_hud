local utility = require("modules.utils.shared")
local functions = require("config.functions")
local config = require("config.shared")
local sharedFunctions = require("config.functions")
local debug = utility.debug

local VehicleStatusThread = {}
VehicleStatusThread.__index = VehicleStatusThread

function VehicleStatusThread.new(playerStatus, seatbeltLogic)
	local self = setmetatable({}, VehicleStatusThread)
	self.playerStatus = playerStatus
	self.seatbelt = seatbeltLogic

	SetHudComponentPosition(6, 999999.0, 999999.0) -- VEHICLE NAME
	SetHudComponentPosition(7, 999999.0, 999999.0) -- AREA NAME
	SetHudComponentPosition(8, 999999.0, 999999.0) -- VEHICLE CLASS
	SetHudComponentPosition(9, 999999.0, 999999.0) -- STREET  NAME

	return self
end

function VehicleStatusThread:start()
	CreateThread(function()
		local ped = PlayerPedId()
		local playerStatusThread = self.playerStatus
		local convertEngineHealthToPercentage = utility.convertEngineHealthToPercentage

		playerStatusThread:setIsVehicleThreadRunning(true)

		while IsPedInAnyVehicle(ped, false) do
			local vehicle = GetVehiclePedIsIn(ped, false)
			local engineHealth = convertEngineHealthToPercentage(GetVehicleEngineHealth(vehicle))
			local speed = math.floor(GetEntitySpeed(vehicle) * 3.6) -- km/h
			local fuelValue = math.max(0, math.min(functions.getVehicleFuel(vehicle), 100))
			local fuel = math.floor(fuelValue)
			local currentGear = GetVehicleCurrentGear(vehicle)

			-- Gear display string
			local gearStr = "N"
			if currentGear == 0 then
				gearStr = "R"
			elseif currentGear == 1 and speed < 2 then
				gearStr = "N"
			else
				gearStr = tostring(currentGear)
			end

			-- Seatbelt state
			local isSeatbeltOn = false
			if config.useBuiltInSeatbeltLogic and self.seatbelt then
				isSeatbeltOn = self.seatbelt.seatbeltState or false
			else
				isSeatbeltOn = sharedFunctions.isSeatbeltOn()
			end

			-- Vehicle lock state (2 = locked, 10 = locked hard)
			local lockStatus = GetVehicleDoorLockStatus(vehicle)
			local isLocked = (lockStatus == 2 or lockStatus == 10)

		-- Enviar TODOS os dados de veículo numa só mensagem
		-- NOTA: Usar inteiros (1/0) em vez de booleans porque FiveM CEF
		-- converte Lua 'false' para null/undefined em JavaScript!
		SendNUIMessage({
			type = "updateVehicle",
			inVehicle = 1,
			speed = speed,
			fuel = fuel,
			gear = gearStr,
			engineHealth = engineHealth,
			seatbelt = isSeatbeltOn and 1 or 0,
			locked = isLocked and 1 or 0,
		})

			Wait(120)
		end

	-- A sair do veículo - enviar estado limpo
	-- Usar 0 em vez de false (FiveM CEF perde booleans false)
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

		if self.seatbelt then
			debug("(vehicleStatusThread) seatbelt found, toggling to false")
			self.seatbelt:toggle(false)
		end

		playerStatusThread:setIsVehicleThreadRunning(false)
		debug("(vehicleStatusThread) Vehicle status thread ended.")
	end)
end

return VehicleStatusThread
