BaganatorOfflineListSearchMixin = {}

function BaganatorOfflineListSearchMixin:OnLoad()
  self.list = {}
  self.pending = {}
  self.searchTerm = ""
end

function BaganatorOfflineListSearchMixin:OnUpdate()
  for details in pairs(self.pending) do
    local result = Baganator.Search.CheckItem(details, self.searchTerm)
    if result == true then
      table.insert(self.matching, details)
      self.pending[details] = nil
    elseif result == false then
      self.pending[details] = nil
    end
  end

  if next(self.pending) == nil then
    self.finishedCallback(self.matching)
    self:SetScript("OnUpdate", nil)
  end
end

function BaganatorOfflineListSearchMixin:Stop()
  self:SetScript("OnUpdate", nil)
end

function BaganatorOfflineListSearchMixin:StartSearch(baseInfoItems, text, finishedCallback)
  if text == "" then
    finishedCallback(baseInfoItems)
  end

  self.list = {}

  for index, item in ipairs(baseInfoItems) do
    item.index = index
    if item.itemLink ~= nil then
      table.insert(self.list, item)
    end
  end

  self.pending = {}
  self.matching = {}

  self.searchTerm = text
  self.finishedCallback = finishedCallback or function(matches) end

  for _, details in ipairs(self.list) do
    local result = Baganator.Search.CheckItem(details, self.searchTerm)
    if result == nil then
      self.pending[details] = true
    elseif result then
      table.insert(self.matching, details)
    end
  end

  if next(self.pending) then
    self:SetScript("OnUpdate", self.OnUpdate)
  else
    self.finishedCallback(self.matching)
  end
end
