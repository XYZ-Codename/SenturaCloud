local function executeQuery(query, params, callback)
  local isCreateTableQuery = query:match("^CREATE%s+TABLE")
  exports.oxmysql:execute(query, params, function(result)
      if callback then
          callback(result)
      end
  end, function(error)
      if not isCreateTableQuery then
          print("Error executing query: ", error)
      end
  end)
end
local queries = {
  "CREATE TABLE IF NOT EXISTS `vrp_srv_data` (" ..
      "`dkey` varchar(255) NOT NULL, " ..
      "`dvalue` text DEFAULT NULL, " ..
      "PRIMARY KEY (`dkey`)" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_users` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`last_login` varchar(255) DEFAULT NULL, " ..
      "`last_date` varchar(255) NOT NULL DEFAULT '', " ..
      "`whitelisted` tinyint(1) DEFAULT NULL, " ..
      "`banned` tinyint(1) DEFAULT NULL, " ..
      "`DmvTest` int(11) NOT NULL DEFAULT 0, " ..
      "`warnings` int(11) NOT NULL DEFAULT 0, " ..
      "`ban_reason` varchar(250) DEFAULT NULL, " ..
      "`discord` varchar(250) DEFAULT NULL, " ..
      "PRIMARY KEY (`id`)" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_business` (" ..
      "`user_id` int(11) NOT NULL, " ..
      "`name` varchar(30) DEFAULT NULL, " ..
      "`description` text DEFAULT NULL, " ..
      "`capital` int(11) DEFAULT NULL, " ..
      "`laundered` int(11) DEFAULT NULL, " ..
      "`reset_timestamp` int(11) DEFAULT NULL, " ..
      "PRIMARY KEY (`user_id`), " ..
      "CONSTRAINT `fk_user_business_users` FOREIGN KEY (`user_id`) REFERENCES `vrp_users` (`id`) ON DELETE CASCADE" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_data` (" ..
      "`user_id` int(11) NOT NULL, " ..
      "`dkey` varchar(255) NOT NULL, " ..
      "`dvalue` text DEFAULT NULL, " ..
      "PRIMARY KEY (`user_id`, `dkey`), " ..
      "CONSTRAINT `fk_user_data_users` FOREIGN KEY (`user_id`) REFERENCES `vrp_users` (`id`) ON DELETE CASCADE" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_homes` (" ..
      "`user_id` int(11) NOT NULL, " ..
      "`home` varchar(255) DEFAULT NULL, " ..
      "`number` int(11) DEFAULT NULL, " ..
      "PRIMARY KEY (`user_id`), " ..
      "CONSTRAINT `fk_user_homes_users` FOREIGN KEY (`user_id`) REFERENCES `vrp_users` (`id`) ON DELETE CASCADE" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_identities` (" ..
      "`user_id` int(11) NOT NULL, " ..
      "`registration` varchar(100) DEFAULT NULL, " ..
      "`phone` varchar(100) DEFAULT NULL, " ..
      "`firstname` varchar(100) DEFAULT NULL, " ..
      "`name` varchar(100) DEFAULT NULL, " ..
      "`age` int(11) DEFAULT NULL, " ..
      "PRIMARY KEY (`user_id`)" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_ids` (" ..
      "`identifier` varchar(255) NOT NULL, " ..
      "`user_id` int(11) DEFAULT NULL, " ..
      "PRIMARY KEY (`identifier`), " ..
      "CONSTRAINT `fk_user_ids_users` FOREIGN KEY (`user_id`) REFERENCES `vrp_users` (`id`) ON DELETE CASCADE" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_moneys` (" ..
      "`user_id` int(11) NOT NULL, " ..
      "`wallet` int(11) DEFAULT NULL, " ..
      "`bank` int(11) DEFAULT NULL, " ..
      "`debt` int(11) DEFAULT 0, " ..
      "`depositOnLogin` int(11) DEFAULT 0, " ..
      "PRIMARY KEY (`user_id`), " ..
      "CONSTRAINT `fk_user_moneys_users` FOREIGN KEY (`user_id`) REFERENCES `vrp_users` (`id`) ON DELETE CASCADE" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `vrp_user_vehicles` (" ..
      "`user_id` int(11) NOT NULL, " ..
      "`vehicle` varchar(100) NOT NULL, " ..
      "`veh_type` varchar(255) NOT NULL DEFAULT 'default', " ..
      "`vehicle_plate` varchar(255) NOT NULL, " ..
      "`impound` int(11) NOT NULL DEFAULT 0, " ..
      "`hashkey` varchar(255) DEFAULT NULL, " ..
      "`vehicle_colorprimary` varchar(255) DEFAULT NULL, " ..
      "`modifications` mediumtext NOT NULL, " ..
      "`vehicle_colorsecondary` varchar(255) DEFAULT NULL, " ..
      "`vehicle_fuel` varchar(50) DEFAULT '60.0', " ..
      "`vehicle_damage` varchar(50) DEFAULT '1000.0', " ..
      "PRIMARY KEY (`user_id`, `vehicle`)" ..
  ") ENGINE=MyISAM DEFAULT CHARSET=latin1;",

"CREATE TABLE IF NOT EXISTS `vrp_wanted` (" ..
    "`user_id` int(11) DEFAULT NULL, " ..
    "`wantedreason` varchar(100) DEFAULT NULL, " ..
    "`wantedby` int(11) DEFAULT NULL, " ..
    "`timestamp` int(11) DEFAULT NULL, " ..
    "`count` int(11) DEFAULT NULL, " ..
    "UNIQUE KEY (`user_id`)" ..
") ENGINE=InnoDB DEFAULT CHARSET=latin1;",

  "CREATE TABLE IF NOT EXISTS `player_contacts` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`citizenid` varchar(50) DEFAULT NULL, " ..
      "`name` varchar(50) DEFAULT NULL, " ..
      "`number` varchar(50) DEFAULT NULL, " ..
      "`iban` varchar(50) NOT NULL DEFAULT '0', " ..
      "PRIMARY KEY (`id`), " ..
      "KEY `citizenid` (`citizenid`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;",

  "CREATE TABLE IF NOT EXISTS `phone_invoices` (" ..
      "`id` int(10) NOT NULL AUTO_INCREMENT, " ..
      "`citizenid` varchar(50) DEFAULT NULL, " ..
      "`amount` int(11) NOT NULL DEFAULT 0, " ..
      "`society` tinytext DEFAULT NULL, " ..
      "`sender` varchar(50) DEFAULT NULL, " ..
      "`sendercitizenid` varchar(50) DEFAULT NULL, " ..
      "PRIMARY KEY (`id`), " ..
      "KEY `citizenid` (`citizenid`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;",

  "CREATE TABLE IF NOT EXISTS `phone_messages` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`citizenid` varchar(50) DEFAULT NULL, " ..
      "`number` varchar(50) DEFAULT NULL, " ..
      "`messages` text DEFAULT NULL, " ..
      "PRIMARY KEY (`id`), " ..
      "KEY `citizenid` (`citizenid`), " ..
      "KEY `number` (`number`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;",

  "CREATE TABLE IF NOT EXISTS `player_mails` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`citizenid` varchar(50) DEFAULT NULL, " ..
      "`sender` varchar(50) DEFAULT NULL, " ..
      "`subject` varchar(50) DEFAULT NULL, " ..
      "`message` text DEFAULT NULL, " ..
      "`read` tinyint(4) DEFAULT 0, " ..
      "`mailid` int(11) DEFAULT NULL, " ..
      "`date` timestamp NULL DEFAULT current_timestamp(), " ..
      "`button` text DEFAULT NULL, " ..
      "PRIMARY KEY (`id`), " ..
      "KEY `citizenid` (`citizenid`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;",

  "CREATE TABLE IF NOT EXISTS `crypto_transactions` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`citizenid` varchar(50) DEFAULT NULL, " ..
      "`title` varchar(50) DEFAULT NULL, " ..
      "`message` varchar(50) DEFAULT NULL, " ..
      "`date` timestamp NULL DEFAULT current_timestamp(), " ..
      "PRIMARY KEY (`id`), " ..
      "KEY `citizenid` (`citizenid`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;",

  "CREATE TABLE IF NOT EXISTS `phone_gallery` (" ..
      "`citizenid` VARCHAR(255) NOT NULL, " ..
      "`image` VARCHAR(255) NOT NULL, " ..
      "`date` timestamp NULL DEFAULT current_timestamp()" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;",

  "CREATE TABLE IF NOT EXISTS `phone_tweets` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`citizenid` varchar(50) DEFAULT NULL, " ..
      "`firstName` varchar(25) DEFAULT NULL, " ..
      "`lastName` varchar(25) DEFAULT NULL, " ..
      "`message` text DEFAULT NULL, " ..
      "`date` datetime DEFAULT current_timestamp(), " ..
      "`url` text DEFAULT NULL, " ..
      "`picture` text, " ..
      "`tweetId` varchar(25) NOT NULL, " ..
      "PRIMARY KEY (`id`), " ..
      "KEY `citizenid` (`citizenid`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=1;",

  "CREATE TABLE IF NOT EXISTS `crypto` (" ..
      "`crypto` varchar(50) NOT NULL DEFAULT 'qbit', " ..
      "`worth` int(11) NOT NULL DEFAULT 0, " ..
      "`history` text DEFAULT NULL, " ..
      "PRIMARY KEY (`crypto`)" ..
  ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",

  "INSERT IGNORE INTO `crypto` VALUES ('qbit', 1000, '[{\"NewWorth\":1000,\"PreviousWorth\":1000}]');",

  "CREATE TABLE IF NOT EXISTS `lapraces` (" ..
      "`id` int(11) NOT NULL AUTO_INCREMENT, " ..
      "`name` varchar(50) DEFAULT NULL, " ..
      "`checkpoints` text DEFAULT NULL, " ..
      "`records` text DEFAULT NULL, " ..
      "`creator` varchar(50) DEFAULT NULL, " ..
      "`distance` int(11) DEFAULT NULL, " ..
      "`raceid` varchar(50) DEFAULT NULL, " ..
      "PRIMARY KEY (`id`)" ..
  ") ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4;"
}
for _, query in ipairs(queries) do
  executeQuery(query)
end
