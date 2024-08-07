local _, addonTable = ...

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

  for _, item in ipairs(everything) do
    local key = item.key
    -- Needs to be set here as the later code will ensure fields are shared,
    -- when invertedItemCount shouldn't be
    item.invertedItemCount = -item.itemCount
    local seen = self.seenData[key]
    if not processedKey[key] then
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
                  callback()
                end
              end)
            end
          else
            item.isJunk = item.isJunkGetter()
          end
        end
        seen = CopyTable(item)
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
