---@class addonTableBaganator
local addonTable = select(2, ...)

local function GetShowState(data)
  if data.details.show then
    return data.details.show.gold
  else
    return data.details.hidden ~= true
  end
end

function addonTable.ShowGoldSummaryRealm(anchor, point)
  GameTooltip:SetOwner(anchor, point)

  local connectedRealms = Syndicator.Utilities.GetConnectedRealms()
  local realmsToInclude = {}
  for _, r in ipairs(connectedRealms) do
    realmsToInclude[r] = true
  end

  local allCharacters = addonTable.Utilities.GetAllCharacters()
  local allGuilds = addonTable.Utilities.GetAllGuilds()
  local currentRealm = Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).details.realmNormalized
  local multipleRealms = false
  -- Identify if any characters/guilds on a different realm to the current one
  -- will be shown
  for _, characterInfo in ipairs(allCharacters) do
    if realmsToInclude[characterInfo.realmNormalized] and GetShowState(Syndicator.API.GetCharacter(characterInfo.fullName)) and characterInfo.realmNormalized ~= currentRealm then
      multipleRealms = true
    end
  end
  for _, guildInfo in ipairs(allGuilds) do
    local guildData = Syndicator.API.GetGuild(guildInfo.fullName)
    if realmsToInclude[guildInfo.realmNormalized] and guildData.details.show and guildData.details.show.gold and guildInfo.realmNormalized ~= currentRealm then
      multipleRealms = true
    end
  end

  local lines = {}
  local total = 0
  for _, characterInfo in ipairs(allCharacters) do
    if realmsToInclude[characterInfo.realmNormalized] and GetShowState(Syndicator.API.GetCharacter(characterInfo.fullName)) then
      local money = Syndicator.API.GetCharacter(characterInfo.fullName).money
      local characterName = characterInfo.name
      if characterInfo.className then
        characterName = "|c" .. (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[characterInfo.className].colorStr .. characterName .. "|r"
      end
      if characterInfo.race then
        characterName = Syndicator.Utilities.GetCharacterIcon(characterInfo.race, characterInfo.sex) .. " " .. characterName
      end
      if multipleRealms then
        characterName = characterName .. "-" .. characterInfo.realmNormalized
      end
      table.insert(lines, {left = characterName, right = addonTable.Utilities.GetMoneyString(money, true)})
      total = total + money
    end
  end

  for _, guildInfo in ipairs(allGuilds) do
    local guildData = Syndicator.API.GetGuild(guildInfo.fullName)
    if realmsToInclude[guildInfo.realmNormalized] and guildData.details.show and guildData.details.show.gold then
      local money = Syndicator.API.GetGuild(guildInfo.fullName).money
      local guildName = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(guildInfo.name)
      if multipleRealms then
        guildName = guildName .. "-" .. guildInfo.realmNormalized
      end
      guildName = Syndicator.Utilities.GetGuildIcon() .. " " .. guildName
      table.insert(lines, {left = guildName, right = addonTable.Utilities.GetMoneyString(money, true)})
      total = total + money
    end
  end

  GameTooltip:AddDoubleLine(addonTable.Locales.REALM_WIDE_GOLD_X:format(""), WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(total, true)))
  GameTooltip:AddLine(" ")
  for _, line in ipairs(lines) do
    GameTooltip:AddDoubleLine(line.left, line.right, nil, nil, nil, 1, 1, 1)
  end

  GameTooltip_AddBlankLineToTooltip(GameTooltip)
  GameTooltip:AddLine(addonTable.Locales.HOLD_SHIFT_TO_SHOW_ACCOUNT_TOTAL, 0, 1, 0)
  GameTooltip:Show()
end

function addonTable.ShowGoldSummaryAccount(anchor, point)
  GameTooltip:SetOwner(anchor, point)

  local lines = {}
  local function AddRealm(realmName, realmCount, realmTotal)
    table.insert(lines, {left = addonTable.Locales.REALM_X_X_X:format(realmName, realmCount), right = addonTable.Utilities.GetMoneyString(realmTotal, true)})
  end
  local function AddGuild(guildName, guildRealmNormalized, guildTotal)
    table.insert(lines, {left = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(guildName) .. "-" .. guildRealmNormalized, right = addonTable.Utilities.GetMoneyString(guildTotal, true)})
  end
  local function AddWarband(warband)
    if warband > 0 then
      table.insert(lines, {left = PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.WARBAND), right = addonTable.Utilities.GetMoneyString(warband, true)})
      table.insert(lines, {left = " ", right = ""})
    end
  end

  local total = 0

  local warbandData = Syndicator.API.GetWarband and Syndicator.API.GetWarband(1)
  if warbandData and (warbandData.details == nil or warbandData.details.gold) then
    local warband = warbandData.money or 0
    AddWarband(warband)
    total = total + warband
  end

  local realmTotal = 0
  local realmCount = 0
  local currentRealm
  for _, characterInfo in ipairs(addonTable.Utilities.GetAllCharacters()) do
    if GetShowState(Syndicator.API.GetCharacter(characterInfo.fullName)) then
      if currentRealm ~= nil and currentRealm ~= characterInfo.realm then
        AddRealm(currentRealm, realmCount, realmTotal)
        realmTotal = 0
        realmCount = 0
      end
      currentRealm = characterInfo.realm
      realmCount = realmCount + 1

      local money = Syndicator.API.GetCharacter(characterInfo.fullName).money

      total = total + money
      realmTotal = realmTotal + money
    end
  end
  if currentRealm ~= nil then
    AddRealm(currentRealm, realmCount, realmTotal)
  end

  local addedGap = false
  for _, guildInfo in ipairs(addonTable.Utilities.GetAllGuilds()) do
    local guildData = Syndicator.API.GetGuild(guildInfo.fullName)
    if GetShowState(guildData) then
      if not addedGap then
        table.insert(lines, {left = " ", right = ""})
        addedGap = true
      end
      AddGuild(guildInfo.name, guildInfo.realmNormalized, guildData.money)
      total = total + guildData.money
    end
  end

  GameTooltip:AddDoubleLine(addonTable.Locales.ACCOUNT_GOLD_X:format(""), WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(total, true)))
  GameTooltip:AddLine(" ")

  for _, line in ipairs(lines) do
    GameTooltip:AddDoubleLine(line.left, line.right, nil, nil, nil, 1, 1, 1)
  end

  GameTooltip:Show()
end
