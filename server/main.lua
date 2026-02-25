CreateThread(function()
	print('^2[NOVA] ^7Sistema de HUD carregado (nova_hud v5.1.0)')
end)

-- Quando o jogador morre, informar todos os outros (opcional, para efeitos visuais)
RegisterNetEvent('nova:server:onPlayerDeath', function()
	local src = source
	-- Reenviar para o client do jogador que morreu
	TriggerClientEvent('nova:client:onPlayerDeath', src)
end)

-- Comando admin para forçar toggle do HUD de um jogador
RegisterCommand("toggleplayerhud", function(source, args)
	local targetId = tonumber(args[1])
	if targetId then
		TriggerClientEvent('nova_hud:toggleFromServer', targetId)
	end
end, true) -- restricted to admins

RegisterNetEvent('nova_hud:toggleFromServer', function()
	-- Handler no client (registered in client/main.lua exports)
end)
