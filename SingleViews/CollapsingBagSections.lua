local _, addonTable = ...
function addonTable.SingleViews.GetCollapsingBagDetails(character, section, indexes, slotsCount)
  local characterInfo = Syndicator.API.GetCharacter(character)
  if characterInfo.containerInfo == nil or characterInfo.containerInfo[section] == nil then
    local cleanMain = {}
    for i = 1, #indexes do
      table.insert(cleanMain, i)
    end
    return {
      main = cleanMain,
      special = {},
    }
  end
  local containerInfo = characterInfo.containerInfo[section]
  local mainBags, inSlots = {}, {}
  local seenIndexes = {}

  for index = 1, slotsCount do
    if containerInfo[index] and containerInfo[index].itemID ~= nil then
      local key = addonTable.Utilities.GetBagType(nil, containerInfo[index].itemID)
      local bagIndex = index + 1
      if key ~= 0 then
        seenIndexes[bagIndex] = true
        inSlots[key] = inSlots[key] or {}
        table.insert(inSlots[key], bagIndex)
      end
    end
  end

  for bagIndex, bagID in ipairs(indexes) do
    if not seenIndexes[bagIndex] then
      local bagType = addonTable.Utilities.GetBagType(bagID, nil)
      seenIndexes[bagIndex] = true
      if bagType and bagType ~= 0 and characterInfo[section][bagIndex] then
        if #characterInfo[section][bagIndex] > 0 then
          inSlots[bagType] = {bagIndex}
        end
      else
        table.insert(mainBags, bagIndex)
      end
    end
  end

  local special = {}
  for key, bags in pairs(inSlots) do
    table.insert(special, {
      indexesUsed = bags,
      visual = addonTable.Constants.ContainerKeyToInfo[key],
      key = key,
    })
  end
  table.sort(special, function(a, b)
    return a.indexesUsed[1] < b.indexesUsed[1]
  end)

  return {
    main = mainBags,
    special = special,
  }
end

function addonTable.SingleViews.AllocateCollapsingSections(character, section, bagIDs, collapsingInfo, previousSections, sectionPool, itemButtonPool, refreshCallback)
  collapsingInfo.mainIndexesToUse = {}
  for _, index in ipairs(collapsingInfo.main) do
    collapsingInfo.mainIndexesToUse[index] = true
  end
  for _, layouts in ipairs(previousSections) do
    sectionPool:Release(layouts)
  end
  local CollapsingBags = {}

  for _, info in ipairs(collapsingInfo.special) do
    local layouts = sectionPool:Acquire()
    addonTable.SingleViews.SetupCollapsingBagSection(layouts, info, bagIDs)
    layouts.live:SetPool(itemButtonPool)
    layouts.button:Hide()
    addonTable.Skins.AddFrame("IconButton", layouts.button, {"collapsingBagSection"})

    layouts.button:SetScript("OnClick", function()
      local state = addonTable.Config.Get(addonTable.Config.Options.HIDE_SPECIAL_CONTAINER)
      state[info.key] = not state[info.key]
      addonTable.CallbackRegistry:TriggerEvent("SpecialBagToggled")
    end)

    table.insert(CollapsingBags, layouts)
  end
  return CollapsingBags
end

function addonTable.SingleViews.SetupCollapsingBagSection(layouts, info, bagIDs)
  if info.visual.type == "file" then
    layouts.button.Icon:SetSize(17, 17)
    layouts.button.Icon:SetTexture(info.visual.value)
  else
    local size = info.visual.size or 64
    layouts.button.Icon:SetSize(size/64 * 17, size/64 * 17)
    layouts.button.Icon:SetAtlas(info.visual.value)
  end
  layouts.key = info.key
  layouts.button.tooltipHeader = info.visual.tooltipHeader or ""

  layouts.indexesToUse = {}
  layouts.bagIDsToUse = {}
  for _, index in ipairs(info.indexesUsed) do
    layouts.indexesToUse[index] = true
    layouts.bagIDsToUse[bagIDs[index]] = true
  end
  layouts.button.bagIDsToUse = layouts.bagIDsToUse
end

function addonTable.SingleViews.ArrangeCollapsibles(activeCollapsibles, originBag, originCollapsibles)
  local topSpacing, dividerOffset, endPadding = 14, 2, 0
  if addonTable.Config.Get(addonTable.Config.Options.REDUCE_SPACING) then
    topSpacing = 7
    dividerOffset = 1
    endPadding = 3
  end

  local lastCollapsible
  local addedHeight = 0
  for index, layout in ipairs(activeCollapsibles) do
    local key = originCollapsibles[index].key
    local hidden = addonTable.Config.Get(addonTable.Config.Options.HIDE_SPECIAL_CONTAINER)[key]
    local divider = originCollapsibles[index].divider
    divider:SetShown(not hidden)
    layout:SetShown(not hidden)
    if not hidden then
      divider:SetPoint("BOTTOM", layout, "TOP", 0, topSpacing / 2 + dividerOffset)
      divider:SetPoint("LEFT", layout)
      divider:SetPoint("RIGHT", layout)
      divider:SetShown(layout:GetHeight() > 0)
      if layout:GetHeight() > 0 then
        addedHeight = addedHeight + layout:GetHeight() + topSpacing
        if lastCollapsible == nil then
          layout:SetPoint("TOP", originBag, "BOTTOM", 0, -topSpacing)
        else
          layout:SetPoint("TOP", lastCollapsible, "BOTTOM", 0, -topSpacing)
        end
        lastCollapsible = layout
      end
    end
  end
  return addedHeight + endPadding
end
