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

  -- Remove any equipped information from the tooltip if the option is disabled
  -- (and remove the character if it has none of the items not equipped)
  if not Baganator.Config.Get("show_equipped_items_in_tooltips") then
    for _, char in ipairs(tooltipInfo.characters) do
      char.equipped = 0
    end
  end

  if Baganator.Config.Get("tooltips_sort_by_name") then
    table.sort(tooltipInfo.characters, CharacterAndRealmComparator)
    table.sort(tooltipInfo.guilds, GuildAndRealmComparator)
  else
    table.sort(tooltipInfo.characters, function(a, b)
      local left = a.bags + a.bank + a.mail + a.equipped + a.void
      local right = b.bags + b.bank + b.mail + a.equipped + a.void
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
  local totals = 0
  local seenRealms = {}

  for index, s in ipairs(tooltipInfo.characters) do
    totals = totals + s.bags + s.bank + s.mail + s.equipped + s.void
    seenRealms[s.realmNormalized] = true
  end
  for index, s in ipairs(tooltipInfo.guilds) do
    totals = totals + s.bank
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

  if totals == 0 then
    return
  end

  AddDoubleLine(BAGANATOR_L_INVENTORY, LINK_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_TOTAL_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(totals))))

  local charactersShown = 0
  for _, s in ipairs(tooltipInfo.characters) do
    local entries = {}
    if s.bags > 0 then
      table.insert(entries, BAGANATOR_L_BAGS_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.bags)))
    end
    if s.bank > 0 then
      table.insert(entries, BAGANATOR_L_BANK_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.bank)))
    end
    if s.mail > 0 then
      table.insert(entries, BAGANATOR_L_MAIL_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.mail)))
    end
    if s.equipped > 0 then
      table.insert(entries, BAGANATOR_L_EQUIPPED_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.equipped)))
    end
    if s.void > 0 then
      table.insert(entries, BAGANATOR_L_VOID_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.void)))
    end
    local character = s.character
    if appendRealm then
      character = character .. "-" .. s.realmNormalized
    end
    if s.className then
      character = RAID_CLASS_COLORS[s.className]:WrapTextInColorCode(character)
    end
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_CHARACTER_RACE_ICONS) and s.race then
      character = Baganator.Utilities.GetCharacterIcon(s.race, s.sex) .. " " .. character
    end
    if #entries > 0 then
      if charactersShown >= Baganator.Config.Get("tooltips_character_limit") then
        tooltip:AddLine("  ...")
        break
      end
      AddDoubleLine("  " .. character, LINK_FONT_COLOR:WrapTextInColorCode(strjoin(", ", unpack(entries))))
    else
      charactersShown = charactersShown + 1
    end
  end

  for index = 1, math.min(#tooltipInfo.guilds, Baganator.Config.Get("tooltips_character_limit")) do
    local s = tooltipInfo.guilds[index]
    local output = BAGANATOR_L_GUILD_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.bank))
    local guild = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(s.guild)
    if appendRealm then
      guild = guild .. "-" .. s.realmNormalized
    end
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_CHARACTER_RACE_ICONS) then
      guild = Baganator.Utilities.GetGuildIcon() .. " " .. guild
    end
    AddDoubleLine("  " .. guild, LINK_FONT_COLOR:WrapTextInColorCode(output))
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

  if quantity == 0 then -- nothing to show
    return
  end

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
    if Baganator.Config.Get(Baganator.Config.Options.SHOW_CHARACTER_RACE_ICONS) and s.race then
      character = Baganator.Utilities.GetCharacterIcon(s.race, s.sex) .. " " .. character
    end
    tooltip:AddDoubleLine("  " .. character, WHITE_FONT_COLOR:WrapTextInColorCode(FormatLargeNumber(s.quantity)))
  end
  if #summary > Baganator.Config.Get("tooltips_character_limit") then
    tooltip:AddLine("  ...")
  end
  tooltip:Show()
end
