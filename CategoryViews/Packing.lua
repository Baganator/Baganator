local _, addonTable = ...
function addonTable.CategoryViews.PackSimple(activeLayouts, activeLabels, baseOffsetX, baseOffsetY, bagWidth, pixelMinWidth)
  local iconPadding, iconSize = addonTable.ItemButtonUtil.GetPaddingAndSize()

  local headerPadding = 6
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    headerPadding = 3
  end

  local categorySpacing = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HORIZONTAL_SPACING) * (iconSize + iconPadding)

  local targetPixelWidth = bagWidth * (iconSize + iconPadding) - iconPadding

  local maxWidth = 0

  local offsetX, offsetY = 0, 0
  local prevLayout, prevLabel = nil, nil
  local endOfLineLabels = {}

  local function NewLine()
    local labelOffsetX = offsetX - categorySpacing - iconPadding - prevLayout:GetWidth()
    table.insert(endOfLineLabels, {label = prevLabel, offsetX = labelOffsetX})
    offsetX = 0
    offsetY = offsetY - prevLayout:GetHeight() - prevLabel:GetHeight() - headerPadding * 3 / 2
  end

  for index, layout in ipairs(activeLayouts) do
    if layout.type == "divider" and prevLayout and prevLayout.type ~= "divider" then
      if prevLayout.type == "category" then
        NewLine()
      end
      layout:Show()
      layout:SetSize(targetPixelWidth, 1)
      layout:ClearAllPoints()
      layout:SetPoint("TOPLEFT", baseOffsetX, offsetY + baseOffsetY)
      offsetY = offsetY - layout:GetHeight() - headerPadding
      offsetX = 0
      prevLayout = layout
    elseif layout.type == "section" then
      if prevLayout and prevLayout.type == "category" then
        NewLine()
      end
      layout:Show()
      layout:SetSize(targetPixelWidth, 20)
      layout:SetPoint("TOPLEFT", baseOffsetX, baseOffsetY + offsetY)
      offsetY = offsetY - layout:GetHeight() - headerPadding
      offsetX = 0
      prevLayout = layout
    elseif layout.type == "category" and layout:GetHeight() > 0 then
      if prevLayout and prevLayout.type == "category" and math.floor(offsetX + layout:GetWidth()) > targetPixelWidth then
        NewLine()
      end
      layout:Show()
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

  for _, layout in ipairs(activeLayouts) do -- Ensure dividers don't overflow when width is reduced
    if layout.type == "divider" or layout.type == "section" then
      layout:SetPoint("RIGHT", layout:GetParent(), "LEFT", baseOffsetX + math.max(pixelMinWidth, maxWidth), 0)
    end
  end

  if prevLayout and prevLayout.type == "category" then
    NewLine()
  end

  for _, details in ipairs(endOfLineLabels) do
    details.label:SetWidth(math.max(pixelMinWidth, maxWidth) - details.offsetX)
  end

  if prevLayout then
    if prevLayout.type == "category" then
      offsetY = offsetY + headerPadding / 2
    elseif prevLayout.type == "divider" then
      prevLayout:Hide()
      offsetY = offsetY + prevLayout:GetHeight() + headerPadding
    end
  end

  return maxWidth, -offsetY - headerPadding
end
