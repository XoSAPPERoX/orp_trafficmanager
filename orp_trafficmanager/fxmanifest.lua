fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Traffic Control NUI'
author 'xoSAPPERox'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}