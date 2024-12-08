local addonName, addonTable = ...

function addonTable.CustomiseDialog.Initialize()
  local customiseDialog = {}

  addonTable.CallbackRegistry:RegisterCallback("ShowCustomise", function()
    local currentSkin = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
    if not customiseDialog[currentSkin] then
      customiseDialog[currentSkin] = CreateFrame("Frame", "BaganatorCustomiseDialogFrame" .. currentSkin, UIParent, "BaganatorCustomiseDialogTemplate")
      customiseDialog[currentSkin]:SetPoint("CENTER")
      table.insert(UISpecialFrames, customiseDialog[currentSkin]:GetName())
      customiseDialog[currentSkin].CloseButton:SetScript("OnClick", function()
        customiseDialog[currentSkin]:Hide()
      end)
    end
    for key, dialog in pairs(customiseDialog) do
      if key ~= currentSkin and dialog:IsShown() then
        dialog:Hide()
        customiseDialog[currentSkin]:Hide()
        customiseDialog[currentSkin]:SetIndex(customiseDialog[key].lastIndex)
      end
    end

    customiseDialog[currentSkin]:RefreshOptions()
    customiseDialog[currentSkin]:SetShown(not customiseDialog[currentSkin]:IsShown())
    customiseDialog[currentSkin]:Raise()
  end)

  -- Create shortcut to open Baganator options from the Bliizzard addon options
  -- panel
  do
    local optionsFrame = CreateFrame("Frame")

    local instructions = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge3")
    instructions:SetPoint("CENTER", optionsFrame)
    instructions:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_TO_OPEN_OPTIONS_X))

    local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
    local versionText = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    versionText:SetPoint("CENTER", optionsFrame, 0, 28)
    versionText:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_VERSION_COLON_X:format(version)))

    local header = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge3")
    header:SetScale(3)
    header:SetPoint("CENTER", optionsFrame, 0, 30)
    header:SetText(LINK_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_BAGANATOR))

    local template = "SharedButtonLargeTemplate"
    if not C_XMLUtil.GetTemplateInfo(template) then
      template = "UIPanelDynamicResizeButtonTemplate"
    end
    local button = CreateFrame("Button", nil, optionsFrame, template)
    button:SetText(BAGANATOR_L_OPEN_OPTIONS)
    DynamicResizeButton_Resize(button)
    button:SetPoint("CENTER", optionsFrame, 0, -30)
    button:SetScale(2)
    button:SetScript("OnClick", function()
      addonTable.CallbackRegistry:TriggerEvent("ShowCustomise")
    end)


    optionsFrame.OnCommit = function() end
    optionsFrame.OnDefault = function() end
    optionsFrame.OnRefresh = function() end

    local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, BAGANATOR_L_BAGANATOR)
    category.ID = BAGANATOR_L_BAGANATOR
    Settings.RegisterAddOnCategory(category)
  end
end
