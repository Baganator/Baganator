function Baganator.Search.GetBaseInfoFromList(cachedItems, callback)
  local results = {}

  local waiting = #cachedItems
  for _, item in ipairs(cachedItems) do
    if item.itemID ~= nil then
      Baganator.Search.GetBaseInfo(item, function(info)
        table.insert(results, info)
      end, function(info)
        waiting = waiting - 1
        if waiting == 0 then
          callback(results)
        end
      end)
    else
      waiting = waiting - 1
      if waiting == 0 then
        callback(results)
      end
    end
  end

  if #cachedItems == 0 then
    callback(results)
  end
end
