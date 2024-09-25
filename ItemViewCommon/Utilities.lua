local _, addonTable = ...

local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

function addonTable.Utilities.ApplyVisuals(frame)
  if TSM_API then
    frame:SetFrameStrata("HIGH")
  end

  local alpha = addonTable.Config.Get(addonTable.Config.Options.VIEW_ALPHA)
  local noFrameBorders = addonTable.Config.Get(addonTable.Config.Options.NO_FRAME_BORDERS)

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

function addonTable.Utilities.GetAllCharacters(searchText)
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

function addonTable.Utilities.ShouldShowSortButton()
  return addonTable.Config.Get(addonTable.Config.Options.SHOW_SORT_BUTTON)
end

function addonTable.Utilities.CountEmptySlots(cachedBag)
  local empty = 0
  for _, slotContents in ipairs(cachedBag) do
    if next(slotContents) == nil then
      empty = empty + 1
    end
  end

  return empty
end

function addonTable.Utilities.GetRandomSearchesText()
  local term = addonTable.Constants.SampleSearchTerms[random(#addonTable.Constants.SampleSearchTerms)]

  return BAGANATOR_L_SEARCH_TRY_X:format(term)
end

function addonTable.Utilities.AddBagSortManager(parent)
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
    if status == addonTable.Constants.SortStatus.Complete then
      completeFunc()
    elseif status == addonTable.Constants.SortStatus.WaitingMove then
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

function addonTable.Utilities.AddBagTransferManager(parent)
  parent.transferManager = CreateFrame("Frame", nil, parent)
  -- Tidy up all the recovery methods so they don't trigger after everything is
  -- complete
  addonTable.CallbackRegistry:RegisterCallback("TransferCancel", function(self)
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
    addonTable.CallbackRegistry:TriggerEvent("TransferCancel")
    self.modes = modes
    if status == addonTable.Constants.SortStatus.Complete then
      completeFunc()
    elseif status == addonTable.Constants.SortStatus.WaitingMove then
      local pending = #modes
      -- Recovery method if the Blizzard APIs stop responding when moving items
      self.timer = C_Timer.NewTimer(1, function()
        self.timer = nil
        addonTable.CallbackRegistry:TriggerEvent("TransferCancel")
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
          addonTable.CallbackRegistry:UnregisterCallback(m, self)
          pending = pending - 1
          if pending == 0 then
            addonTable.CallbackRegistry:TriggerEvent("TransferCancel")
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
    addonTable.CallbackRegistry:TriggerEvent("TransferCancel")
  end)
end

-- Prevent coin icons getting offset on varying screen resolutions by removing
-- the coin icon offset
function addonTable.Utilities.GetMoneyString(amount, splitThousands)
  local result = GetMoneyString(amount, splitThousands)
  result = result:gsub("0:0:2:0", "12"):gsub("|T", " |T")
  return result
end

function addonTable.Utilities.AddGeneralDropSlot(parent, getData, bagIndexes)
  local function UpdateVisibility()
    if parent.isLive then
      local cursorType, itemID = GetCursorInfo()
      parent.backgroundButton:SetShown(cursorType == "item")
      parent.backgroundButton:SetFrameLevel(parent.ScrollBox:GetFrameLevel() + 1)
    else
      parent.backgroundButton:Hide()
    end
  end
  if parent.backgroundButton then
    UpdateVisibility()
    return
  end

  local pool = parent.liveItemButtonPool or addonTable.ItemViewCommon.GetLiveItemButtonPool(parent)

  local indexFrame = CreateFrame("Frame", nil, parent.Container)
  parent.backgroundButton = pool:Acquire()
  parent.backgroundButton:SetParent(indexFrame)
  parent.backgroundButton:SetMotionScriptsWhileDisabled(true)
  parent.backgroundButton:ClearAllPoints()
  parent.backgroundButton:SetAllPoints(parent.Container, true)
  parent.backgroundButton:ClearHighlightTexture()
  parent.backgroundButton:ClearNormalTexture()
  parent.backgroundButton:ClearDisabledTexture()
  parent.backgroundButton:ClearPushedTexture()
  for _, child in ipairs({parent.backgroundButton:GetRegions()}) do
    child:Hide()
  end

  UpdateVisibility()
  parent.backgroundButton:RegisterEvent("CURSOR_CHANGED")
  parent.backgroundButton:SetScript("OnEvent", UpdateVisibility)

  parent.backgroundButton:SetScript("OnEnter", nil)
  parent.backgroundButton:SetScript("OnLeave", nil)
  parent.backgroundButton:SetScript("PreClick", function(self)
    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
      local usageChecks = addonTable.Sorting.GetBagUsageChecks(bagIndexes)
      local sortedBagIDs = CopyTable(bagIndexes)
      table.sort(sortedBagIDs, function(a, b) return usageChecks.sortOrder[a] < usageChecks.sortOrder[b] end)
      local currentCharacterBags = getData()
      local backupBagID = nil
      for _, bagID in ipairs(sortedBagIDs) do
        if not usageChecks.checks[bagID] or usageChecks.checks[bagID]({itemID = itemID}) then
          local bag = currentCharacterBags[tIndexOf(bagIndexes, bagID)]
          for index, slot in ipairs(bag) do
            if slot.itemID == nil then
              self:Enable()
              self:SetID(index)
              self:GetParent():SetID(bagID)
              return
            end
          end
        end
        if not usageChecks.checks[bagID] then
          backupBagID = usageChecks.checks[bagID]
        end
      end
      self:Disable()
      self:SetID(1)
      self:GetParent():SetID(backupBagID or sortedBagIDs[1])
    end
  end)
end

function addonTable.Utilities.AddScrollBar(self)
  self.ScrollBox = CreateFrame("Frame", nil, self, "WowScrollBox")
  self.ScrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
  addonTable.Skins.AddFrame("TrimScrollBar", self.ScrollBar)
  self.ScrollChild = CreateFrame("Frame", nil, self.ScrollBox)
  self.ScrollChild.scrollable = true
  self.Container:SetParent(self.ScrollChild)
  self.Container:ClearAllPoints()
  -- Offset is to prevent default item buttons getting edges cropped on edges of
  -- container
  self.Container:SetPoint("TOPLEFT", 2, -2)
  ScrollUtil.InitScrollBoxWithScrollBar(self.ScrollBox, self.ScrollBar, CreateScrollBoxLinearView())
  ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar)

  function self:UpdateScroll(ySaved, scale)
    local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()
    self.ScrollBox:ClearAllPoints()
    self.ScrollBox:SetPoint("TOPLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset - 2 - 2, -50 - topSpacing / 4 + 2)
    self.ScrollChild:SetWidth(self.Container:GetWidth() + 4)
    self.ScrollChild:SetHeight(self.Container:GetHeight() + 4)
    self.ScrollBox:SetSize(
      self.Container:GetWidth() + 4,
      math.min(
        self.Container:GetHeight() + 4,
        UIParent:GetHeight() / scale - ySaved
      )
    )
    self.ScrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
    if self.ScrollBar:IsShown() then
      local xOffset = 7 + sideSpacing / 2 - 2
      if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
        xOffset = 4
      end
      self.ScrollBar:SetPoint("TOPLEFT", self.ScrollBox, "TOPRIGHT", xOffset, -2)
      self.ScrollBar:SetPoint("BOTTOMLEFT", self.ScrollBox, "BOTTOMRIGHT", xOffset, 2)
      self:SetWidth(self:GetWidth() + 10 + sideSpacing / 2)
    end
  end
end

function addonTable.Utilities.GetExternalSortMethodName()
  local sortsDetails = addonTable.API.ExternalContainerSorts[addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)]
  return sortsDetails and BAGANATOR_L_USING_X:format(sortsDetails.label)
end

function addonTable.Utilities.GetBagType(bagID, itemID)
  local classID, subClassID
  if itemID then
    classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
  end
  local iconDetails = addonTable.Constants.ContainerKeyToInfo[subClassID]
  if classID ~= nil and classID == Enum.ItemClass.Quiver then
    return "quiver"
  elseif iconDetails then
    return subClassID
  elseif addonTable.Constants.IsRetail and bagID == Enum.BagIndex.ReagentBag then
    return "reagentBag"
  elseif addonTable.Constants.IsRetail and bagID == Enum.BagIndex.Reagentbank then
    return "reagentBag"
  elseif bagID == Enum.BagIndex.Keyring then
    return "keyring"
  else
    return 0 -- regular bag
  end
end

-- Anchor is relative to UIParent
function addonTable.Utilities.ConvertAnchorToCorner(targetCorner, frame)
  if targetCorner == "TOPLEFT" then
    return "TOPLEFT", frame:GetLeft(), frame:GetTop() - UIParent:GetTop()/frame:GetScale()
  elseif targetCorner == "TOPRIGHT" then
    return "TOPRIGHT", frame:GetRight() - UIParent:GetRight()/frame:GetScale(), frame:GetTop() - UIParent:GetTop()/frame:GetScale()
  elseif targetCorner == "BOTTOMLEFT" then
    return "BOTTOMLEFT", frame:GetLeft(), frame:GetBottom()
  elseif targetCorner == "BOTTOMRIGHT" then
    return "BOTTOMRIGHT", frame:GetRight() - UIParent:GetRight()/frame:GetScale(), frame:GetBottom()
  elseif targetCorner == "RIGHT" then
    return "RIGHT", frame:GetRight() - UIParent:GetRight()/frame:GetScale(), select(2, frame:GetCenter()) - select(2, UIParent:GetCenter())/frame:GetScale()
  elseif targetCorner == "LEFT" then
    return "LEFT", frame:GetLeft(), select(2, frame:GetCenter()) - select(2, UIParent:GetCenter())/frame:GetScale()
  elseif targetCorner == "TOP" then
    return "TOP", select(1, frame:GetCenter() - select(1, UIParent:GetCenter())/frame:GetScale()), (frame:GetTop() - UIParent:GetTop()/frame:GetScale())
  elseif targetCorner == "BOTTOM" then
    return "BOTTOM", select(1, frame:GetCenter()) - select(1, UIParent:GetCenter())/frame:GetScale(), frame:GetBottom()
  else
    error("Unknown anchor")
  end
end

function addonTable.Utilities.GetSpacing()
  local sideSpacing, topSpacing = 13, 14
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    sideSpacing = 8
    topSpacing = 7
  end

  return sideSpacing, topSpacing
end

addonTable.Utilities.MasqueRegistration = function() end

if LibStub then
  -- Establish a reference to Masque.
  local Masque, MSQ_Version = LibStub("Masque", true)
  if Masque ~= nil then
    -- Retrieve a reference to a new or existing group.
    local masqueGroup = Masque:Group("Baganator", "Bag")

    addonTable.Utilities.MasqueRegistration = function(button)
      if button.masqueApplied then
        masqueGroup:ReSkin(button)
      else
        button.masqueApplied = true
        masqueGroup:AddButton(button, nil, "Item")
      end
    end
  end
end
