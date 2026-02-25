-- Core Logic
local config = require("config.shared")
local playerStatusClass = require("modules.threads.client.playerStatus")
local vehicleStatusClass = require("modules.threads.client.vehicleStatusThread")
local seatbeltLogicClass = require("modules.seatbelt.client")
local utility = require("modules.utils.shared")
local interface = require("modules.interface.client")
local debug = utility.debug

local seatbeltLogic = seatbeltLogicClass.new()
local playerStatusThread = playerStatusClass.new("main")
local vehicleStatusThread = vehicleStatusClass.new(playerStatusThread, seatbeltLogic)
local framework = utility.isFrameworkValid() and require("modules.frameworks." .. config.framework:lower()).new()
	or false

playerStatusThread:start(vehicleStatusThread, seatbeltLogic, framework)

-- ═══════════════════════════════════════════════════════════════════
-- HUD Visibility Control
-- ═══════════════════════════════════════════════════════════════════

-- Esconder HUD ao iniciar (só mostrar quando o jogador spawnar)
interface.toggle(false)
DisplayRadar(false) -- Esconder minimap nativo ao iniciar (só mostrar em veículo)

-- Esperar que o framework esteja pronto, verificar se já está loaded
CreateThread(function()
	-- Esperar pelo nova_core
	while GetResourceState('nova_core') ~= 'started' do
		Wait(500)
	end

	-- Verificar se o jogador já está loaded (reconexão rápida)
	local ok, isLoaded = pcall(exports['nova_core'].IsPlayerLoaded, exports['nova_core'])
	if ok and isLoaded then
		interface.toggle(true)
		debug("(init) Player já estava loaded, HUD mostrado")
	end
end)

-- Mostrar HUD quando o jogador carrega o personagem
RegisterNetEvent('nova:client:onPlayerLoaded', function()
	interface.toggle(true)
	debug("(onPlayerLoaded) HUD mostrado")
end)

-- Backup: também ouvir o evento local (triggered por nova_core após processar)
RegisterNetEvent('nova:client:playerLoaded', function()
	interface.toggle(true)
	debug("(playerLoaded) HUD mostrado via evento local")
end)

-- Esconder HUD quando o jogador faz logout
RegisterNetEvent('nova:client:onLogout', function()
	interface.toggle(false)
	debug("(onLogout) HUD escondido")
end)

-- Esconder HUD quando o jogador morre
RegisterNetEvent('nova:client:onPlayerDeath', function()
	SendNUIMessage({ type = "hideHUD" })
	debug("(onPlayerDeath) HUD escondido - jogador morreu")
end)

-- Mostrar HUD quando o jogador é revivido
RegisterNetEvent('nova:client:onRevive', function()
	SendNUIMessage({ type = "showHUD" })
	debug("(onRevive) HUD mostrado - jogador revivido")
end)

-- ═══════════════════════════════════════════════════════════════════
-- Minimap Anchor - posição dinâmica do minimap
-- ═══════════════════════════════════════════════════════════════════

local PAD = 10 -- Padding do vital frame à volta do minimap (deve corresponder ao PAD no Minimap.tsx)

local function GetMinimapAnchor()
	local resX, resY = GetActiveScreenResolution()
	local aspectRatio = resX / resY
	local defaultAspectRatio = 1920 / 1080
	local minimapOffset = 0
	local safezoneSize = GetSafeZoneSize()

	if aspectRatio > defaultAspectRatio then
		minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
	end

	-- Valores que correspondem EXATAMENTE ao SetMinimapComponentPosition no setupMinimap
	local normLeft = 0.0 + minimapOffset
	local normWidth = 0.1638
	local normHeight = 0.183
	local normBottomFromTop = 1.0 - 0.047 -- posição Y do fundo do minimap (de cima)

	-- Aplicar safezone
	local safezoneOffset = (1.0 - safezoneSize) * 0.5
	normLeft = normLeft + safezoneOffset
	normBottomFromTop = normBottomFromTop - safezoneOffset

	-- Converter para pixels
	local leftPx = math.floor(normLeft * resX)
	local widthPx = math.floor(normWidth * resX)
	local heightPx = math.floor(normHeight * resY)
	local topPx = math.floor((normBottomFromTop - normHeight) * resY)

	return {
		leftPx = leftPx,
		topPx = topPx,
		widthPx = widthPx,
		heightPx = heightPx,
	}
end

