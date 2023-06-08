--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'lu-parking'

--[[ Manifest ]]--
shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua',
}

dependencies {
	'ox_lib',
	'oxmysql',
}

escrow_ignore {
	'config.lua',
	'client/cl_functions.lua',
	'server/sv_functions.lua',
}

