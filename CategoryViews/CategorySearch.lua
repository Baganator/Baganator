local _, addonTable = ...

local errorDialog = "Baganator_Categories_Search_Error"
StaticPopupDialogs[errorDialog] = {
  text = "",
  button1 = OKAY,
  timeout = 0,
  hideOnEscape = 1,
  hasEditBox = 1,
  OnShow = function(self)
    self.editBox:SetText("https://discord.gg/TtSN6DxSky")
    self.editBox:HighlightText()
  end,
  EditBoxOnEnterPressed = function(self)
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  editBoxWidth = 230,
}

BaganatorCategoryViewsCategoryFilterMixin = {}

function BaganatorCategoryViewsCategoryFilterMixin:OnLoad()
  self:ResetCaches()
end

function BaganatorCategoryViewsCategoryFilterMixin:OnHide()
  if self.timer then
    self.timer:Cancel()
    self.timer = nil
  end
end

function BaganatorCategoryViewsCategoryFilterMixin:ResetCaches()
  self.seenData = {}
end

function BaganatorCategoryViewsCategoryFilterMixin:ApplySearches(searches, attachedItems, everything, callback)
  self.start = debugprofilestop()

  if self.timer then
    self.timer:Cancel()
    self.timer = nil
  end

  self.searches = searches
  self.attachedItems = attachedItems
  self.searchIndex = 0
  self.callback = callback

  self.results = {}
  self.sortPending = {}
  self.searchPending = nil
  for _, search in ipairs(searches) do
    self.results[search] = {}
    self.sortPending[search] = true
  end

  self.pending = {}

  local function DoComplete()
    for search, items in pairs(self.attachedItems) do
      local results = self.results[search]

      for key in pairs(self.pending) do
        local seenData = self.seenData[key]
        local details = addonTable.CategoryViews.Utilities.GetAddedItemData(seenData.itemID, seenData.itemLink)
        local match = items["i:" .. tostring(details.itemID)] or items["p:" .. tostring(details.petID)] or items[key]
        if match then
          for _, i in ipairs(self.pending[key]) do
            i.addedDirectly = true
            table.insert(results, i)
          end
          self.pending[key] = nil
        end
      end
    end

    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_CATEGORIES_SEARCH) then
      self.timer = C_Timer.NewTimer(5, function()
        local items = ""
        if self.searchPending then
          for key in pairs(self.searchPending) do
            items = items .. "\n" .. key .. " item ID: " .. self.seenData[key].itemID
          end
        else
          items = "sorting failure"
        end
        StaticPopupDialogs[errorDialog].text = BAGANATOR_L_CATEGORIES_FAILED_WARNING:format(self.searches[self.searchIndex] or "$$$", items)
        StaticPopup_Show(errorDialog)
      end)
    end
    self:DoSearch()
  end

  -- Ensure junk plugins calculate correctly
  local waiting = 0
  local loopComplete = false

  for _, item in ipairs(everything) do
    local key = item.key
    -- Needs to be set here as the later code will ensure fields are shared,
    -- when invertedItemCount shouldn't be
    item.invertedItemCount = -item.itemCount
    local seen = self.seenData[key]
    if not self.pending[key] then
      self.pending[key] = {}
      if not seen then
        if item.isJunkGetter then
          if not C_Item.IsItemDataCachedByID(item.itemID) then
            local i = Item:CreateFromItemID(item.itemID)
            if not i:IsItemEmpty() then
              waiting = waiting + 1
              i:ContinueOnItemLoad(function()
                waiting = waiting - 1
                item.isJunk = item.isJunkGetter()
                if waiting == 0 and loopComplete then
                  DoComplete()
                end
              end)
            end
          else
            item.isJunk = item.isJunkGetter()
          end
        end
        self.seenData[key] = item
      else
        seen.setInfo = item.setInfo
        if self.seenData[key] ~= item then
          setmetatable(item, {__index = self.seenData[key], __newindex = seen})
        end
      end
    else
      setmetatable(item, {__index = self.seenData[key], __newindex = seen})
    end
    table.insert(self.pending[key], item)
  end

  loopComplete = true
  if waiting == 0 then
    DoComplete()
  end
end

function BaganatorCategoryViewsCategoryFilterMixin:DoSearch()
  if not self.searchPending then
    self.searchIndex = self.searchIndex + 1

    if self.searchIndex > #self.searches then
      if self.timer then
        self.timer:Cancel()
        self.timer = nil
      end

      self:SetScript("OnUpdate", nil)
      if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
        print("search took", debugprofilestop() - self.start)
      end
      self.callback(self.results)
      return
    end

    self.searchPending = {}
    for key in pairs(self.pending) do
      self.searchPending[key] = true
    end
  end

  local search = self.searches[self.searchIndex]

  local results = self.results[search]

  for key in pairs(self.searchPending) do
    local match = Syndicator.Search.CheckItem(self.seenData[key], search)
    if match ~= nil then
      self.searchPending[key] = nil
      if match then
        for _, i in ipairs(self.pending[key]) do
          setmetatable(i, nil)
          table.insert(results, i)
        end
        self.pending[key] = nil
      end
    end
  end

  if next(self.searchPending) == nil then
    self.searchPending = nil
    self:DoSearch()
  else
    self:SetScript("OnUpdate", self.DoSearch)
  end
end