local function SendMinimapAnchor()
	local anchor = GetMinimapAnchor()
	-- Subtrair PAD porque o React coloca o minimap area a PAD pixels dentro do frame
	local cssLeft = anchor.leftPx - PAD
	local cssTop = anchor.topPx - PAD

	SendNUIMessage({
		type   = "minimapAnchor",
		left   = cssLeft,
		top    = cssTop,
		width  = anchor.widthPx,
		height = anchor.heightPx,
	})
	debug("(minimapAnchor) Enviado: left=" .. cssLeft .. " top=" .. cssTop .. " w=" .. anchor.widthPx .. " h=" .. anchor.heightPx)
end

-- Enviar posição do minimap ao iniciar
CreateThread(function()
	Wait(2000) -- Esperar o jogo iniciar completamente
	SendMinimapAnchor()
end)

-- Re-enviar se a resolução/safezone mudar
CreateThread(function()
	local lastResX, lastResY = GetActiveScreenResolution()
	local lastSafeZone = GetSafeZoneSize()

	while true do
		Wait(5000)
		local resX, resY = GetActiveScreenResolution()
		local safeZone = GetSafeZoneSize()

		if resX ~= lastResX or resY ~= lastResY or safeZone ~= lastSafeZone then
			lastResX, lastResY, lastSafeZone = resX, resY, safeZone
			SendMinimapAnchor()
			debug("(minimapAnchor) Resolução/safezone mudou, re-enviado")
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- Esconder HUD components nativos do GTA V
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
	while true do
		HideHudComponentThisFrame(2)   -- Weapon icon / ammo
		HideHudComponentThisFrame(3)   -- Cash
		HideHudComponentThisFrame(4)   -- MP Cash / Bank
		HideHudComponentThisFrame(13)  -- Cash Change notification
		Wait(0)
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- Minimap Radar Visibility — esconder minimap nativo quando a pé
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
	local wasInVehicle = false

	while true do
		local ped = PlayerPedId()
		local isInVehicle = IsPedInAnyVehicle(ped, false)

		if isInVehicle and not wasInVehicle then
			-- Entrou no veículo — mostrar minimap e enviar anchor
			DisplayRadar(true)
			Wait(200)
			SendMinimapAnchor()
			wasInVehicle = true
			debug("(minimap) Jogador entrou no veículo, radar ON")
		elseif not isInVehicle and wasInVehicle then
			-- Saiu do veículo — esconder minimap
			DisplayRadar(false)
			wasInVehicle = false
			debug("(minimap) Jogador saiu do veículo, radar OFF")
		elseif not isInVehicle and not wasInVehicle then
			-- A pé — garantir que o radar está off
			DisplayRadar(false)
		end

		Wait(300)
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- Server ID
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
	-- Esperar pelo player data para obter o charId persistente
	local charId = nil
	while not charId do
		local ok, pd = pcall(exports['nova_core'].GetPlayerData, exports['nova_core'])
		if ok and pd and pd.charid then
			charId = pd.charid
		end
		Wait(2000)
	end

	SendNUIMessage({ type = "updateServerId", serverId = charId })
end)

-- ═══════════════════════════════════════════════════════════════════
-- Voice + Radio
-- ═══════════════════════════════════════════════════════════════════

