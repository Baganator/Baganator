local addonName, addonTable = ...

BaganatorCategoryViewsCategorySearchMixin = {}

function BaganatorCategoryViewsCategorySearchMixin:OnLoad()
  self:ResetCaches()
end

function BaganatorCategoryViewsCategorySearchMixin:ResetCaches()
  self.seenData = {}
end

function BaganatorCategoryViewsCategorySearchMixin:ApplySearches(searches, attachedItems, everything, callback)
  self.start = debugprofilestop()

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
  for _, item in ipairs(everything) do
    local key = item.key
    local seen = self.seenData[key]
    if not self.pending[key] then
      self.pending[key] = {}
      if not seen then
        item.isJunk = item.isJunkGetter and item.isJunkGetter()
        self.seenData[key] = item
        Baganator.Sorting.AddSortKeys({item})
      else
        seen.setInfo = item.setInfo
        setmetatable(item, {__index = self.seenData[key], __newindex = seen})
      end
    else
      setmetatable(item, {__index = self.seenData[key], __newindex = seen})
    end
    table.insert(self.pending[key], item)
  end

  local attachedItems = self.attachedItems[search]
  for search, items in pairs(self.attachedItems) do
    local results = self.results[search]

    for key in pairs(self.pending) do
      local seenData = self.seenData[key]
      local details = Baganator.CategoryViews.Utilities.GetAddedItemData(seenData.itemID, seenData.itemLink)
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

  self.sortMethod = Baganator.Config.Get("sort_method")
  if self.sortMethod == "combine_stacks_only" or addonTable.ExternalContainerSorts[self.sortMethod] then
    Baganator.Utilities.Message(BAGANATOR_L_SORT_METHOD_RESET_FOR_CATEGORIES)
    Baganator.Config.ResetOne(Baganator.Config.Options.SORT_METHOD)
    self.sortMethod = Baganator.Config.Get(Baganator.Config.Options.SORT_METHOD)
  end

  self:DoSearch()
end

function BaganatorCategoryViewsCategorySearchMixin:SortResults()
  local incomplete
  for search in pairs(self.sortPending) do
    self.results[search], incomplete = Baganator.Sorting.OrderOneListOffline(self.results[search], self.sortMethod)
    if not incomplete then
      self.sortPending[search] = nil
    end
  end

  if next(self.sortPending) == nil then
    self:SetScript("OnUpdate", nil)
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("search and sort took", debugprofilestop() - self.start)
    end
    self.callback(self.results)
  else
    self:SetScript("OnUpdate", self.SortResults)
  end
end

function BaganatorCategoryViewsCategorySearchMixin:DoSearch()
  if not self.searchPending then
    self.searchIndex = self.searchIndex + 1

    if self.searchIndex > #self.searches then
      self:SortResults()
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
