Baganator.Tooltips = {}

local function CharacterAndRealmComparator(a, b)
  if a.realmNormalized == b.realmNormalized then
    return a.character < b.character
  else
    return a.realmNormalized < b.realmNormalized
  end
end

local function GuildAndRealmComparator(a, b)
  if a.realmNormalized == b.realmNormalized then
    return a.guild < b.guild
  else
    return a.realmNormalized < b.realmNormalized
  end
end

function Baganator.Tooltips.AddItemLines(tooltip, summaries, itemLink)
  if itemLink == nil then
    return
  end

  local success, key = pcall(Baganator.Utilities.GetItemKey, itemLink)

  if not success then
    return
  end

  local tooltipInfo = summaries:GetTooltipInfo(key, Baganator.Config.Get("tooltips_connected_realms_only"), Baganator.Config.Get("tooltips_faction_only"))

  if Baganator.Config.Get("tooltips_sort_by_name") then
    table.sort(tooltipInfo.characters, CharacterAndRealmComparator)
    table.sort(tooltipInfo.guilds, GuildAndRealmComparator)
  else
    table.sort(tooltipInfo.characters, function(a, b)
      local left = a.bags + a.bank + a.mail
      local right = b.bags + b.bank + b.mail
      if left == right then
        return CharacterAndRealmComparator(a, b)
      else
        return left > right
      end
    end)
    table.sort(tooltipInfo.guilds, function(a, b)
      if a.bank == b.bank then
        return GuildAndRealmComparator(a, b)
      else
        return a.bank > b.bank
      end
    end)
  end

  if not Baganator.Config.Get(Baganator.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS) then
    tooltipInfo.guilds = {}
  end

  if #tooltipInfo.characters == 0 and #tooltipInfo.guilds == 0 then
    return
  end

  -- Used to ease adding to battle pet tooltip which doesn't have AddDoubleLine
  local function AddDoubleLine(left, right, ...)
    if tooltip.AddDoubleLine then
      tooltip:AddDoubleLine(left, right, ...)
    else
      tooltip:AddLine(left .. " " .. right)
    end
  end

  local result = "  "
  local bagCount, bankCount, mailCount, equippedCount, guildCount = 0, 0, 0, 0, 0
  local seenRealms = {}

  for index, s in ipairs(tooltipInfo.characters) do
    bagCount = bagCount + s.bags
    bankCount = bankCount + s.bank
    mailCount = mailCount + s.mail
    equippedCount = equippedCount + s.equipped
    seenRealms[s.realmNormalized] = true
  end
  for index, s in ipairs(tooltipInfo.guilds) do
    guildCount = guildCount + s.bank
    seenRealms[s.realmNormalized] = true
  end
  seenRealms[GetNormalizedRealmName() or ""] = true -- ensure realm name is shown for a different realm

  local realmCount = 0
  for realm in pairs(seenRealms) do
    realmCount = realmCount + 1
  end
  local appendRealm = false
  if realmCount > 1 then
    appendRealm = true
  end

  local totals = bagCount + bankCount + mailCount + equippedCount + guildCount
  AddDoubleLine(BAGANATOR_L_INVENTORY, WHITE_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_TOTAL_X:format(totals)))

  for index = 1, math.min(#tooltipInfo.characters, Baganator.Config.Get("tooltips_character_limit")) do
    local s = tooltipInfo.characters[index]
    local entries = {}
    if s.bags > 0 then
      table.insert(entries, BAGANATOR_L_BAGS_X:format(s.bags))
    end
    if s.bank > 0 then
      table.insert(entries, BAGANATOR_L_BANK_X:format(s.bank))
    end
    if s.mail > 0 then
      table.insert(entries, BAGANATOR_L_MAIL_X:format(s.mail))
    end
    if s.equipped > 0 then
      table.insert(entries, BAGANATOR_L_EQUIPPED_X:format(s.equipped))
    end
    local character = s.character
    if appendRealm then
      character = character .. "-" .. s.realmNormalized
    end
    if s.className then
      character = RAID_CLASS_COLORS[s.className]:WrapTextInColorCode(character)
    end
    AddDoubleLine("  " .. character, WHITE_FONT_COLOR:WrapTextInColorCode(strjoin(", ", unpack(entries))))
  end
  if #tooltipInfo.characters > Baganator.Config.Get("tooltips_character_limit") then
    tooltip:AddLine("  ...")
  end

  for index = 1, math.min(#tooltipInfo.guilds, Baganator.Config.Get("tooltips_character_limit")) do
    local s = tooltipInfo.guilds[index]
    local output = BAGANATOR_L_GUILD_X:format(s.bank)
    local guild = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(s.guild)
    if appendRealm then
      guild = guild .. "-" .. s.realmNormalized
    end
    AddDoubleLine("  " .. guild, WHITE_FONT_COLOR:WrapTextInColorCode(output))
  end
  if #tooltipInfo.guilds > Baganator.Config.Get("tooltips_character_limit") then
    tooltip:AddLine("  ...")
  end
  tooltip:Show()
end

function Baganator.Tooltips.AddCurrencyLines(tooltip, currencyID)
  if tIndexOf(Baganator.Constants.SharedCurrencies, currencyID) ~= nil then
    return
  end

  local summary = Baganator.InventoryTracking.GetCurrencyTooltipData(currencyID, Baganator.Config.Get("tooltips_connected_realms_only"), Baganator.Config.Get("tooltips_faction_only"))

  if Baganator.Config.Get("tooltips_sort_by_name") then
    table.sort(summary, CharacterAndRealmComparator)
  else
    table.sort(summary, function(a, b)
      if a.quantity == b.quantity then
        return CharacterAndRealmComparator(a, b)
      else
        return a.quantity > b.quantity
      end
    end)
  end

  local quantity = 0
  local seenRealms = {}

  for index, s in ipairs(summary) do
    quantity = quantity + s.quantity
    seenRealms[s.realmNormalized] = true
  end
  seenRealms[GetNormalizedRealmName() or ""] = true -- ensure realm name is shown for a different realm

  local realmCount = 0
  for realm in pairs(seenRealms) do
    realmCount = realmCount + 1
  end
  local appendRealm = false
  if realmCount > 1 then
    appendRealm = true
  end

  tooltip:AddLine(BAGANATOR_L_ALL_CHARACTERS_COLON .. " " .. WHITE_FONT_COLOR:WrapTextInColorCode(FormatLargeNumber(quantity)))
  for index = 1, math.min(#summary, Baganator.Config.Get("tooltips_character_limit")) do
    local s = summary[index]
    local character = s.character
    if appendRealm then
      character = character .. "-" .. s.realmNormalized
    end
    if s.className then
      character = RAID_CLASS_COLORS[s.className]:WrapTextInColorCode(character)
    end
    tooltip:AddDoubleLine("  " .. character, WHITE_FONT_COLOR:WrapTextInColorCode(FormatLargeNumber(s.quantity)))
  end
  if #summary > Baganator.Config.Get("tooltips_character_limit") then
    tooltip:AddLine("  ...")
  end
  tooltip:Show()
end
