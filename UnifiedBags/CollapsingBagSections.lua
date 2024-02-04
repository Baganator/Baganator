local ContainerTypeToIcon = {
  [0] = nil, -- regular bag
  [1] = {type = "file", value="interface\\icons\\inv_spiritshard_01", tooltipHeader=BAGANATOR_L_SOUL}, -- soulbag
  [2] = {type = "file", value="interface\\icons\\inv_misc_bag_cenarionherbbag", tooltipHeader=BAGANATOR_L_HERBALISM}, --herb
  [3] = {type = "file", value="interface\\icons\\inv_enchant_disenchant", tooltipHeader=BAGANATOR_L_ENCHANTING}, --enchant
  [4] = {type = "file", value="interface\\icons\\trade_engineering", tooltipHeader=BAGANATOR_L_ENGINEERING}, --engineering
  [5] = {type = "file", value="interface\\icons\\inv_misc_gem_ruby_02", tooltipHeader=BAGANATOR_L_GEMS}, -- gem
  [6] = {type = "file", value="interface\\icons\\trade_mining", tooltipHeader=BAGANATOR_L_MINING}, -- mining
  [7] = {type = "file", value="interface\\icons\\trade_leatherworking", tooltipHeader=BAGANATOR_L_LEATHERWORKING}, -- leatherworking
  [8] = {type = "file", value="interface\\icons\\inv_inscription_parchment", tooltipHeader=BAGANATOR_L_INSCRIPTION}, -- inscription
  [9] = {type = "file", value="interface\\icons\\trade_fishing", tooltipHeader=BAGANATOR_L_FISHING}, -- fishing
  [10] = {type = "file", value="interface\\icons\\inv_misc_food_150_cookie", tooltipHeader=BAGANATOR_L_COOKING}, -- cooking
}

local keyedTextures = {
  quiver = {type = "file", value="interface\\addons\\baganator\\assets\\ability_hunter_wildquiver", tooltipHeader=AMMOSLOT},
  reagentBag = {type = "atlas", value="Professions_Tracking_Herb", tooltipHeader = BAGANATOR_L_REAGENTS},
  keyring = {type = "file", value="interface\\addons\\baganator\\assets\\spell_nature_moonkey", tooltipHeader = BAGANATOR_L_KEYS},
}
for subClassType, textureDetails in pairs(ContainerTypeToIcon) do
  keyedTextures[subClassType] = textureDetails
end

function Baganator.UnifiedBags.GetCollapsingBagDetails(character, section, indexes, slotsCount)
  local characterInfo = BAGANATOR_DATA.Characters[character]
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
      local classID, subClassID = select(6, GetItemInfoInstant(containerInfo[index].itemID))
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

function Baganator.UnifiedBags.AllocateCollapsingSections(character, section, bagIDs, collapsingInfo, previousSections, sectionPool, itemButtonPool, refreshCallback)
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
    Baganator.UnifiedBags.SetupCollapsingBagSection(layouts, info, bagIDs)
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

function Baganator.UnifiedBags.SetupCollapsingBagSection(layouts, info, bagIDs)
  if info.visual.type == "file" then
    layouts.button.icon:SetTexture(info.visual.value)
  else
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
