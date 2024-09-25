local _, addonTable = ...

local isSyncing = false
local function ApplyBlizzard()
  local backpackCurrencies = {}

  if not Syndicator.API.GetCurrentCharacter() then
    return
  end

  local existingCurrencies = Syndicator.API.GetCharacter(Syndicator.API.GetCurrentCharacter()).currencies

  for i = 1, addonTable.Constants.MaxPinnedCurrencies do
    local currencyID, _
    if C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo then
      local currencyInfo = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
      if currencyInfo then
        currencyID = currencyInfo.currencyTypesID
      end
    elseif GetBackpackCurrencyInfo then
      _, currencyID = select(3, GetBackpackCurrencyInfo(i))
    end
    if currencyID and existingCurrencies[currencyID] then
      table.insert(backpackCurrencies, currencyID)
    else
      break
    end
  end

  local tracked = addonTable.Config.Get(addonTable.Config.Options.CURRENCIES_TRACKED)

  local seen = {}
  for index = #tracked, 1, -1 do
    local details = tracked[index]
    if details.currencyID then
      if tIndexOf(backpackCurrencies, details.currencyID) == nil then
        table.remove(tracked, index)
      else
        seen[details.currencyID] = true
      end
    end
  end

  for _, currencyID in ipairs(backpackCurrencies) do
    if not seen[currencyID] then
      table.insert(tracked, {currencyID = currencyID})
    end
  end

  addonTable.Config.Set(addonTable.Config.Options.CURRENCIES_TRACKED, CopyTable(tracked))
end

function addonTable.ItemViewCommon.SyncCurrenciesTrackedWithBlizzard()
  if isSyncing then
    return
  end
  isSyncing = true

  ApplyBlizzard()

  -- Update currencies when they are watched/unwatched in Blizz UI
  EventRegistry:RegisterCallback("TokenFrame.OnTokenWatchChanged", function()
    ApplyBlizzard()
  end)
  -- Needed to get currencies to load correctly on classic versions of WoW
  addonTable.Utilities.OnAddonLoaded("Blizzard_TokenUI", function()
    ApplyBlizzard()

    -- Wrath Classic
    if ManageBackpackTokenFrame then
      hooksecurefunc("ManageBackpackTokenFrame", function()
        ApplyBlizzard()
      end)
    end
  end)
end

function addonTable.ItemViewCommon.SetCurrencyTrackedBlizzard(toTrackCurrencyID, state)
  if Syndicator.Constants.IsRetail then
    local index = 0
    while index < C_CurrencyInfo.GetCurrencyListSize() do
      index = index + 1
      local info = C_CurrencyInfo.GetCurrencyListInfo(index)
      if info.isHeader then
        if not info.isHeaderExpanded then
          C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
          if currencyID == toTrackCurrencyID then
            C_CurrencyInfo.SetCurrencyBackpack(index, state)
            break
          end
        end
      end
    end
  else -- Only versions of classic with currency (due to checks earlier)
    local index = 0
    while index < GetCurrencyListSize() do
      index = index + 1
      local name, isHeader, isHeaderExpanded, _, _, quantity = GetCurrencyListInfo(index)
      if isHeader then
        if not isHeaderExpanded then
          table.insert(toCollapse, index)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
          if currencyID == toTrackCurrencyID then
            SetCurrencyBackpack(index, state)
            return
          end
        end
      end
    end
  end
end
