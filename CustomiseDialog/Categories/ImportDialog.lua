---@class addonTableBaganator
local addonTable = select(2, ...)

local dialogsBySkin = {}

function addonTable.CustomiseDialog.ShowCategoriesImportDialog(callback)
  local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
  if not dialogsBySkin[currentSkinKey] then
    local dialog = CreateFrame("Frame", "BaganatorCustomiseDialogCategoriesImportDialog", UIParent)
    dialog:SetToplevel(true)
    table.insert(UISpecialFrames, "BaganatorCustomiseDialogCategoriesImportDialog")
    dialog:SetPoint("TOP", 0, -135)
    dialog:EnableMouse(true)
    dialog:SetFrameStrata("DIALOG")

    dialog.NineSlice = CreateFrame("Frame", nil, dialog, "NineSlicePanelTemplate")
    NineSliceUtil.ApplyLayoutByName(dialog.NineSlice, "Dialog", dialog.NineSlice:GetFrameLayoutTextureKit())

    local bg = dialog:CreateTexture(nil, "BACKGROUND", nil, -1)
    bg:SetColorTexture(0, 0, 0, 0.8)
    bg:SetPoint("TOPLEFT", 11, -11)
    bg:SetPoint("BOTTOMRIGHT", -11, 11)

    dialog:SetSize(500, 110)

    local text = dialog:CreateFontString(nil, nil, "GameFontHighlight")
    text:SetText(addonTable.Locales.PASTE_YOUR_IMPORT_STRING_HERE)
    text:SetPoint("TOP", 0, -20)

    local buffer, bufferIndex, pasteTimestamp
    local currentText = ""

    local editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    local fakeText = editBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fakeText:SetAllPoints()
    fakeText:SetMaxLines(1)
    fakeText:SetJustifyH("LEFT")
    editBox:SetMaxBytes(1)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnChar", function(_, char)
      if pasteTimestamp ~= GetTime() then
        currentText = ""
        buffer, bufferIndex, pasteTimestamp = {}, 0, GetTime()
        editBox:SetScript("OnUpdate", function()
          editBox:SetScript("OnUpdate", nil)
          currentText = table.concat(buffer)
          fakeText:SetText(currentText:sub(1, 500))
        end)
      end
      bufferIndex = bufferIndex + 1
      buffer[bufferIndex] = char
    end)
    editBox:SetScript("OnEditFocusGained", function()
      fakeText:SetText("")
      pasteTimestamp = nil
    end)
    editBox:SetScript("OnEditFocusLost", function()
      editBox:SetScript("OnUpdate", nil)
    end)

    editBox:SetSize(350, 30)
    editBox:SetPoint("CENTER")

    local acceptButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    acceptButton:SetText(addonTable.Locales.IMPORT)
    DynamicResizeButton_Resize(acceptButton)
    local cancelButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    cancelButton:SetText(CANCEL)
    DynamicResizeButton_Resize(cancelButton)

    acceptButton:SetPoint("TOPRIGHT", dialog, "CENTER", -5, -18)
    cancelButton:SetPoint("TOPLEFT", dialog, "CENTER", 5, -18)

    acceptButton:SetScript("OnClick", function()
      if currentText ~= "" then
        dialog.callback(currentText)
      end
      dialog:Hide()
    end)
    editBox:SetScript("OnEnterPressed", function()
      acceptButton:Click()
    end)
    cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)
    dialog:SetScript("OnShow", function()
      fakeText:SetText("")
      currentText = ""

      PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    end)
    dialog:SetScript("OnHide", function()
      PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    end)

    addonTable.Skins.AddFrame("Dialog", dialog)
    addonTable.Skins.AddFrame("EditBox", editBox)
    addonTable.Skins.AddFrame("Button", acceptButton)
    addonTable.Skins.AddFrame("Button", cancelButton)

    dialog.editBox = editBox
    dialogsBySkin[currentSkinKey] = dialog
  end

  local dialog = dialogsBySkin[currentSkinKey]
  dialog:Hide()
  dialog.callback = callback
  dialog:Show()
  dialog.editBox:SetFocus()
end
