local _, addonTable = ...

function addonTable.CustomiseDialog.GetColorSwatch(parent, label, Save)
  local colorSwatch
  local colorPickerFrameMonitor = CreateFrame("Frame", nil, parent)
  colorPickerFrameMonitor.OnUpdate = function()
    if not ColorPickerFrame:IsVisible() then
      colorPickerFrameMonitor:SetScript("OnUpdate", nil)
    end
    if colorPickerFrameMonitor.changed then
      Save()
      colorSwatch.lastColor = colorSwatch.pendingColor
      colorSwatch.pendingColor = nil
    end
    colorPickerFrameMonitor.changed = false
  end
  colorPickerFrameMonitor:SetScript("OnHide", function() colorPickerFrameMonitor:SetScript("OnUpdate", nil) end)
  colorSwatch = CreateFrame("Button", nil, parent, "ColorSwatchTemplate")
  colorSwatch:SetPoint("RIGHT", -10, 0)
  colorSwatch:SetPoint("CENTER", label)
  colorSwatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  colorSwatch:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
      local info = {}
      info.r, info.g, info.b = colorSwatch.lastColor:GetRGBA()
      info.swatchFunc = function()
        colorPickerFrameMonitor.changed = true
        local r, g, b = ColorPickerFrame:GetColorRGB()
        colorSwatch.pendingColor = CreateColor(r, g, b)
        colorSwatch:SetColorRGB(r, g, b)
      end
      info.cancelFunc = function()
        colorSwatch.pendingColor = colorSwatch.lastColor
        colorSwatch:SetColorRGB(colorSwatch.lastColor:GetRGBA())
        Save()
        colorSwatch.pendingColor = nil
      end,
      colorPickerFrameMonitor:SetScript("OnUpdate", colorPickerFrameMonitor.OnUpdate)
      ColorPickerFrame:SetupColorPickerAndShow(info);
    else
      colorSwatch.pendingColor = CreateColor(1, 1, 1)
      colorSwatch.lastColor = colorSwatch.pendingColor
      colorSwatch:SetColorRGB(1, 1, 1)
      Save()
      -- Update tooltip to hide text about resetting the color
      colorSwatch:GetScript("OnLeave")(colorSwatch)
      colorSwatch:GetScript("OnEnter")(colorSwatch)
      colorSwatch.pendingColor = nil
    end
  end)
  colorSwatch:HookScript("OnEnter", function()
    GameTooltip:SetOwner(colorSwatch, "ANCHOR_TOP")
    GameTooltip:SetText(BAGANATOR_L_CHANGE_COLOR)
    local c = colorSwatch.lastColor
    if c.r ~= 1 or c.g ~= 1 or c.b ~= 1 then
      GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_RIGHT_CLICK_TO_RESET))
    end
    GameTooltip:Show()
  end)
  colorSwatch:HookScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return colorSwatch
end
