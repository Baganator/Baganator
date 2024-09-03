local _, addonTable = ...

BaganatorCategoryViewsCategorySortMixin = {}

function BaganatorCategoryViewsCategorySortMixin:Cancel()
  self:SetScript("OnUpdate", nil)
end

function BaganatorCategoryViewsCategorySortMixin:OnHide()
  self:Cancel()
end

function BaganatorCategoryViewsCategorySortMixin:ApplySorts(composed, callback)
  self.start = debugprofilestop()
  self.callback = callback
  self.composedDetails = composed.details
  self.sortPending = {}
  for index, details in ipairs(composed.details) do
    if details.results and #details.results > 0 then
      self.sortPending[index] = true
    end
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
  for index in pairs(self.sortPending) do
    self.composedDetails[index].results, incomplete = addonTable.Sorting.OrderOneListOffline(self.composedDetails[index].results, self.sortMethod)
    if not incomplete then
      self.sortPending[index] = nil
    end
  end

  if next(self.sortPending) == nil then
    self:SetScript("OnUpdate", nil)
    if addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) then
      addonTable.Utilities.DebugOutput("sort took", debugprofilestop() - self.start)
    end
    self.callback()
  else
    self:SetScript("OnUpdate", self.SortResults)
  end
end
