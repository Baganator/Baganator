local addonName, addonTable = ...

function addonTable.CustomiseDialog.Initialize()
  local customiseDialog

  addonTable.CallbackRegistry:RegisterCallback("ShowCustomise", function()
    if not customiseDialog then
      customiseDialog = CreateFrame("Frame", "BaganatorCustomiseDialogFrame", UIParent, "BaganatorCustomiseDialogTemplate")
      customiseDialog:SetPoint("CENTER")
      table.insert(UISpecialFrames, customiseDialog:GetName())
    end
    customiseDialog.CloseButton:SetScript("OnClick", function()
      customiseDialog:Hide()
    end)
    customiseDialog:RefreshOptions()
    customiseDialog:SetShown(not customiseDialog:IsShown())
    customiseDialog:Raise()
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
