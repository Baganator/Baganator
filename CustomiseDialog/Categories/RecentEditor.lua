---@class addonTableBaganator
local addonTable = select(2, ...)

function addonTable.CustomiseDialog.GetCategoriesRecentEditor(parent)
  local holder = CreateFrame("Frame", nil, parent)

  holder:SetSize(300, 200)

  local valueMapping = {0, 15, 30, 60, 60 * 5, 60 * 10, 60 * 20, 60 * 40, 60 * 60, -1}
  local labelMapping = {addonTable.Locales.IMMEDIATE, "15s", "30s", "1m", "5m", "10m", "20m", "40m", "60m", addonTable.Locales.FOREVER}

  local slider = CreateFrame("Frame", nil, holder, "BaganatorCustomSliderTemplate")
  slider:Init({
    text = addonTable.Locales.RECENT_TIMER,
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

  local includeTransfers = addonTable.CustomiseDialog.GetCategoryEditorCheckBox(holder)
  includeTransfers:SetPoint("TOP", slider, "BOTTOM", 0, -5)
  includeTransfers.checkBox:SetScript("OnClick", function()
    addonTable.Config.Set("recent_include_owned", not addonTable.Config.Get("recent_include_owned"))
  end)

  local includeTransfersText = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  includeTransfersText:SetText(addonTable.Locales.RECENT_HEADER_CLICK_MESSAGE)
  includeTransfersText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 15, -20)
  includeTransfersText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -20)
  includeTransfersText:SetText(addonTable.Locales.RECENT_INCLUDE_OWNED)
  includeTransfersText:SetJustifyH("LEFT")

  local text = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetText(addonTable.Locales.RECENT_HEADER_CLICK_MESSAGE)
  text:SetPoint("TOPLEFT", 0, -140)
  text:SetPoint("TOPRIGHT", 0, -140)

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

  addonTable.Skins.AddFrame("Button", deleteButton)

  holder:SetScript("OnShow", function()
    slider:SetValue(tIndexOf(valueMapping, addonTable.Config.Get("recent_timeout")) or 2)
    includeTransfers.checkBox:SetChecked(addonTable.Config.Get("recent_include_owned"))
  end)

  return holder
end
