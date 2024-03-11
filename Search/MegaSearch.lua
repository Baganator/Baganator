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

  Baganator.Search.GetBaseInfoFromList(characterData.auctions or {}, function(results)
    finishCheck("auctions", results)
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
  local linkToTabIndex = {}
  for tabIndex, tab in ipairs(CopyTable(BAGANATOR_DATA.Guilds[guild].bank)) do
    for _, item in ipairs(tab.slots) do
      if item.itemLink then
        linkToTabIndex[item.itemLink] = tabIndex
      end
      table.insert(guildList, item)
    end
  end

  Baganator.Search.GetBaseInfoFromList(guildList, function(results)
    for _, r in ipairs(results) do
      r.source = {guild = guild, container = linkToTabIndex[r.itemLink]}
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
      managingFrame:SetScript("OnUpdate", nil)
      for _, query in ipairs(pendingQueries) do
        Query(unpack(query))
      end
      pendingQueries = {}
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

function Baganator.Search.CombineMegaSearchResults(results)
  local items = {}
  local seenCharacters = {}
  local seenGuilds = {}
  for _, r in ipairs(results) do
    local key = Baganator.Search.GetGroupingKey(r)
    if not items[key] then
      items[key] = CopyTable(r)
      items[key].itemCount = 0
      items[key].sources = {}
      seenCharacters[key] = {}
      seenGuilds[key] = {}
    end
    local source = CopyTable(r.source)
    source.itemCount = r.itemCount
    if source.character then
      local characterData = BAGANATOR_DATA.Characters[source.character]
      if not characterData.details.hidden and (source.container ~= "equipped" or Baganator.Config.Get(Baganator.Config.Options.SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS)) then
        if seenCharacters[key][source.character .. "_" .. source.container] then
          local entry = items[key].sources[seenCharacters[key][source.character .. "_" .. source.container]]
          entry.itemCount = entry.itemCount + source.itemCount
        else
          table.insert(items[key].sources, source)
          source.itemLink = r.itemLink
          source.itemName = r.itemName
          seenCharacters[key][source.character .. "_" .. source.container] = #items[key].sources
        end
      end
    elseif source.guild then
      if seenGuilds[key][source.guild] then
        local entry = items[key].sources[seenGuilds[key][source.guild]]
        entry.itemCount = entry.itemCount + source.itemCount
      else
        table.insert(items[key].sources, source)
        source.itemLink = r.itemLink
        source.itemName = r.itemName
        seenGuilds[key][source.guild] = #items[key].sources
      end
    end
    items[key].itemCount = items[key].itemCount + r.itemCount
  end

  local keys = {}
  for key in pairs(items) do
    table.insert(keys, key)
  end
  table.sort(keys)

  local final = {}
  for _, key in ipairs(keys) do
    if #items[key].sources > 0 then
      table.insert(final, items[key])
      table.sort(items[key].sources, function(a, b)
        if a.itemCount == b.itemCount then
          return tostring(a.container) < tostring(b.container)
        else
          return a.itemCount > b.itemCount
        end
      end)
    end
  end

  return final
end

local function GetLink(source, searchTerm, text)
  local mode
  if source.guild then
    mode = "guild"
  elseif source.character then
    mode = "character"
  else
    return text
  end
  -- Modify item link so it doesn't break the addon link
  local moddedLink = source.itemLink:gsub(":", "("):gsub("%|",")")
  local moddedTerm = searchTerm:gsub(":", "(")
  return "|Haddon:BaganatorSearch:" .. moddedTerm .. ":" .. mode .. ":" .. source[mode] .. ":" .. source.container .. ":" .. moddedLink .. "|h" .. "[" .. text .. "]" .. "|h"
end

local CONTAINER_TYPE_TO_TEXT = {
  bag = BAGANATOR_L_BAGS_LOWER,
  bank = BAGANATOR_L_BANK_LOWER,
  mail = BAGANATOR_L_MAIL_LOWER,
  equipped = BAGANATOR_L_EQUIPPED_LOWER,
  void = BAGANATOR_L_VOID_LOWER,
  auctions = BAGANATOR_L_AUCTIONS_LOWER,
}

local CONTAINER_TYPE_TO_MESSAGE = {
  equipped = BAGANATOR_L_THAT_ITEM_IS_EQUIPPED,
  auctions = BAGANATOR_L_THAT_ITEM_IS_LISTED_ON_THE_AUCTION_HOUSE,
  mail = BAGANATOR_L_THAT_ITEM_IS_IN_A_MAILBOX,
  void = BAGANATOR_L_THAT_ITEM_IS_IN_VOID_STORAGE,
}

local function PrintSource(indent, source, searchTerm)
  local count = BLUE_FONT_COLOR:WrapTextInColorCode(" x" .. FormatLargeNumber(source.itemCount))
  if source.character then
    local character = GetLink(source, searchTerm, source.character)
    local characterData = BAGANATOR_DATA.Characters[source.character]
    local className = characterData.details.className
    if className then
      character = RAID_CLASS_COLORS[className]:WrapTextInColorCode(character)
    end
    print(indent, PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(CONTAINER_TYPE_TO_TEXT[source.container]) .. count, character)
  elseif source.guild then
    local guild = GetLink(source, searchTerm, source.guild)
    print(indent, BAGANATOR_L_GUILD_LOWER .. count, TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(guild))
  end
end

local dialogName = "Baganator_InventoryItemInX"
StaticPopupDialogs[dialogName] = {
  text = "",
  button1 = OKAY,
  timeout = 0,
  hideOnEscape = 1,
}

EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button, chatFrame)
    local linkType, addonName, searchText, mode, entity, container, itemLink = strsplit(":", link)
    StaticPopup_Hide(dialogName)
    if linkType == "addon" and addonName == "BaganatorSearch" then
      -- Revert changes to item link to make it fit in the addon link
      itemLink = itemLink:gsub("%(", ":"):gsub("%)", "|")
      searchText = searchText:gsub("%(", ":")
      if mode == "character" then
        if container == "bag" then
          Baganator.CallbackRegistry:TriggerEvent("GuildHide")
          Baganator.CallbackRegistry:TriggerEvent("BankHide")
          Baganator.CallbackRegistry:TriggerEvent("BagShow", entity)
          Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
          Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
        elseif container == "bank" then
          Baganator.CallbackRegistry:TriggerEvent("GuildHide")
          Baganator.CallbackRegistry:TriggerEvent("BagHide")
          Baganator.CallbackRegistry:TriggerEvent("BankShow", entity)
          Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
          Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
        else
          StaticPopupDialogs[dialogName].text = CONTAINER_TYPE_TO_MESSAGE[container]
          StaticPopup_Show(dialogName)
          return
        end
      elseif mode == "guild" then
        Baganator.CallbackRegistry:TriggerEvent("BagHide")
        Baganator.CallbackRegistry:TriggerEvent("BankHide")
        Baganator.CallbackRegistry:TriggerEvent("GuildShow", entity)
        Baganator.CallbackRegistry:TriggerEvent("GuildSetTab", tonumber(container))
        Baganator.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
        Baganator.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
      end
    end
end)

function Baganator.Search.RunMegaSearchAndPrintResults(searchTerm)
  if searchTerm:match("|H") then
    Baganator.Utilities.Message(BAGANATOR_L_CANNOT_SEARCH_BY_ITEM_LINK)
    return
  end
  searchTerm = searchTerm:lower()
  Baganator.Search.RequestMegaSearchResults(searchTerm, function(results)
    print(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_SEARCHED_EVERYWHERE_COLON) .. " " .. YELLOW_FONT_COLOR:WrapTextInColorCode(searchTerm))
    results = Baganator.Search.CombineMegaSearchResults(results)
    for _, r in ipairs(results) do
      print("   " .. r.itemLink, BLUE_FONT_COLOR:WrapTextInColorCode("x" .. FormatLargeNumber(r.itemCount)))
      for _, s in ipairs(r.sources) do
        PrintSource("       ", s, s.itemName:lower())
      end
    end
  end)
end
