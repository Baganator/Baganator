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

function BaganatorCategoryViewsCategoryFilterMixin:ResetCaches()
  self.searchCache = {}
end

function BaganatorCategoryViewsCategoryFilterMixin:OnHide()
  if self.timer then
    self.timer:Cancel()
    self.timer = nil
  end
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

  self.cacheReject = {}

  for _, item in ipairs(everything) do
    if not self.pending[item.key] then
      self.pending[item.key] = {}
    end
    table.insert(self.pending[item.key], item)
  end

  for search, items in pairs(self.attachedItems) do
    local results = self.results[search]

    for key, pendingForKey in pairs(self.pending) do
      local details = addonTable.CategoryViews.Utilities.GetAddedItemData(pendingForKey[1].itemID, pendingForKey[1].itemLink)
      local match = items["i:" .. tostring(details.itemID)] or items["p:" .. tostring(details.petID)] or items[key]
      if match then
        for _, i in ipairs(self.pending[key]) do
          rawset(i, "addedDirectly", true)
          table.insert(results, i)
        end
        self.pending[key] = nil
      end
    end
  end

  for key, items in pairs(self.pending) do
    local search = self.searchCache[key]
    if search then
      tAppendAll(self.results[search], items)
      self.pending[key] = nil
    end
  end

  if addonTable.Config.Get(addonTable.Config.Options.DEBUG_CATEGORIES_SEARCH) then
    self.timer = C_Timer.NewTimer(5, function()
      local items = ""
      if next(self.searchPending) then
        for key in pairs(self.searchPending) do
          items = items .. "\n" .. key .. " item ID: " .. self.pending[key][1].itemID
        end
      else
        items = "unknown failure"
      end
      StaticPopupDialogs[errorDialog].text = BAGANATOR_L_CATEGORIES_FAILED_WARNING:format(self.searches[self.searchIndex] or "$$$", items)
      StaticPopup_Show(errorDialog)
    end)
  end
  self:DoSearch()
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
        addonTable.Utilities.DebugOutput("search took", debugprofilestop() - self.start)
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

  local checkItem = Syndicator.Search.CheckItem
  for key in pairs(self.searchPending) do
    local match = checkItem(self.pending[key][1], search)
    if match ~= nil then
      self.searchPending[key] = nil
      if self.pending[key][1].fullMatchInfo[search] == nil then
        self.cacheReject[key] = true
      end
      if match then
        if not self.cacheReject[key] then
          self.searchCache[key] = search
        end
        for _, i in ipairs(self.pending[key]) do
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
