local _, addonTable = ...

BaganatorCategoryViewsCategorySortMixin = {}

function BaganatorCategoryViewsCategorySortMixin:ApplySorts(results, callback)
  self.start = debugprofilestop()
  self.callback = callback
  self.results = results
  self.sortPending = {}
  self.searchPending = nil
  for search, items in pairs(results) do
    self.sortPending[search] = true
  end

  self.sortMethod = addonTable.Config.Get("sort_method")
  if self.sortMethod == "combine_stacks_only" or addonTable.API.ExternalContainerSorts[self.sortMethod] then
    addonTable.Utilities.Message(BAGANATOR_L_SORT_METHOD_RESET_FOR_CATEGORIES)
    addonTable.Config.ResetOne(addonTable.Config.Options.SORT_METHOD)
    self.sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)
  end

  self:SortResults()
end

function BaganatorCategoryViewsCategorySortMixin:SortResults()
  local incomplete
  for search in pairs(self.sortPending) do
    self.results[search], incomplete = addonTable.Sorting.OrderOneListOffline(self.results[search], self.sortMethod)
    if not incomplete then
      self.sortPending[search] = nil
    end
  end

  if next(self.sortPending) == nil then
    self:SetScript("OnUpdate", nil)
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("sort took", debugprofilestop() - self.start)
    end
    self.callback(self.results)
  else
    self:SetScript("OnUpdate", self.SortResults)
  end
end
