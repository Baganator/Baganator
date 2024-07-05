function Baganator.CategoryViews.PackSimple(activeLayouts, activeLabels, baseOffsetX, baseOffsetY, bagWidth, dividerPoints, dividerPool, sectionButtons)
  local iconPadding, iconSize = Baganator.ItemButtonUtil.GetPaddingAndSize()

  local headerPadding = 6
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    headerPadding = 3
  end

  local categorySpacing = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HORIZONTAL_SPACING) * (iconSize + iconPadding)

  local targetPixelWidth = bagWidth * (iconSize + iconPadding) - iconPadding

  local maxWidth = 0

  local offsetX, offsetY = 0, 0
  local prevLayout, prevLabel = nil, nil
  local hasActiveLayout = false
  local dividers = {}
  for index, layout in ipairs(activeLayouts) do
    layout:Show()
    if dividerPoints[index] and hasActiveLayout then
      if prevLabel then
        prevLabel:SetWidth(maxWidth - offsetX + categorySpacing + prevLayout:GetWidth())
      end
      local divider = dividerPool:Acquire()
      divider:Show()
      divider:SetSize(targetPixelWidth, 1)
      offsetY = offsetY - prevLayout:GetHeight() - headerPadding * 3/2 - prevLabel:GetHeight()
      divider:ClearAllPoints()
      divider:SetPoint("TOPLEFT", baseOffsetX, offsetY + baseOffsetY)
      table.insert(dividers, divider)
      offsetY = offsetY - divider:GetHeight() - headerPadding
      offsetX = 0
      hasActiveLayout = false
    end
    if sectionButtons[index] then
      if hasActiveLayout then
        if prevLabel then
          prevLabel:SetWidth(maxWidth - offsetX + categorySpacing + prevLayout:GetWidth())
        end
        offsetY = offsetY - prevLayout:GetHeight() - headerPadding * 3/2 - prevLabel:GetHeight()
        hasActiveLayout = false
      end
      local button = sectionButtons[index]
      button:Show()
      button:SetSize(targetPixelWidth, 20)
      button:SetPoint("TOPLEFT", baseOffsetX, baseOffsetY + offsetY)
      offsetY = offsetY - button:GetHeight() - headerPadding
      offsetX = 0
    end

    if layout:IsShown() and layout:GetHeight() > 0 then
      hasActiveLayout = true
      if math.floor(offsetX + layout:GetWidth()) > targetPixelWidth then
        prevLabel:SetWidth(targetPixelWidth - offsetX + prevLayout:GetWidth() + categorySpacing)
        offsetX = 0
        offsetY = offsetY - prevLayout:GetHeight() - prevLabel:GetHeight() - headerPadding * 3 / 2
      end
      local label = activeLabels[index]
      label:Resize()
      label:Show()
      label:SetPoint("TOPLEFT", offsetX + baseOffsetX, offsetY + baseOffsetY)
      label:SetWidth(math.min(layout:GetWidth() + categorySpacing, targetPixelWidth - offsetX))
      layout:SetPoint("TOPLEFT", offsetX + baseOffsetX, offsetY + baseOffsetY - label:GetHeight() - headerPadding / 2)
      offsetX = offsetX + layout:GetWidth()
      maxWidth = math.max(maxWidth, offsetX)
      offsetX = offsetX + categorySpacing + iconPadding
      prevLayout = layout
      prevLabel = label
    end
  end

  for _, divider in ipairs(dividers) do -- Ensure dividers don't overflow when width is reduced
    divider:SetPoint("RIGHT", divider:GetParent(), "LEFT", baseOffsetX + maxWidth, 0)
  end
  if hasActiveLayout then
    prevLabel:SetWidth(maxWidth - offsetX + categorySpacing + prevLayout:GetWidth())
    offsetY = offsetY - prevLayout:GetHeight() - prevLabel:GetHeight() - headerPadding / 2
  end

  return maxWidth, -offsetY
end
