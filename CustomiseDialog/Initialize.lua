local addonName, addonTable = ...

function addonTable.CustomiseDialog.Initialize()
  local customiseDialog = {} -- Stored by skin applied

  addonTable.CallbackRegistry:RegisterCallback("ShowCustomise", function()
    local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
    if not customiseDialog[currentSkinKey] then
      customiseDialog[currentSkinKey] = CreateFrame("Frame", "BaganatorCustomiseDialogFrame" .. currentSkinKey, UIParent, "BaganatorCustomiseDialogTemplate")
      customiseDialog[currentSkinKey]:SetPoint("CENTER")
      table.insert(UISpecialFrames, customiseDialog[currentSkinKey]:GetName())
      customiseDialog[currentSkinKey].CloseButton:SetScript("OnClick", function()
        customiseDialog[currentSkinKey]:Hide()
      end)
    end
    for key, dialog in pairs(customiseDialog) do
      if key ~= currentSkinKey and dialog:IsShown() then
        dialog:Hide()
        customiseDialog[currentSkinKey]:Hide()
        customiseDialog[currentSkinKey]:SetIndex(customiseDialog[key].lastIndex)
        customiseDialog[currentSkinKey]:ClearAllPoints()
        for i = 1, dialog:GetNumPoints() do
          customiseDialog[currentSkinKey]:SetPoint(dialog:GetPoint(i))
        end
      end
    end

    customiseDialog[currentSkinKey]:RefreshOptions()
    customiseDialog[currentSkinKey]:SetShown(not customiseDialog[currentSkinKey]:IsShown())
    customiseDialog[currentSkinKey]:Raise()
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
