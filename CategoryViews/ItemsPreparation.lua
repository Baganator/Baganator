---@class addonTableBaganator
local addonTable = select(2, ...)

BaganatorCategoryViewsItemsPreparationMixin = {}

function BaganatorCategoryViewsItemsPreparationMixin:OnLoad()
  self:ResetCaches()
end

function BaganatorCategoryViewsItemsPreparationMixin:ResetCaches()
  self.seenData = {}
end

function BaganatorCategoryViewsItemsPreparationMixin:PrepareItems(everything, callback)
  -- Ensure junk plugins calculate correctly
  local waiting = 0
  local loopComplete = false
  local processedKey = {}

  for index, item in ipairs(everything) do
    local key = item.key
    -- Needs to be set here as the later code will ensure fields are shared,
    -- when invertedItemCount shouldn't be
    item.invertedItemCount = -item.itemCount
    item.index = index
    local seen = self.seenData[key]
    if not processedKey[key] then
      if not seen then
        seen = CopyTable(item)
        if seen.isJunkGetter or seen.isUpgradeGetter then
          if not C_Item.IsItemDataCachedByID(seen.itemID) then
            if C_Item.GetItemInfoInstant(seen.itemID) ~= nil then
              waiting = waiting + 1
              addonTable.Utilities.LoadItemData(seen.itemID, function()
                waiting = waiting - 1
                seen.isJunk = seen.isJunkGetter and seen.isJunkGetter()
                seen.isUpgrade = seen.isUpgradeGetter and seen.isUpgradeGetter()
                if waiting == 0 and loopComplete then
                  callback()
                end
              end)
            end
          else
            seen.isJunk = seen.isJunkGetter and seen.isJunkGetter()
            seen.isUpgrade = seen.isUpgradeGetter and seen.isUpgradeGetter()
          end
        end
        addonTable.Sorting.AddSortKeys({seen})
        self.seenData[key] = seen
      end
      seen.setInfo = item.setInfo
      setmetatable(item, {__index = seen, __newindex = seen})
      processedKey[key] = true
    else
      setmetatable(item, {__index = seen, __newindex = seen})
    end
  end

  loopComplete = true
  if waiting == 0 then
    callback()
  end
end

function BaganatorCategoryViewsItemsPreparationMixin:CleanItems(everything)
  for _, item in ipairs(everything) do
    setmetatable(item, nil)
  end
end
