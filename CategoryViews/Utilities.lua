Baganator.CategoryViews.Utilities = {}

-- Gets a table describing an item to be used in custom category's list of added
-- items
function Baganator.CategoryViews.Utilities.GetAddedItemData(itemID, itemLink)
  local petID = tonumber((itemLink:match("battlepet:(%d+)")))

  if petID then
    return { petID = petID }
  else
    return { itemID = itemID }
  end
end
