--@diagnostic disable: undefined-global
fx_version("cerulean")
game("gta5")

name("nova_hud")
author("NOVA Framework")
description("NOVA HUD - Sistema de HUD Minimalista")
version("5.1.0")

shared_scripts({
	"require.lua",
})

client_scripts({
	"client/main.lua",
	"client/nuicb.lua",
	"client/commands.lua",
})

server_scripts({
	"server/main.lua",
})

ui_page("dist/index.html")

files({
	"dist/index.html",
	"dist/assets/*.js",
	"dist/assets/*.css",
	"config/shared.lua",
	"config/functions.lua",
	"modules/interface/client.lua",
	"modules/utils/shared.lua",
	"modules/seatbelt/client.lua",
	"modules/frameworks/**/*.lua",
	"modules/threads/client/**/*.lua",
	"data/mapData.lua",
	"stream/hud_reticle.gfx",
	"stream/minimap.gfx",
})

-- Exports declarados para discovery por outros devs
exports({
	"toggleHud",
	"showServerLabel",
	"hideServerLabel",
})

lua54("yes")

dependencies({
	"nova_core",
})
