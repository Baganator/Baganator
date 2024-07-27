local _, addonTable = ...

BaganatorCategoryViewsCategorySortMixin = {}

function BaganatorCategoryViewsCategorySortMixin:OnLoad()
end

function BaganatorCategoryViewsCategorySortMixin:ApplySorts(results, callback)
  self.callback = callback
  self.sortPending = {}
  self.searchPending = nil
  for search in pairs(results) do
    self.sortPending[search] = true
  end

  self:SetScript("OnUpdate", self.SortResults)
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
      print("search and sort took", debugprofilestop() - self.start)
    end
    self.callback(self.results)
  else
    self:SetScript("OnUpdate", self.SortResults)
  end
end
