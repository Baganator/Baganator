local _, addonTable = ...

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
    if realmsToInclude[characterInfo.realmNormalized] and not Syndicator.API.GetCharacter(characterInfo.fullName).details.hidden then
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

  local warband = Syndicator.API.GetWarband and Syndicator.API.GetWarband(1).money or 0
  AddWarband(warband)
  total = total + warband

  local realmTotal = 0
  local realmCount = 0
  local currentRealm
  for _, characterInfo in ipairs(addonTable.Utilities.GetAllCharacters()) do
    if not Syndicator.API.GetCharacter(characterInfo.fullName).details.hidden then
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

  GameTooltip:AddDoubleLine(BAGANATOR_L_ACCOUNT_GOLD_X:format(""), WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Utilities.GetMoneyString(total, true)))
  GameTooltip:AddLine(" ")

  for _, line in ipairs(lines) do
    GameTooltip:AddDoubleLine(line.left, line.right, nil, nil, nil, 1, 1, 1)
  end

  GameTooltip:Show()
end
