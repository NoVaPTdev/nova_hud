local interface = require("modules.interface.client")
local config = require("config.shared")
local utility = require("modules.utils.shared")
local debug = utility.debug

-- Configurar minimap ao iniciar (não depende de callback do UI)
CreateThread(function()
	Wait(500)
	CreateThread(utility.setupMinimap)
	debug("(nuicb) Minimap setup iniciado.")
end)

-- Callback: cycleVoice (o novo React UI envia isto quando o jogador clica no indicador de voz)
RegisterNuiCallback("cycleVoice", function(data, cb)
	debug("(nuicb:cycleVoice) Voice level cycled to: ", data.level)
	-- Aqui podes integrar com pma-voice ou outro sistema de voz
	-- Exemplo: exports['pma-voice']:setVoiceProperty('proximity', data.level)
	cb("ok")
end)

-- Manter callback antigo para compatibilidade (caso algo ainda o chame)
RegisterNuiCallback("uiLoaded", function(_, cb)
	local data = {
		config = config,
		minimap = utility.calculateMinimapSizeAndPosition(),
	}
	cb(data)
	debug("(nuicb:uiLoaded) Legacy callback triggered.")
end)
