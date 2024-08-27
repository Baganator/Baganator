local _, addonTable = ...

function addonTable.CustomiseDialog.GetCategoriesRecentEditor(parent)
  local holder = CreateFrame("Frame", nil, parent)

  holder:SetSize(300, 150)

  local valueMapping = {0, 15, 30, 60, 60 * 5, 60 * 10, 60 * 20, 60 * 40, 60 * 60, -1}
  local labelMapping = {BAGANATOR_L_IMMEDIATE, "15s", "30s", "1m", "5m", "10m", "20m", "40m", "60m", BAGANATOR_L_FOREVER}

  local slider = CreateFrame("Frame", nil, holder, "BaganatorCustomSliderTemplate")
  slider:Init({
    text = BAGANATOR_L_RECENT_TIMER,
    min = 1,
    max = #valueMapping,
    valueToText = labelMapping,
    callback = function(value)
      addonTable.Config.Set("recent_timeout", valueMapping[value])
    end
  })
  slider:SetPoint("LEFT")
  slider:SetPoint("RIGHT")
  slider:SetPoint("TOP", 0, -10)

  local text = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetText(BAGANATOR_L_RECENT_HEADER_CLICK_MESSAGE)
  text:SetPoint("TOPLEFT", 0, -80)
  text:SetPoint("TOPRIGHT", 0, -80)

  local deleteButton = CreateFrame("Button", nil, holder, "UIPanelDynamicResizeButtonTemplate")
  deleteButton:SetText(DELETE)
  DynamicResizeButton_Resize(deleteButton)
  deleteButton:SetPoint("BOTTOMRIGHT", -15, 0)

  deleteButton:SetScript("OnClick", function()
    local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)

    local oldIndex = tIndexOf(displayOrder, "default_auto_recents")
    if oldIndex then
      table.remove(displayOrder, oldIndex)
      addonTable.Config.Set(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER, CopyTable(displayOrder))
      holder:Return()
    end
  end)

  holder:SetScript("OnShow", function()
    slider:SetValue(tIndexOf(valueMapping, addonTable.Config.Get("recent_timeout")) or 2)
  end)

  return holder
end
