local ContainerTypeToIcon = {
  [0] = nil, -- regular bag
  [1] = {type = "file", value="interface\\addons\\baganator\\assets\\bag_soul_shard", tooltipHeader=BAGANATOR_L_SOUL}, -- soulbag
  [2] = {type = "atlas", value="worldquest-icon-herbalism", tooltipHeader=BAGANATOR_L_HERBALISM, size=50}, --herb
  [3] = {type = "atlas", value="worldquest-icon-enchanting", tooltipHeader=BAGANATOR_L_ENCHANTING, size=50}, --enchant
  [4] = {type = "atlas", value="worldquest-icon-engineering", tooltipHeader=BAGANATOR_L_ENGINEERING, size=50}, --engineering
  [5] = {type = "atlas", value="worldquest-icon-jewelcrafting", tooltipHeader=BAGANATOR_L_GEMS, size=50}, -- gem
  [6] = {type = "atlas", value="worldquest-icon-mining", tooltipHeader=BAGANATOR_L_MINING, size=50}, -- mining
  [7] = {type = "atlas", value="worldquest-icon-leatherworking", tooltipHeader=BAGANATOR_L_LEATHERWORKING, size=50}, -- leatherworking
  [8] = {type = "atlas", value="worldquest-icon-inscription", tooltipHeader=BAGANATOR_L_INSCRIPTION, size=50}, -- inscription
  [9] = {type = "atlas", value="worldquest-icon-fishing", tooltipHeader=BAGANATOR_L_FISHING, size=50}, -- fishing
  [10] = {type = "atlas", value="worldquest-icon-cooking", tooltipHeader=BAGANATOR_L_COOKING, size=60}, -- cooking
}

local keyedTextures = {
  quiver = {type = "atlas", value="Ammunition", tooltipHeader=AMMOSLOT},
  reagentBag = {type = "atlas", value="Professions_Tracking_Herb", tooltipHeader = BAGANATOR_L_REAGENTS},
  keyring = {type = "file", value="interface\\addons\\baganator\\assets\\bag_keys", tooltipHeader = BAGANATOR_L_KEYS},
}
for subClassType, textureDetails in pairs(ContainerTypeToIcon) do
  keyedTextures[subClassType] = textureDetails
end

function Baganator.UnifiedViews.GetCollapsingBagDetails(character, section, indexes, slotsCount)
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
      local classID, subClassID = select(6, C_Item.GetItemInfoInstant(containerInfo[index].itemID))
      local icon = ContainerTypeToIcon[subClassID]
      local bagIndex = index + 1
      if classID == Enum.ItemClass.Quiver then
        seenIndexes[bagIndex] = true
        inSlots["quiver"] = {bagIndex}
      elseif icon then
        seenIndexes[bagIndex] = true
        local key = subClassID
        inSlots[key] = inSlots[key] or {}
        table.insert(inSlots[key], bagIndex)
      end
    end
  end

  for bagIndex, bagID in ipairs(indexes) do
    if not seenIndexes[bagIndex] then
      seenIndexes[bagIndex] = true
      if Baganator.Constants.IsRetail and bagID == Enum.BagIndex.ReagentBag then
        inSlots["reagentBag"] = {bagIndex}
      elseif Baganator.Constants.IsRetail and bagID == Enum.BagIndex.Reagentbank then
        if #characterInfo.bank[bagIndex] > 0 then
          inSlots["reagentBag"] = {bagIndex}
        end
      elseif bagID == Enum.BagIndex.Keyring then
        inSlots["keyring"] = {bagIndex}
      else
        table.insert(mainBags, bagIndex)
      end
    end
  end

  local special = {}
  for key, bags in pairs(inSlots) do
    table.insert(special, {
      indexesUsed = bags,
      visual = keyedTextures[key],
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

function Baganator.UnifiedViews.AllocateCollapsingSections(character, section, bagIDs, collapsingInfo, previousSections, sectionPool, itemButtonPool, refreshCallback)
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
    Baganator.UnifiedViews.SetupCollapsingBagSection(layouts, info, bagIDs)
    layouts.live:SetPool(itemButtonPool)
    layouts.button:Hide()

    layouts.button:SetScript("OnClick", function()
      local state = Baganator.Config.Get(Baganator.Config.Options.HIDE_SPECIAL_CONTAINER)
      state[info.key] = not state[info.key]
      Baganator.CallbackRegistry:TriggerEvent("SpecialBagToggled")
    end)

    table.insert(CollapsingBags, layouts)
  end
  return CollapsingBags
end

function Baganator.UnifiedViews.SetupCollapsingBagSection(layouts, info, bagIDs)
  if info.visual.type == "file" then
    layouts.button.icon:SetSize(17, 17)
    layouts.button.icon:SetTexture(info.visual.value)
  else
    local size = info.visual.size or 64
    layouts.button.icon:SetSize(size/64 * 17, size/64 * 17)
    layouts.button.icon:SetAtlas(info.visual.value)
  end
  layouts.key = info.key
  layouts.button.tooltipHeader = info.visual.tooltipHeader or ""

  layouts.indexesToUse = {}
  layouts.bagIDsToUse = {}
  for _, index in ipairs(info.indexesUsed) do
    layouts.indexesToUse[index] = true
    layouts.bagIDsToUse[bagIDs[index]] = true
  end
  layouts.button:SetScript("OnEnter", function(self)
    Baganator.CallbackRegistry:TriggerEvent("HighlightBagItems", layouts.bagIDsToUse)

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tooltipHeader)
    if self.tooltipText then
      GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  layouts.button:SetScript("OnLeave", function(self)
    Baganator.CallbackRegistry:TriggerEvent("ClearHighlightBag")

    GameTooltip:Hide()
  end)
end

function Baganator.UnifiedViews.ArrangeCollapsibles(activeCollapsibles, originBag, originCollapsibles)
  local topSpacing, dividerOffset, endPadding = 14, 2, 0
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    topSpacing = 7
    dividerOffset = 1
    endPadding = 3
  end

  local lastCollapsible
  local addedHeight = 0
  for index, layout in ipairs(activeCollapsibles) do
    local key = originCollapsibles[index].key
    local hidden = Baganator.Config.Get(Baganator.Config.Options.HIDE_SPECIAL_CONTAINER)[key]
    local divider = originCollapsibles[index].divider
    if hidden then
      divider:Hide()
      layout:Hide()
    else
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
