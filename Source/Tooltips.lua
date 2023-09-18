Baganator.Tooltips = {}

function Baganator.Tooltips.AddLines(tooltip, summaries, itemLink)
  if itemLink == nil then
    return
  end

  local key = Baganator.Utilities.GetItemKey(itemLink)

  local tooltipInfo = summaries:GetTooltipInfo(key)

  table.sort(tooltipInfo, function(a, b)
    return a.bags + a.bank > b.bags + b.bank
  end)

  if #tooltipInfo == 0 then
    return
  end

  local result = "  "
  local bagCount, bankCount = 0, 0

  for index, s in ipairs(tooltipInfo) do
    bagCount = bagCount + s.bags
    bankCount = bankCount + s.bank
  end

  tooltip:AddLine("Inventory Totals: " .. WHITE_FONT_COLOR:WrapTextInColorCode("Bags " .. bagCount .. ", Banks " .. bankCount))

  for index = 1, math.min(#tooltipInfo, 4) do
    local s = tooltipInfo[index]
    tooltip:AddDoubleLine("  " .. s.character, WHITE_FONT_COLOR:WrapTextInColorCode("Bags: " .. s.bags .. ", Bank: " .. s.bank))
  end
  if #tooltipInfo > 4 then
    tooltip:AddLine("  ...")
  end
end
