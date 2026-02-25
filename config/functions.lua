return {
	isSeatbeltOn = function() -- Repalce this with your own seatbelt logic if your not using the built in seatbelt logic.
		return false
	end,
	getVehicleFuel = function(currentVehicle) -- Uses nova_fuel exports
		local ok, fuel = pcall(function() return exports['nova_fuel']:GetFuel(currentVehicle) end)
		if ok and fuel then return fuel end
		return GetVehicleFuelLevel(currentVehicle)
	end,
}
