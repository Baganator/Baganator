---@class addonTableBaganator
local addonTable = select(2, ...)

BaganatorCategoryViewsCategoryFilterMixin = {}

function BaganatorCategoryViewsCategoryFilterMixin:OnLoad()
  self:ResetCaches()
end

function BaganatorCategoryViewsCategoryFilterMixin:ResetCaches()
  self.searchCache = {}
end

function BaganatorCategoryViewsCategoryFilterMixin:Cancel()
  self:SetScript("OnUpdate", nil)
  if self.timer then
    self.timer:Cancel()
    self.timer = nil
  end
end

function BaganatorCategoryViewsCategoryFilterMixin:OnHide()
  self:Cancel()
end

function BaganatorCategoryViewsCategoryFilterMixin:ApplySearches(composed, everything, callback)
  self.start = debugprofilestop()

  if self.timer then
    self.timer:Cancel()
    self.timer = nil
  end

  self.searches = composed.prioritisedSearches
  self.searchIndex = 0
  self.callback = callback

  self.results = {}
  local indexMap = {}
  self.searchPending = nil
  for index, entry in ipairs(composed.details) do
    if entry.search then
      self.results[entry.search] = entry.results
      indexMap[entry.search] = index
    end
  end

  self.pending = {}

  self.cacheReject = {}

  for _, item in ipairs(everything) do
    if not self.pending[item.key] then
      self.pending[item.key] = {}
    end
    table.insert(self.pending[item.key], item)
  end

  local superAttachedItems = {}
  for _, search in ipairs(self.searches) do
    local details = composed.details[indexMap[search]]
    local items = details.attachedItems
    local search = details.search
    if items then
      for key, hit in pairs(items) do
        if hit and not superAttachedItems[key] and not superAttachedItems[hit] then
          superAttachedItems[key] = search
        end
      end
    end
  end

  for key, pendingForKey in pairs(self.pending) do
    local attachmentKey = addonTable.CategoryViews.Utilities.GetAddedItemData(pendingForKey[1].itemID, pendingForKey[1].itemLink)
    local match = superAttachedItems[key] or superAttachedItems[attachmentKey]
    if match then
      for _, i in ipairs(self.pending[key]) do
        rawset(i, "addedDirectly", true)
        table.insert(self.results[match], i)
      end
      self.pending[key] = nil
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
      addonTable.Dialogs.ShowCopy(addonTable.Locales.CATEGORIES_FAILED_WARNING:format(self.searches[self.searchIndex] or "$$$", items))
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
      self.callback()
      return
    end

    self.searchPending = {}
    for key in pairs(self.pending) do
      self.searchPending[key] = true
    end
  end

  if addonTable.CheckTimeout() then
    self:SetScript("OnUpdate", function()
      addonTable.ReportEntry()
      self:DoSearch()
    end)
    return
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
    self:SetScript("OnUpdate", function()
      addonTable.ReportEntry()
      self:DoSearch()
    end)
  end
end
