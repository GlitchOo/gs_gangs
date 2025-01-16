fx_version "cerulean"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54 "yes"

author '_G[S]cripts'
description 'Gang for RedM'
version '1.0.0'

shared_scripts {
  'config.lua',
  'utils/*.lua',
}

client_scripts {
  'utils/client/*.lua',
  'client/*.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/*.lua'
}

files {
  'locales/*.json'
}