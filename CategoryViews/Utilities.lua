---@class addonTableBaganator
local addonTable = select(2, ...)
addonTable.CategoryViews.Utilities = {}

-- Gets a table describing an item to be used in custom category's list of added
-- items
function addonTable.CategoryViews.Utilities.GetAddedItemData(itemID, itemLink)
  local petID = tonumber((itemLink:match("battlepet:(%d+)")))

  if petID then
    return "p:" .. petID
  else
    return "i:" .. itemID
  end
end

function addonTable.CategoryViews.Utilities.GetBagTypes(characterData, section, indexes)
  local result = {}
  if not characterData.containerInfo or not characterData.containerInfo[section] then
    for index, bagID in ipairs(indexes) do
      table.insert(result, 0)
    end
    return result
  end

  local containerInfo = characterData.containerInfo[section]

  for index, bagID in ipairs(indexes) do
    local details = containerInfo[index - 1]
    local itemID = details and details.itemID

    table.insert(result, addonTable.Utilities.GetBagType(bagID, itemID))
  end
  return result
end

function addonTable.CategoryViews.Utilities.GetAddButtonsState()
  return addonTable.Config.Get(addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS) == "drag" or (
    addonTable.Config.Get(addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS) == "drag+alt" and IsAltKeyDown()
  )
end

function addonTable.CategoryViews.Utilities.GetMinWidth(rowWidth)
  local iconPadding, iconSize = addonTable.ItemButtonUtil.GetPaddingAndSize()
  return math.min(350, rowWidth * (iconSize + iconPadding) - iconPadding)
end
