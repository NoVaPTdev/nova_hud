local debug = require("modules.utils.shared").debug

local novaFramework = {}
novaFramework.__index = novaFramework

-- Cache local dos valores
local playerHunger = 100
local playerThirst = 100
local playerStress = 0
local isPlayerLoaded = false

function novaFramework.new()
	debug("(novaFramework:new) Created new instance for NOVA Framework.")
	local self = setmetatable({}, novaFramework)

	-- Escutar evento de player loaded para obter metadata inicial
	AddEventHandler('nova:client:playerLoaded', function(playerData)
		if playerData and playerData.metadata then
			playerHunger = playerData.metadata.hunger or 100
			playerThirst = playerData.metadata.thirst or 100
			playerStress = playerData.metadata.stress or 0
		end
		isPlayerLoaded = true
		debug("(novaFramework) Player loaded - hunger:", playerHunger, "thirst:", playerThirst, "stress:", playerStress)
	end)

	-- Escutar atualizações de metadata em tempo real
	AddEventHandler('nova:client:onPlayerDataUpdate', function(dataType, data)
		if dataType == 'metadata' and data then
			playerHunger = data.hunger or playerHunger
			playerThirst = data.thirst or playerThirst
			playerStress = data.stress or playerStress
			debug("(novaFramework) Metadata updated - hunger:", playerHunger, "thirst:", playerThirst)
		elseif dataType == 'all' and data and data.metadata then
			playerHunger = data.metadata.hunger or playerHunger
			playerThirst = data.metadata.thirst or playerThirst
			playerStress = data.metadata.stress or playerStress
			debug("(novaFramework) Full data updated")
		end
	end)

	-- Escutar logout para resetar
	AddEventHandler('nova:client:onLogout', function()
		playerHunger = 100
		playerThirst = 100
		playerStress = 0
		isPlayerLoaded = false
		debug("(novaFramework) Player logout - valores resetados")
	end)

	-- Thread de polling como fallback (caso eventos falhem)
	CreateThread(function()
		while true do
			if GetResourceState('nova_core') == 'started' then
				-- Método 1: Usar export GetPlayerData() (mais fiável)
				local success, playerData = pcall(exports['nova_core'].GetPlayerData, exports['nova_core'])
				if success and playerData and playerData.metadata then
					local meta = playerData.metadata
					playerHunger = meta.hunger or playerHunger
					playerThirst = meta.thirst or playerThirst
					playerStress = meta.stress or playerStress
				else
					-- Método 2: Fallback para GetObject()
					local ok2, Nova = pcall(exports['nova_core'].GetObject, exports['nova_core'])
					if ok2 and Nova and Nova.PlayerData and Nova.PlayerData.metadata then
						local meta = Nova.PlayerData.metadata
						playerHunger = meta.hunger or playerHunger
						playerThirst = meta.thirst or playerThirst
						playerStress = meta.stress or playerStress
					end
				end
			end
			Wait(2000) -- Polling a cada 2 segundos como fallback
		end
	end)

	return self
end

function novaFramework:getPlayerHunger()
	return playerHunger
end

function novaFramework:getPlayerThirst()
	return playerThirst
end

function novaFramework:getPlayerStress()
	return playerStress
end

return novaFramework
