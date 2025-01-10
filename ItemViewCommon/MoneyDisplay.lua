local _, addonTable = ...

local function GetShowState(data)
  if data.details.show then
    return data.details.show.gold
  else
    return not data.details.hidden == false
  end
end

function addonTable.ShowGoldSummaryRealm(anchor, point)
  GameTooltip:SetOwner(anchor, point)

  local connectedRealms = Syndicator.Utilities.GetConnectedRealms()
  local realmsToInclude = {}
  for _, r in ipairs(connectedRealms) do
    realmsToInclude[r] = true
  end

  local lines = {}
  local total = 0
  for _, characterInfo in ipairs(addonTable.Utilities.GetAllCharacters()) do
    if realmsToInclude[characterInfo.realmNormalized] and GetShowState(Syndicator.API.GetCharacter(characterInfo.fullName)) then
      local money = Syndicator.API.GetCharacter(characterInfo.fullName).money
      local characterName = characterInfo.name
      if #connectedRealms > 1 then
        characterName = characterInfo.fullName
      end
      if characterInfo.className then
        characterName = "|c" .. (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[characterInfo.className].colorStr .. characterName .. "|r"
      end
      if characterInfo.race then
        characterName = Syndicator.Utilities.GetCharacterIcon(characterInfo.race, characterInfo.sex) .. " " .. characterName
      end
      table.insert(lines, {left = characterName, right = addonTable.Utilities.GetMoneyString(money, true)})
      total = total + money
    end
  end

  for _, guildInfo in ipairs(addonTable.Utilities.GetAllGuilds()) do
    if realmsToInclude[guildInfo.realmNormalized] and GetShowState(Syndicator.API.GetGuild(guildInfo.fullName)) then
      local money = Syndicator.API.GetGuild(guildInfo.fullName).money
      local guildName = guildInfo.name
      if #connectedRealms > 1 then
        guildName = guildInfo.fullName
      end
      guildName = Syndicator.Utilities.GetGuildIcon() .. " " .. guildName
      table.insert(lines, {left = guildName, right = addonTable.Utilities.GetMoneyString(money, true)})
      total = total + money
    end
  end

  GameTooltip:AddDoubleLine(BAGANATOR_L_REALM_WIDE_GOLD_X:format(""), WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(total, true)))
  GameTooltip:AddLine(" ")
  for _, line in ipairs(lines) do
    GameTooltip:AddDoubleLine(line.left, line.right, nil, nil, nil, 1, 1, 1)
  end

  GameTooltip_AddBlankLineToTooltip(GameTooltip)
  GameTooltip:AddLine(BAGANATOR_L_HOLD_SHIFT_TO_SHOW_ACCOUNT_TOTAL, 0, 1, 0)
  GameTooltip:Show()
end

function addonTable.ShowGoldSummaryAccount(anchor, point)
  GameTooltip:SetOwner(anchor, point)

  local lines = {}
  local function AddRealm(realmName, realmCount, realmTotal)
    table.insert(lines, {left = BAGANATOR_L_REALM_X_X_X:format(realmName, realmCount), right = addonTable.Utilities.GetMoneyString(realmTotal, true)})
  end
  local function AddWarband(warband)
    if warband > 0 then
      table.insert(lines, {left = PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_WARBAND), right = addonTable.Utilities.GetMoneyString(warband, true)})
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
  local characters = addonTable.Utilities.GetAllCharacters()
  for _, e in ipairs(characters) do
    e.type = "character"
  end
  local guilds = addonTable.Utilities.GetAllGuilds()
  for _, e in ipairs(guilds) do
    e.type = "guild"
  end
  local entries = characters
  tAppendAll(entries, guilds)

  -- Sort again to combine properly
  table.sort(entries, function(a, b)
    if a.realm == b.realm then
      return a.name < b.name
    else
      return a.realm < b.realm
    end
  end)

  for _, info in ipairs(entries) do
    if (info.type == "character" and GetShowState(Syndicator.API.GetCharacter(info.fullName))) or
       (info.type == "guild" and GetShowState(Syndicator.API.GetGuild(info.fullName)))
      then
      if currentRealm ~= nil and currentRealm ~= info.realm then
        AddRealm(currentRealm, realmCount, realmTotal)
        realmTotal = 0
        realmCount = 0
      end
      currentRealm = info.realm
      realmCount = realmCount + 1

      local money = 0
      if info.type == "character" then
        money = Syndicator.API.GetCharacter(info.fullName).money
      elseif info.type == "guild" then
        money = Syndicator.API.GetGuild(info.fullName).money
      end

      total = total + money
      realmTotal = realmTotal + money
    end
  end
  if currentRealm ~= nil then
    AddRealm(currentRealm, realmCount, realmTotal)
  end

  GameTooltip:AddDoubleLine(BAGANATOR_L_ACCOUNT_GOLD_X:format(""), WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(total, true)))
  GameTooltip:AddLine(" ")

  for _, line in ipairs(lines) do
    GameTooltip:AddDoubleLine(line.left, line.right, nil, nil, nil, 1, 1, 1)
  end

  GameTooltip:Show()
end
