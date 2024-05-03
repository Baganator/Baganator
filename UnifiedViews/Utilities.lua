local _, addonTable = ...

local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

function Baganator.Utilities.ApplyVisuals(frame)
  if TSM_API then
    frame:SetFrameStrata("HIGH")
  end

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
  for _, char in ipairs(Syndicator.API.GetAllCharacters()) do
    local info = Syndicator.API.GetCharacter(char)
    if searchText == "" or char:lower():find(searchText, nil, true) then
      table.insert(characters, {
        fullName = char,
        name = info.details.character,
        realmNormalized = info.details.realmNormalized,
        realm = info.details.realm,
        className = info.details.className,
        race = info.details.race,
        sex = info.details.sex,
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

function Baganator.Utilities.AddBagSortManager(parent)
  parent.sortManager = CreateFrame("Frame", nil, parent)
  function parent.sortManager:Cancel()
    self:SetScript("OnUpdate", nil)
    Syndicator.CallbackRegistry:UnregisterCallback("BagCacheUpdate", self)
    if self.timer then
      self.timer:Cancel()
      self.timer = nil
    end
  end
  function parent.sortManager:Apply(status, retryFunc, completeFunc)
    self:Cancel()
    if status == Baganator.Constants.SortStatus.Complete then
      completeFunc()
    elseif status == Baganator.Constants.SortStatus.WaitingMove then
      Syndicator.CallbackRegistry:RegisterCallback("BagCacheUpdate",  function(_, character, updatedBags)
        self:Cancel()
        retryFunc()
      end, self)
      self.timer = C_Timer.NewTimer(1, function()
        self:Cancel()
        retryFunc()
      end)
    else -- waiting item data or item unlock
      self:SetScript("OnUpdate", retryFunc)
    end
  end
  parent.sortManager:SetScript("OnHide", parent.sortManager.Cancel)
end

function Baganator.Utilities.AddBagTransferManager(parent)
  parent.transferManager = CreateFrame("Frame", nil, parent)
  -- Tidy up all the recovery methods so they don't trigger after everything is
  -- complete
  Baganator.CallbackRegistry:RegisterCallback("TransferCancel", function(self)
    self:SetScript("OnUpdate", nil)
    if self.modes ~= nil then
      for _, m in ipairs(self.modes) do
        Syndicator.CallbackRegistry:UnregisterCallback(m, self)
      end
      self.modes = nil
    end
    if self.timer then
      self.timer:Cancel()
      self.timer = nil
    end
  end, parent.transferManager)
  function parent.transferManager:Apply(status, modes, retryFunc, completeFunc)
    Baganator.CallbackRegistry:TriggerEvent("TransferCancel")
    self.modes = modes
    if status == Baganator.Constants.SortStatus.Complete then
      completeFunc()
    elseif status == Baganator.Constants.SortStatus.WaitingMove then
      local pending = #modes
      -- Recovery method if the Blizzard APIs stop responding when moving items
      self.timer = C_Timer.NewTimer(1, function()
        self.timer = nil
        Baganator.CallbackRegistry:TriggerEvent("TransferCancel")
        retryFunc()
      end)
      -- Wait for all affected caches to update before moving onto the next
      -- action
      for _, m in ipairs(self.modes) do
        Syndicator.CallbackRegistry:RegisterCallback(m, function(_, _, affected)
          local anyChanges = false
          for _, changed in pairs(affected) do
            anyChanges = anyChanges or changed
          end
          if not anyChanges then
            return
          end
          Baganator.CallbackRegistry:UnregisterCallback(m, self)
          pending = pending - 1
          if pending == 0 then
            Baganator.CallbackRegistry:TriggerEvent("TransferCancel")
            -- We save the timer so a TransferCancel event will be effective if
            -- done while this timer is pending.
            self.timer = C_Timer.NewTimer(0.1, function()
              self.timer = nil
              retryFunc()
            end)
          end
        end, self)
      end
    else -- waiting item data or item unlock
      self:SetScript("OnUpdate", retryFunc)
    end
  end
  parent.transferManager:SetScript("OnHide", function(self)
    Baganator.CallbackRegistry:TriggerEvent("TransferCancel")
  end)
end

-- Prevent coin icons getting offset on varying screen resolutions by removing
-- the coin icon offset
function Baganator.Utilities.GetMoneyString(amount, splitThousands)
  local result = GetMoneyString(amount, splitThousands)
  result = result:gsub("0:0:2:0", "12"):gsub("|T", " |T")
  return result
end

function Baganator.Utilities.GetExternalSortMethodName()
  local sortsDetails = addonTable.ExternalContainerSorts[Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)]
  return sortsDetails and BAGANATOR_L_USING_X:format(sortsDetails.label)
end

function Baganator.Utilities.GetGuildSortMethodName()
  local sortsDetails = addonTable.ExternalGuildBankSorts[Baganator.Config.Get(Baganator.Config.Options.GUILD_BANK_SORT_METHOD)]
  return sortsDetails and BAGANATOR_L_USING_X:format(sortsDetails.label)
end

function Baganator.Utilities.AutoSetGuildSortMethod()
  local method = Baganator.Config.Get(Baganator.Config.Options.GUILD_BANK_SORT_METHOD)
  if not addonTable.ExternalGuildBankSorts[method] then
    if method == "unset" and next(addonTable.ExternalGuildBankSorts) then
      local lowest, id = nil, nil
      for id, details in pairs(addonTable.ExternalGuildBankSorts) do
        if lowest == nil then
          lowest, id = details.priority, id
        elseif details.priority < lowest then
          lowest, id = details.priority, id
        end
      end
      Baganator.Config.Set("guild_bank_sort_method", id)
    elseif method ~= "none" and method ~= "unset" then
      Baganator.Config.ResetOne("guild_bank_sort_method")
    end
  end
end
