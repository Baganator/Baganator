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

  local offsetY = 0
  local lastOffsetX = 0
  local prevLayout = nil
  local endOfLineLabels = {}

  local categoriesInRow = {}
  local wrapIndex = 1
  local prevHeight = 0

  local function PredictRow()
    local offsetX = 0
    for _, details in ipairs(categoriesInRow) do
      local targetWidth = math.min(bagWidth, math.ceil(#details.layout.buttons/math.min(details.wrapLimit, wrapIndex)))
      details.targetWidth = targetWidth
      offsetX = offsetX + targetWidth * (iconSize + iconPadding) - iconPadding
      if offsetX > targetPixelWidth then
        return false
      end
      offsetX = offsetX + categorySpacing + iconPadding
    end
    return true
  end
  local function ArrangeRow()
    local offsetX = 0
    prevHeight = 0
    for _, details in ipairs(categoriesInRow) do
      local layout, label = details.layout, details.label
      layout:Flow(details.targetWidth)
      layout:Show()
      label:Resize()
      label:Show()
      label:SetPoint("TOPLEFT", offsetX + baseOffsetX, offsetY + baseOffsetY)
      label:SetWidth(math.min(layout:GetWidth() + categorySpacing, targetPixelWidth - offsetX))
      layout:SetPoint("TOPLEFT", offsetX + baseOffsetX, offsetY + baseOffsetY - label:GetHeight() - headerPadding / 2)
      prevHeight = math.max(layout:GetHeight() + label:GetHeight() + headerPadding * 3/2, prevHeight)
      details.offsetX = offsetX
      offsetX = offsetX + layout:GetWidth() + categorySpacing + iconPadding
    end
    lastOffsetX = offsetX - categorySpacing - iconPadding
  end

  local function NewLine()
    ArrangeRow()
    offsetY = offsetY - prevHeight
    maxWidth = math.max(maxWidth, lastOffsetX)
    table.insert(endOfLineLabels, categoriesInRow[#categoriesInRow])
    categoriesInRow = {}
    prevHeight = 0
    wrapIndex = 1
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
      prevLayout = layout
    elseif layout.type == "section" then
      if prevLayout and prevLayout.type == "category" then
        NewLine()
      end
      layout:Show()
      layout:SetSize(targetPixelWidth, 20)
      layout:SetPoint("TOPLEFT", baseOffsetX, baseOffsetY + offsetY)
      offsetY = offsetY - layout:GetHeight() - headerPadding
      prevLayout = layout
    elseif layout.type == "category" and #layout.buttons > 0 then
      table.insert(categoriesInRow, {layout = layout, label = activeLabels[index], rootLimit = math.ceil(math.max(math.log(#layout.buttons)/math.log(3), 1)), goldenLimit = math.max(math.floor(math.sqrt(#layout.buttons/1.618)), 1)})
      local oldWrapIndex = wrapIndex
        if wrapIndex > 1 then
          for _, details in ipairs(categoriesInRow) do
            details.wrapLimit = details.rootLimit
          end
        else
          for _, details in ipairs(categoriesInRow) do
            details.wrapLimit = details.goldenLimit
          end
        end
      while not PredictRow() do
        wrapIndex = wrapIndex + 1
        local bail = true
        for _, details in ipairs(categoriesInRow) do
          bail = bail and details.goldenLimit < wrapIndex
        end
        if wrapIndex > 1 then
          for _, details in ipairs(categoriesInRow) do
            details.wrapLimit = details.rootLimit
          end
        else
          for _, details in ipairs(categoriesInRow) do
            details.wrapLimit = details.goldenLimit
          end
        end
        if bail then
          wrapIndex = oldWrapIndex
          PredictRow()
          local details = table.remove(categoriesInRow)
          NewLine()
          table.insert(categoriesInRow, details)
          while not PredictRow() do
            wrapIndex = wrapIndex + 1
          end
          break
        end
      end
      prevLayout = layout
    end
  end
  maxWidth = math.max(maxWidth, lastOffsetX)

  if #categoriesInRow > 0 then
    ArrangeRow()
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

  local bottomSpacing = 2
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    bottomSpacing = 4
  end

  return maxWidth, -offsetY - headerPadding + bottomSpacing
end
