local cache = {}

local function CacheCharacter(character, callback)
  local waiting = 5 -- bags, bank, mail, equipped+containerInfo, void

  local function finishCheck(sourceType, results)
    for _, r in ipairs(results) do
      r.source = {character = character, container = sourceType}
      table.insert(cache, r)
    end
    waiting = waiting - 1
    if waiting == 0 then
      callback()
    end
  end

  local characterData = CopyTable(BAGANATOR_DATA.Characters[character])

  local bagsList = {}
  for _, bag in ipairs(characterData.bags) do
    for _, item in ipairs(bag) do
      table.insert(bagsList, item)
    end
  end

  Baganator.Search.GetBaseInfoFromList(bagsList, function(results)
    finishCheck("bag", results)
  end)

  local bankList = {}
  for _, bag in ipairs(characterData.bank) do
    for _, item in ipairs(bag) do
      table.insert(bankList, item)
    end
  end

  Baganator.Search.GetBaseInfoFromList(bankList, function(results)
    finishCheck("bank", results)
  end)

  Baganator.Search.GetBaseInfoFromList(characterData.mail or {}, function(results)
    finishCheck("mail", results)
  end)

  local equippedList = {}
  for _, slot in pairs(characterData.equipped or {}) do
    table.insert(equippedList, slot)
  end
  for label, containers in pairs(characterData.containerInfo or {}) do
    for _, item in pairs(containers) do
      table.insert(equippedList, item)
    end
  end

  Baganator.Search.GetBaseInfoFromList(equippedList, function(results)
    finishCheck("equipped", results)
  end)

  local voidList = {}
  for _, tab in ipairs(characterData.void or {}) do
    for _, item in ipairs(tab) do
      table.insert(voidList, item)
    end
  end

  Baganator.Search.GetBaseInfoFromList(voidList, function(results)
    finishCheck("void", results)
  end)
end

local function CacheGuild(guild, callback)
  local guildList = {}
  for _, tab in ipairs(BAGANATOR_DATA.Guilds[guild].bank) do
    for _, item in ipairs(tab.slots) do
      table.insert(guildList, item)
    end
  end

  Baganator.Search.GetBaseInfoFromList(guildList, function(results)
    for _, r in ipairs(results) do
      r.source = {guild = guild}
      table.insert(cache, r)
    end
    callback()
  end)
end

local pendingQueries = {}
local pending
local toPurge = {Characters = {}, Guilds = {}}
local managingFrame = CreateFrame("Frame")

local searchMonitorPool = CreateFramePool("Frame", UIParent, "BaganatorOfflineListSearchTemplate")

local function Query(searchTerm, callback)
  local monitor = searchMonitorPool:Acquire()
  monitor:Show()
  monitor:StartSearch(cache, searchTerm, function(matches)
    callback(matches)
    searchMonitorPool:Release(monitor)
  end)
end

local function CharacterCacheUpdate(_, character)
  if pending then
    pending.Characters[character] = true
    toPurge.Characters[character] = true
  end
end

Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate", CharacterCacheUpdate)
Baganator.CallbackRegistry:RegisterCallback("MailCacheUpdate", CharacterCacheUpdate)
Baganator.CallbackRegistry:RegisterCallback("EquippedCacheUpdate", CharacterCacheUpdate)
Baganator.CallbackRegistry:RegisterCallback("VoidCacheUpdate", CharacterCacheUpdate)

Baganator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", function(_, guild)
  if pending then
    pending.Guilds[guild] = true
    toPurge.Guilds[guild] = true
  end
end)

function Baganator.Search.RequestMegaSearchResults(searchTerm, callback)
  if pending == nil then
    pending = {
      Characters = {},
      Guilds = {},
    }

    for c in pairs(BAGANATOR_DATA.Characters) do
      pending.Characters[c] = true
    end

    for g in pairs(BAGANATOR_DATA.Guilds) do
      pending.Guilds[g] = true
    end
  end

  local function PendingCheck()
    if next(pending.Characters) == nil and (not Baganator.Config.Get(Baganator.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS) or next(pending.Guilds) == nil) then
      for _, query in ipairs(pendingQueries) do
        Query(unpack(query))
      end
      pendingQueries = {}
      managingFrame:SetScript("OnUpdate", nil)
      return
    end
    cache = tFilter(cache, function(item) return toPurge.Characters[item.source.character] == nil and toPurge.Guilds[item.source.guild] == nil end, true)
    toPurge = {Characters = {}, Guilds = {}}
    managingFrame:SetScript("OnUpdate", nil)
    local waiting = 0
    local complete = false
    for character in pairs(pending.Characters) do
      waiting = waiting + 1
      CacheCharacter(character, function()
        pending.Characters[character] = nil
        waiting = waiting - 1
        if complete and waiting == 0 then
          managingFrame:SetScript("OnUpdate", PendingCheck)
        end
      end)
    end
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS) then
      for guild in pairs(pending.Guilds) do
        waiting = waiting + 1
        CacheGuild(guild, function()
          pending.Guilds[guild] = nil
          waiting = waiting - 1
          if complete and waiting == 0 then
            managingFrame:SetScript("OnUpdate", PendingCheck)
          end
        end)
      end
    end
    complete = true
    if waiting == 0 then
      PendingCheck()
    end
  end

  if next(pending.Characters) or next(pending.Guilds) then
    managingFrame:SetScript("OnUpdate", PendingCheck)
    table.insert(pendingQueries, {searchTerm, callback})
  else
    Query(searchTerm, callback)
  end
end

function Baganator.Search.RunMegaSearchAndPrintResults(term)
  Baganator.Search.RequestMegaSearchResults(term, function(results)
    local anyShown = false
    print(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_SEARCHED_EVERYWHERE_COLON) .. " " .. YELLOW_FONT_COLOR:WrapTextInColorCode(term))
    for _, r in ipairs(results) do
      local item = r.itemLink .. BLUE_FONT_COLOR:WrapTextInColorCode("x" .. r.itemCount)
      if r.source.character then
        local character = r.source.character
        local characterData = BAGANATOR_DATA.Characters[r.source.character]
        if not characterData.details.hidden then
          anyShown = true
          local className = characterData.details.className
          if className then
            character = RAID_CLASS_COLORS[className]:WrapTextInColorCode(character)
          end
          print("   ", item, PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(r.source.container), character)
        end
      elseif r.source.guild then
        anyShown = true
        print("   ", r.itemLink .. BLUE_FONT_COLOR:WrapTextInColorCode("x" .. r.itemCount), TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(r.source.guild))
      end
    end
    if not anyShown then
      print("   ", BAGANATOR_L_NO_RESULTS)
    end
  end)
end
