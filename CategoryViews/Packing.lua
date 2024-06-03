function Baganator.CategoryViews.PackSimple(activeLayouts, activeLabels, baseOffsetX, baseOffsetY, bagWidth, dividerPoints, dividerPool)
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
  for index, layout in ipairs(activeLayouts) do
    layout:Show()
    if dividerPoints[index] and hasActiveLayout then
      local divider = dividerPool:Acquire()
      divider:Show()
      divider:SetSize(targetPixelWidth, 1)
      offsetY = offsetY - prevLayout:GetHeight() - headerPadding * 3/2 - prevLabel:GetHeight()
      divider:ClearAllPoints()
      divider:SetPoint("TOPLEFT", baseOffsetX, offsetY + baseOffsetY)
      divider:SetPoint("TOPRIGHT", divider:GetParent(), "TOPLEFT", baseOffsetX + targetPixelWidth, offsetY)
      offsetY = offsetY - divider:GetHeight() - headerPadding
      offsetX = 0
      hasActiveLayout = false
    end
    if layout:IsShown() and layout:GetHeight() > 0 then
      hasActiveLayout = true
      if math.floor(offsetX + layout:GetWidth()) > targetPixelWidth then
        prevLabel:SetWidth(targetPixelWidth - offsetX + prevLayout:GetWidth() + categorySpacing)
        offsetX = 0
        offsetY = offsetY - prevLayout:GetHeight() - prevLabel:GetHeight() - headerPadding / 2
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
  prevLabel:SetWidth(targetPixelWidth - offsetX + categorySpacing + prevLayout:GetWidth())

  return maxWidth, - offsetY + prevLayout:GetHeight() + prevLabel:GetHeight() + headerPadding / 2
end
