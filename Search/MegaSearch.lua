local cache = {
}

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
  for _, slot in ipairs(characterData.containerInfo or {}) do
    table.insert(equippedList, slot)
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
    if next(pending.Characters) == nil and next(pending.Guilds) == nil then
      for _, query in ipairs(pendingQueries) do
        Query(unpack(query))
      end
      pendingQueries = {}
      managingFrame:SetScript("OnUpdate", nil)
      return
    end
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