CreateThread(function()
	local lastVoice, lastTalking, lastRadio = -1, -1, -1
	while true do
		-- Nível de voz (pma-voice proximity)
		local voiceIndex = 2 -- default Normal
		local ok, prox = pcall(function()
			return LocalPlayer.state.proximity
		end)
		if ok and prox and prox.index then
			voiceIndex = prox.index
		end

		-- Frequência de rádio (nova_radio ou pma-voice)
		local radioFreq = 0
		-- Tentar nova_radio primeiro
		local okr, freq = pcall(function()
			return exports['nova_radio']:GetCurrentChannel()
		end)
		if okr and freq and freq > 0 then
			radioFreq = freq
		else
			-- Tentar pma-voice radio channel
			local okp, pfreq = pcall(function()
				return LocalPlayer.state.radioChannel
			end)
			if okp and pfreq and pfreq > 0 then
				radioFreq = pfreq
			end
		end

		-- Detetar se o jogador está a falar
		local isTalking = NetworkIsPlayerTalking(PlayerId()) and 1 or 0

		-- Enviar voice update apenas se mudou
		if voiceIndex ~= lastVoice or isTalking ~= lastTalking then
			lastVoice = voiceIndex
			lastTalking = isTalking
			SendNUIMessage({
				type = "updateVoice",
				level = voiceIndex,
				isTalking = isTalking,
			})
		end

		-- Enviar radio update apenas se mudou
		if radioFreq ~= lastRadio then
			lastRadio = radioFreq
			SendNUIMessage({
				type = "updateRadio",
				frequency = radioFreq > 0 and string.format("%.1f MHz", radioFreq) or "",
			})
		end

		Wait(500)
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- Weapon HUD — arma equipada + munição
-- ═══════════════════════════════════════════════════════════════════

local weaponGroups = {
	[GetHashKey("GROUP_PISTOL")]    = "pistol",
	[GetHashKey("GROUP_SMG")]       = "smg",
	[GetHashKey("GROUP_RIFLE")]     = "rifle",
	[GetHashKey("GROUP_MG")]        = "rifle",
	[GetHashKey("GROUP_SHOTGUN")]   = "shotgun",
	[GetHashKey("GROUP_SNIPER")]    = "sniper",
	[GetHashKey("GROUP_HEAVY")]     = "heavy",
	[GetHashKey("GROUP_MELEE")]     = "melee",
	[GetHashKey("GROUP_THROWN")]    = "throwable",
	[GetHashKey("GROUP_PETROLCAN")] = "melee",
	[GetHashKey("GROUP_FIREEXTINGUISHER")] = "melee",
	[GetHashKey("GROUP_STUNGUN")]   = "pistol",
}

local UNARMED_HASH = GetHashKey("WEAPON_UNARMED")

CreateThread(function()
	local lastHash = 0
	local lastClip = -1
	local lastTotal = -1

	while true do
		local ped = PlayerPedId()
		local _, weaponHash = GetCurrentPedWeapon(ped, true)

		if weaponHash == UNARMED_HASH or weaponHash == 0 then
			if lastHash ~= 0 then
				SendNUIMessage({ type = "updateWeapon", equipped = false })
				lastHash = 0
				lastClip = -1
				lastTotal = -1
			end
			Wait(500)
		else
			local _, ammoClip = GetAmmoInClip(ped, weaponHash)
			local ammoTotal = GetAmmoInPedWeapon(ped, weaponHash) - ammoClip
			if ammoTotal < 0 then ammoTotal = 0 end

			local group = GetWeapontypeGroup(weaponHash)
			local category = weaponGroups[group] or "unknown"

			if weaponHash ~= lastHash or ammoClip ~= lastClip or ammoTotal ~= lastTotal then
				SendNUIMessage({
					type = "updateWeapon",
					equipped = true,
					category = category,
					ammoClip = ammoClip,
					ammoTotal = ammoTotal,
				})
				lastHash = weaponHash
				lastClip = ammoClip
				lastTotal = ammoTotal
			end

			Wait(100)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- Assalto Liberado — label automático baseado na hora do jogo
-- ═══════════════════════════════════════════════════════════════════

local ASSALTO_START = 20  -- 20:00
local ASSALTO_END   = 6   -- 06:00

CreateThread(function()
	local wasActive = false

	while true do
		local hour = GetClockHours()
		local isActive = hour >= ASSALTO_START or hour < ASSALTO_END

		if isActive and not wasActive then
			SendNUIMessage({ type = "showLabel", label = "ASSALTO LIBERADO" })
			wasActive = true
		elseif not isActive and wasActive then
			SendNUIMessage({ type = "hideLabel" })
			wasActive = false
		end

		Wait(5000)
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- Server-driven HUD toggle (admin command)
-- ═══════════════════════════════════════════════════════════════════

RegisterNetEvent('nova_hud:toggleFromServer', function()
	interface.toggle()
	debug("(nova_hud:toggleFromServer) HUD toggled by server/admin")
end)

-- ═══════════════════════════════════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════════════════════════════════

exports("toggleHud", function(state)
	if state == nil then
		-- toggle
		interface.toggle()
	elseif state then
		interface.toggle(true)
	else
		interface.toggle(false)
	end
	debug("(exports:toggleHud) Toggled HUD to state: ", state)
end)

-- Export para mostrar label no servidor (ex: "Assalto Liberado")
exports("showServerLabel", function(label)
	if label and label ~= "" then
		SendNUIMessage({ type = "showLabel", label = tostring(label) })
		debug("(exports:showServerLabel) Mostrando label:", label)
	end
end)

-- Export para esconder label
exports("hideServerLabel", function()
	SendNUIMessage({ type = "hideLabel" })
	debug("(exports:hideServerLabel) Label escondida")
end)
