---@class addonTableBaganator
local addonTable = select(2, ...)
local frame

function addonTable.ShowWelcome()
  addonTable.Config.Set(addonTable.Config.Options.SEEN_WELCOME, 1)
  if frame then
    frame:Show()
    return
  end

  frame = CreateFrame("Frame", "Baganator_WelcomeFrame", UIParent, "ButtonFrameTemplate")
  frame:Hide()
  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  addonTable.Skins.AddFrame("ButtonFrame", frame)
  frame:EnableMouse(true)
  frame:SetPoint("CENTER")
  frame:SetToplevel(true)

  frame:SetSize(550, 180)

  frame:SetTitle(addonTable.Locales.WELCOME_TO_BAGANATOR)

  local welcomeText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  welcomeText:SetText(addonTable.Locales.WELCOME_DESCRIPTION)
  welcomeText:SetPoint("LEFT")
  welcomeText:SetPoint("RIGHT")
  welcomeText:SetPoint("TOP", 0, -40)

  local singleBagHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
  singleBagHeader:SetText(addonTable.Locales.SINGLE_BAG)
  singleBagHeader:SetPoint("LEFT", 20, 0)
  singleBagHeader:SetPoint("RIGHT", frame, "CENTER", -10, 0)
  singleBagHeader:SetPoint("TOP", 0, -70)

  local singleBagText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  singleBagText:SetText(addonTable.Locales.SINGLE_BAG_DESCRIPTION_2)
  singleBagText:SetPoint("LEFT", singleBagHeader)
  singleBagText:SetPoint("RIGHT", singleBagHeader)
  singleBagText:SetPoint("TOP", singleBagHeader, "BOTTOM", 0, -10)

  local categoryGroupsHeader = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
  categoryGroupsHeader:SetText(addonTable.Locales.CATEGORY_GROUPS)
  categoryGroupsHeader:SetPoint("RIGHT", -20, 0)
  categoryGroupsHeader:SetPoint("LEFT", frame, "CENTER", 10, 0)
  categoryGroupsHeader:SetPoint("TOP", 0, -70)

  local categoryGroupsText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  categoryGroupsText:SetText(addonTable.Locales.CATEGORY_GROUPS_DESCRIPTION)
  categoryGroupsText:SetPoint("LEFT", categoryGroupsHeader)
  categoryGroupsText:SetPoint("RIGHT", categoryGroupsHeader)
  categoryGroupsText:SetPoint("TOP", categoryGroupsHeader, "BOTTOM", 0, -10)

  local function MakeChooseButton(value)
    local button = CreateFrame("Button", nil, frame, "UIPanelDynamicResizeButtonTemplate")
    button:SetText(addonTable.Locales.CHOOSE)
    DynamicResizeButton_Resize(button)
    button:SetScript("OnClick", function()
      addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, value)
      addonTable.Config.Set(addonTable.Config.Options.BANK_VIEW_TYPE, value)
      frame:Hide()
    end)
    addonTable.Skins.AddFrame("Button", button)
    return button
  end
  local chooseSingle = MakeChooseButton("single")
  local chooseCategories = MakeChooseButton("category")
  chooseSingle:SetPoint("CENTER", singleBagHeader)
  chooseSingle:SetPoint("BOTTOM", 0, 25)
  chooseCategories:SetPoint("CENTER", categoryGroupsHeader)
  chooseCategories:SetPoint("BOTTOM", 0, 25)

  local categoryBag, singleBag

  frame:SetScript("OnShow", function ()
    addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, "category")
    categoryBag = addonTable.ViewManagement.GetBackpackFrame()
    addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, "single")
    singleBag = addonTable.ViewManagement.GetBackpackFrame()

    categoryBag:ClearAllPoints()
    categoryBag:SetPoint("LEFT", frame, "RIGHT", 20, 0)
    categoryBag:Show()
    categoryBag:UpdateForCharacter(Syndicator.API.GetCurrentCharacter(), true)
    singleBag:ClearAllPoints()
    singleBag:SetPoint("RIGHT", frame, "LEFT", -20, 0)
    singleBag:Show()
    singleBag:UpdateForCharacter(Syndicator.API.GetCurrentCharacter(), true)

    frame:Raise()
  end)

  frame:SetScript("OnHide", function()
    singleBag:Hide()
    categoryBag:Hide()
    addonTable.CallbackRegistry:TriggerEvent("ResetFramePositions")
    addonTable.CallbackRegistry:TriggerEvent("BagShow")
  end)

  frame:Show()
end
