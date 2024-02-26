function Baganator.Search.GetBaseInfoFromList(cachedItems, callback)
  local results = {}

  local waiting = #cachedItems
  for _, item in ipairs(cachedItems) do
    Baganator.Search.GetBaseInfo(item, function(info)
      table.insert(results, info)
    end, function(info)
      waiting = waiting - 1
      if waiting == 0 then
        callback(results)
      end
    end)
  end
end
