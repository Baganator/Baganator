local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

function Baganator.Utilities.ApplyVisuals(frame)
  local alpha = Baganator.Config.Get(Baganator.Config.Options.VIEW_ALPHA)
  local noFrameBorders = Baganator.Config.Get(Baganator.Config.Options.NO_FRAME_BORDERS)

  frame.Bg:SetAlpha(alpha)
  frame.TopTileStreaks:SetAlpha(alpha)

  if frame.NineSlice then -- retail
    frame.NineSlice:SetAlpha(alpha)
    frame.NineSlice:SetShown(not noFrameBorders)
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 6, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 6, -21)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, -21)
    end
  elseif frame.TitleBg then -- classic
    frame.TitleBg:SetAlpha(alpha)
    for _, key in ipairs(classicBorderFrames) do
      frame[key]:SetAlpha(alpha)
      frame[key]:SetShown(not noFrameBorders)
    end
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 2, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, 0)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 2, -21)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, -21)
    end
  end
end

function Baganator.Utilities.GetAllCharacters(searchText)
  searchText = searchText and searchText:lower() or ""
  local characters = {}
  for char, info in pairs(BAGANATOR_DATA.Characters) do
    if searchText == "" or char:lower():find(searchText, nil, true) then
      table.insert(characters, {
        fullName = char,
        name = info.details.character,
        realmNormalized = info.details.realmNormalized,
        realm = info.details.realm,
        className = info.details.className
      })
    end
  end
  table.sort(characters, function(a, b)
    if a.realm == b.realm then
      return a.name < b.name
    else
      return a.realm < b.realm
    end
  end)

  return characters
end

function Baganator.Utilities.ShouldShowSortButton()
  return Baganator.Config.Get(Baganator.Config.Options.SHOW_SORT_BUTTON)
end

function Baganator.Utilities.CountEmptySlots(cachedBag)
  local empty = 0
  for _, slotContents in ipairs(cachedBag) do
    if next(slotContents) == nil then
      empty = empty + 1
    end
  end

  return empty
end

function Baganator.Utilities.GetRandomSearchesText()
  local term = Baganator.Constants.SampleSearchTerms[random(#Baganator.Constants.SampleSearchTerms)]

  return BAGANATOR_L_SEARCH_TRY_X:format(term)
end

if Baganator.Constants.IsClassic then
  local tooltip = CreateFrame("GameTooltip", "BaganatorUtilitiesScanTooltip", nil, "GameTooltipTemplate")
  tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

  function Baganator.Utilities.DumpClassicTooltip(tooltipSetter)
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltipSetter(tooltip)

    local name = tooltip:GetName()
    local dump = {}

    local row = 1
    while _G[name .. "TextLeft" .. row] ~= nil do
      local leftFontString = _G[name .. "TextLeft" .. row]
      local rightFontString = _G[name .. "TextRight" .. row]

      local entry = {
        leftText = leftFontString:GetText(),
        leftColor = CreateColor(leftFontString:GetTextColor()),
        rightText = rightFontString:GetText(),
        rightColor = CreateColor(rightFontString:GetTextColor())
      }
      if entry.leftText or entry.rightText then
        table.insert(dump, entry)
      end

      row = row + 1
    end

    return {lines = dump}
  end
end

function Baganator.Utilities.AddBagSortManager(self)
  self.sortManager = CreateFrame("Frame", nil, self)
  function self.sortManager:Apply(status, retryFunc, completeFunc)
    self:SetScript("OnUpdate", nil)
    Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self)
    if status == Baganator.Constants.SortStatus.Complete then
      completeFunc()
    elseif status == Baganator.Constants.SortStatus.WaitingMove then
      Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
        retryFunc()
      end, self)
    else -- waiting item data or item unlock
      self:SetScript("OnUpdate", retryFunc)
    end
  end
  self.sortManager:SetScript("OnHide", function()
    self.sortManager:SetScript("OnUpdate", nil)
    Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self.sortManager)
  end)
end

function Baganator.Utilities.AddBagTransferManager(self)
  self.transferManager = CreateFrame("Frame", nil, self)
  function self.transferManager:Apply(status, retryFunc, completeFunc)
    self:SetScript("OnUpdate", nil)
    Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self)
    if status == Baganator.Constants.SortStatus.Complete then
      completeFunc()
    elseif status == Baganator.Constants.SortStatus.WaitingMove then
      Baganator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
        C_Timer.After(0, retryFunc)
      end, self)
    else -- waiting item data or item unlock
      self:SetScript("OnUpdate", retryFunc)
    end
  end
  self.transferManager:SetScript("OnHide", function()
    self.transferManager:SetScript("OnUpdate", nil)
    Baganator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self.transferManager)
  end)
end

-- Prevent coin icons getting offset on varying screen resolutions by removing
-- the coin icon offset
function Baganator.Utilities.GetMoneyString(amount, splitThousands)
  local result = GetMoneyString(amount, splitThousands)
  result = result:gsub("0:0:2:0", "12"):gsub("|T", " |T")
  return result
end
