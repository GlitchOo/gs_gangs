CreateThread(function()
    local colums = MySQL.query.await('SHOW COLUMNS FROM `characters`')

    for i = 1, #colums, 1 do
        if colums[i].Field == 'gang' then
            return DevPrint('Database Ready')
        end
    end

    MySQL.query.await([[
        ALTER TABLE `characters` ADD COLUMN `gang` longtext NOT NULL DEFAULT '{"name":false,"rank":0,"lastupdate":false}'
    ]])

    DevPrint('Database Ready')
end)