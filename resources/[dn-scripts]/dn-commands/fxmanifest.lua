fx_version 'cerulean'
games { 'gta5' }

dependency "vrp"

client_scripts {
    "revive/client.lua",
	"fixveh/client.lua",
    "dv/client.lua"
}

server_scripts {
    "@vrp/lib/utils.lua",
    "revive/server.lua",
	"fixveh/server.lua",
    "dv/server.lua"
}