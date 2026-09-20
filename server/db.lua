CreateThread(function()
	local columns = MySQL.query.await('SHOW COLUMNS FROM `characters`')
	local hasGang = false

	if columns then
		for i = 1, #columns do
			if columns[i].Field == 'gang' then
				hasGang = true
				break
			end
		end
	end

	if not hasGang then
		MySQL.query.await([[
			ALTER TABLE `characters` ADD COLUMN `gang` longtext NOT NULL DEFAULT '{"name":false,"rank":0,"lastupdate":false}'
		]])
	end

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `gs_gang_ledgers` (
			`gang_name` VARCHAR(64) NOT NULL,
			`amount` INT NOT NULL DEFAULT 0,
			PRIMARY KEY (`gang_name`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `gs_gang_ledger_logs` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`gang_name` VARCHAR(64) NOT NULL,
			`charidentifier` INT DEFAULT NULL,
			`player_name` VARCHAR(128) NOT NULL DEFAULT '',
			`entry_type` VARCHAR(16) NOT NULL,
			`amount` INT NOT NULL DEFAULT 0,
			`created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `idx_gang_created` (`gang_name`, `created_at`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	DevPrint('Database Ready')
end)
