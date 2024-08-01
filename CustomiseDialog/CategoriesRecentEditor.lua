local _, addonTable = ...

function addonTable.CustomiseDialog.GetCategoriesRecentEditor(parent)
  local holder = CreateFrame("Frame", nil, parent)

  holder:SetSize(300, 200)

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

  holder:SetScript("OnShow", function()
    slider:SetValue(tIndexOf(valueMapping, addonTable.Config.Get("recent_timeout")) or 2)
  end)

  addonTable.CallbackRegistry:RegisterCallback("EditCategoryRecent", function()
    holder:Show()
  end)

  return holder
end

local function GetCheckbox(text, holder, previous)
  local checkBoxWrapper = CreateFrame("Frame", nil, holder)
  local checkBox
  checkBoxWrapper:SetHeight(40)
  checkBoxWrapper:SetPoint("LEFT")
  checkBoxWrapper:SetPoint("RIGHT")
  if not previous then
    checkBoxWrapper:SetPoint("TOP", 0, -10)
  else
    checkBoxWrapper:SetPoint("TOP", previous, "BOTTOM")
  end
  checkBoxWrapper:SetScript("OnEnter", function() checkBox:OnEnter() end)
  checkBoxWrapper:SetScript("OnLeave", function() checkBox:OnLeave() end)
  checkBoxWrapper:SetScript("OnMouseUp", function() checkBox:Click() end)
  if DoesTemplateExist("SettingsCheckBoxTemplate") then
    checkBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckBoxTemplate")
  else
    checkBox = CreateFrame("CheckButton", nil, checkBoxWrapper, "SettingsCheckboxTemplate")
  end
  checkBox:SetPoint("LEFT", checkBoxWrapper, "CENTER", 0, 0)
  checkBox:SetText(text)
  checkBox:SetNormalFontObject(GameFontHighlight)
  checkBox:GetFontString():SetPoint("RIGHT", checkBoxWrapper, "CENTER", -20, 0)
  addonTable.Skins.AddFrame("CheckBox", checkBox)

  return checkBox
end

function addonTable.CustomiseDialog.GetCategoriesEmptyEditor(parent)
  local holder = CreateFrame("Frame", nil, parent)

  holder:SetSize(300, 200)

  holder.HiddenCheckBox = GetCheckbox(BAGANATOR_L_HIDDEN, holder, nil)

  holder.HiddenCheckBox:SetScript("OnClick", function()
    local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
    hidden[addonTable.CategoryViews.Constants.EmptySlotsCategory] = holder.HiddenCheckBox:GetChecked()
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
  end)

  holder.GroupCheckBox = GetCheckbox(BAGANATOR_L_GROUP_EMPTY_SLOTS, holder, holder.HiddenCheckBox)

  holder.GroupCheckBox:SetScript("OnClick", function()
    addonTable.Config.Set("category_group_empty_slots", holder.GroupCheckBox:GetChecked())
  end)

  holder:SetScript("OnShow", function()
    holder.HiddenCheckBox:SetChecked(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)[addonTable.CategoryViews.Constants.EmptySlotsCategory] == true)
    holder.GroupCheckBox:SetChecked(addonTable.Config.Get("category_group_empty_slots"))
  end)

  addonTable.CallbackRegistry:RegisterCallback("EditCategoryEmpty", function()
    holder:Show()
  end)

  return holder
end
