---@class addonTableBaganator
local addonTable = select(2, ...)

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

  holder:SetSize(300, 210)

  holder.HiddenCheckBox = GetCheckbox(addonTable.Locales.HIDDEN, holder, nil)

  holder.HiddenCheckBox:SetScript("OnClick", function()
    local hidden = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)
    hidden[addonTable.CategoryViews.Constants.EmptySlotsCategory] = holder.HiddenCheckBox:GetChecked()
    addonTable.Config.Set(addonTable.Config.Options.CATEGORY_HIDDEN, CopyTable(hidden))
  end)

  holder.GroupCheckBox = GetCheckbox(addonTable.Locales.GROUP_EMPTY_SLOTS, holder, holder.HiddenCheckBox)

  holder.GroupCheckBox:SetScript("OnClick", function()
    addonTable.Config.Set("category_group_empty_slots", holder.GroupCheckBox:GetChecked())
  end)

  holder:SetScript("OnShow", function()
    holder.HiddenCheckBox:SetChecked(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)[addonTable.CategoryViews.Constants.EmptySlotsCategory] == true)
    holder.GroupCheckBox:SetChecked(addonTable.Config.Get("category_group_empty_slots"))
  end)

  return holder
end
