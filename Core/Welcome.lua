local _, addonTable = ...
function addonTable.ShowWelcome()
  local frame = CreateFrame("Frame", "Baganator_WelcomeFrame", UIParent, "ButtonFrameTemplate")
  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  addonTable.Skins.AddFrame("ButtonFrame", frame)
  frame:EnableMouse(true)
  frame:SetPoint("CENTER")
  frame:SetToplevel(true)

  frame:SetSize(550, 180)

  frame:SetTitle(BAGANATOR_L_WELCOME_TO_BAGANATOR)

  local welcomeText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  welcomeText:SetText(BAGANATOR_L_WELCOME_DESCRIPTION)
  welcomeText:SetPoint("LEFT")
  welcomeText:SetPoint("RIGHT")
  welcomeText:SetPoint("TOP", 0, -40)

  local singleBagHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
  singleBagHeader:SetText(BAGANATOR_L_SINGLE_BAG)
  singleBagHeader:SetPoint("LEFT", 20, 0)
  singleBagHeader:SetPoint("RIGHT", frame, "CENTER", -10, 0)
  singleBagHeader:SetPoint("TOP", 0, -70)

  local singleBagText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  singleBagText:SetText(BAGANATOR_L_SINGLE_BAG_DESCRIPTION_2)
  singleBagText:SetPoint("LEFT", singleBagHeader)
  singleBagText:SetPoint("RIGHT", singleBagHeader)
  singleBagText:SetPoint("TOP", singleBagHeader, "BOTTOM", 0, -10)

  local categoryGroupsHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
  categoryGroupsHeader:SetText(BAGANATOR_L_CATEGORY_GROUPS)
  categoryGroupsHeader:SetPoint("RIGHT", -20, 0)
  categoryGroupsHeader:SetPoint("LEFT", frame, "CENTER", 10, 0)
  categoryGroupsHeader:SetPoint("TOP", 0, -70)

  local categoryGroupsText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  categoryGroupsText:SetText(BAGANATOR_L_CATEGORY_GROUPS_DESCRIPTION)
  categoryGroupsText:SetPoint("LEFT", categoryGroupsHeader)
  categoryGroupsText:SetPoint("RIGHT", categoryGroupsHeader)
  categoryGroupsText:SetPoint("TOP", categoryGroupsHeader, "BOTTOM", 0, -10)

  local function MakeChooseButton(value)
    local button = CreateFrame("Button", nil, frame, "UIPanelDynamicResizeButtonTemplate")
    button:SetText(BAGANATOR_L_CHOOSE)
    DynamicResizeButton_Resize(button)
    button:SetScript("OnClick", function()
      addonTable.CallbackRegistry:TriggerEvent("ResetFramePositions")
      addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, value)
      addonTable.Config.Set(addonTable.Config.Options.BANK_VIEW_TYPE, value)
      frame:Hide()
    end)
    return button
  end
  local chooseSingle = MakeChooseButton("single")
  local chooseCategories = MakeChooseButton("category")
  chooseSingle:SetPoint("CENTER", singleBagHeader)
  chooseSingle:SetPoint("BOTTOM", 0, 25)
  chooseCategories:SetPoint("CENTER", categoryGroupsHeader)
  chooseCategories:SetPoint("BOTTOM", 0, 25)
end
