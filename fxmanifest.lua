fx_version 'cerulean'
game 'gta5'

lua54 'yes'

description 'vehiclekeys for ox_core'
version '0.0.1'

dependencies {
	"/onesync",
	"ox_core",
	"ox_lib",
	"ox_inventory",
}

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'@ox_core/imports/client.lua',
	'client/main.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'@ox_core/imports/server.lua',
	'server/main.lua'
}
-- files {
-- 	'config.json'
-- }

exports {
	'lockpick',
	'setKeys',
	'checkKeys'
}
