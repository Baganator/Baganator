local _, addonTable = ...

local inventorySlots = {
  "INVTYPE_2HWEAPON",
  "INVTYPE_WEAPON",
  "INVTYPE_WEAPONMAINHAND",
  "INVTYPE_WEAPONOFFHAND",
  "INVTYPE_SHIELD",
  "INVTYPE_HOLDABLE",
  "INVTYPE_RANGED",
  "INVTYPE_RANGEDRIGHT",
  "INVTYPE_THROWN",
  "INVTYPE_AMMO",
  "INVTYPE_QUIVER",
  "INVTYPE_RELIC",
  "INVTYPE_HEAD",
  "INVTYPE_SHOULDER",
  "INVTYPE_CLOAK",
  "INVTYPE_CHEST",
  "INVTYPE_ROBE",
  "INVTYPE_WRIST",
  "INVTYPE_HAND",
  "INVTYPE_WAIST",
  "INVTYPE_LEGS",
  "INVTYPE_FEET",
  "INVTYPE_NECK",
  "INVTYPE_FINGER",
  "INVTYPE_TRINKET",
  "INVTYPE_BODY",
  "INVTYPE_TABARD",
  "INVTYPE_PROFESSION_TOOL",
  "INVTYPE_PROFESSION_GEAR",
  "INVTYPE_BAG",
}

-- Generate automatic categories
local function GetAuto(category, everything)
  local searches, searchLabels, attachedItems = {}, {}, {}
  if category.auto == "equipment_sets" then
    local names = addonTable.ItemViewCommon.GetEquipmentSetNames()
    if #names == 0 then
      table.insert(searchLabels, BAGANATOR_L_CATEGORY_EQUIPMENT_SET)
      table.insert(searches, "#" .. SYNDICATOR_L_KEYWORD_EQUIPMENT_SET)
    else
      local groupedItems = {}
      local merged = {}
      for i = 1, #everything do
        local item = everything[i]
        if item.setInfo ~= nil then
          local key = item.setInfo[1].name
          if not groupedItems[key] then
            groupedItems[key] = {}
          end
          groupedItems[key][item.key] = true
        end
      end
      for _, n in ipairs(names) do
        if groupedItems[n] ~= nil then
          local index = #searches + 1
          searches[index] = ""
          searchLabels[index] = n
          attachedItems[index] = groupedItems[n]
        end
      end
    end
  elseif category.auto == "inventory_slots" then
    for _, slot in ipairs(inventorySlots) do
      local name = _G[slot]
      if name then
        table.insert(searchLabels, name)
        table.insert(searches, "#" .. SYNDICATOR_L_KEYWORD_GEAR .. "&#" .. name:lower())
      end
    end
  elseif category.auto == "recents" then
    table.insert(searches, "")
    table.insert(searchLabels, BAGANATOR_L_CATEGORY_RECENT)
    local newItems = {}
    for _, item in ipairs(everything) do
      if newItems[item.key] ~= false and item.bagID ~= nil then
        newItems[item.key] = addonTable.NewItems:IsNewItemTimeout(item.bagID, item.slotID)
      end
    end
    attachedItems[1] = newItems
  elseif category.auto == "tradeskillmaster" then
    local groups = {}
    for _, item in ipairs(everything) do
      local itemString = TSM_API.ToItemString(item.itemLink)
      if itemString then
        local groupPath = TSM_API.GetGroupPathByItem(itemString)
        if groupPath then
          if groupPath:find("`") then
            groupPath = groupPath:match("`([^`]*)$")
          end
          if not groups[groupPath] then
            groups[groupPath] = {}
          end
          groups[groupPath][item.key] = true
        end
      end
    end
    for _, groupPath in ipairs(TSM_API.GetGroupPaths({})) do
      if groupPath:find("`") then
        groupPath = groupPath:match("`([^`]*)$")
      end
      if groups[groupPath] then
        table.insert(searches, "")
        table.insert(searchLabels, groupPath)
        table.insert(attachedItems, groups[groupPath])
      end
    end
  else
    error("automatic category type not supported")
  end
  return {searches = searches, searchLabels = searchLabels, attachedItems = attachedItems}
end

-- Organise category data ready for display, including removing duplicate
-- searches with priority determining which gets kept.
function addonTable.CategoryViews.ComposeCategories(everything)
  local allDetails = {}

  local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
  local sectionToggled = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)
  local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
  local categoryKeys = {}
  local emptySlots = {index = -1, section = ""}
  local currentSection = ""
  local prevSection = ""
  for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local section = source:match("^_(.*)")
    if source == addonTable.CategoryViews.Constants.DividerName and not sectionToggled[currentSection] then
      table.insert(allDetails, {
        type = "divider",
      })
    end
    if source == addonTable.CategoryViews.Constants.SectionEnd then
      table.insert(allDetails, {
        type = "divider",
      })
      prevSection = currentSection
      currentSection = ""
    elseif section then
      table.insert(allDetails, {
        type = "divider",
      })
      currentSection = _G["BAGANATOR_L_SECTION_" .. section] or section
      table.insert(allDetails, {
        type = "section",
        label = currentSection,
      })
    end

    local priority = categoryMods[source] and categoryMods[source].priority and (categoryMods[source].priority + 1) * 200 or 0

    local mods = categoryMods[source]
    local group, groupPrefix, attachedItems
    if mods then
      if mods.addedItems and next(mods.addedItems) then
        attachedItems = mods.addedItems
      end
      group = mods.group
      groupPrefix = mods.showGroupPrefix
    end

    local category = addonTable.CategoryViews.Constants.SourceToCategory[source]
    if category then
      if category.auto then
        local autoDetails = GetAuto(category, everything)
        for index = 1, #autoDetails.searches do
          local search = autoDetails.searches[index]
          if search == "" then
            search = "________" .. (#allDetails + 1)
          end
          allDetails[#allDetails + 1] = {
            type = "category",
            source = source,
            search = search,
            label = autoDetails.searchLabels[index],
            priority = category.priorityOffset + priority,
            index = #allDetails + 1,
            attachedItems = autoDetails.attachedItems[index],
            group = group,
            groupPrefix = groupPrefix,
            auto = true,
            section = currentSection,
          }
        end
      elseif category.emptySlots then
        allDetails[#allDetails + 1] = {
          type = "category",
          source = source,
          index = #allDetails + 1,
          section = currentSection,
          search = "________" .. (#allDetails + 1),
          priority = 0,
          auto = true,
          emptySlots = true,
          label = BAGANATOR_L_EMPTY,
        }
      else
        allDetails[#allDetails + 1] = {
          type = "category",
          source = source,
          search = category.search,
          label = category.name,
          priority = category.priorityOffset + priority,
          index = #allDetails + 1,
          attachedItems = attachedItems,
          group = group,
          groupPrefix = groupPrefix,
          section = currentSection,
        }
      end
    end
    category = customCategories[source]
    if category then
      local search = category.search:lower()
      if search == "" then
        search = "________" .. (#allDetails + 1)
      end

      allDetails[#allDetails + 1] = {
        type = "category",
        source = source,
        search = search,
        label = category.name,
        priority = priority,
        index = #allDetails + 1,
        attachedItems = attachedItems,
        group = group,
        groupPrefix = groupPrefix,
        section = currentSection,
      }
    end
  end

  local copy = tFilter(allDetails, function(a) return a.type == "category" end, true)
  table.sort(copy, function(a, b)
    if a.priority == b.priority then
      return a.index < b.index
    else
      return a.priority > b. priority
    end
  end)

  local seenSearches = {}
  local prioritisedSearches = {}
  for _, details in ipairs(copy) do
    if seenSearches[details.search] then
      details.search = "________" .. details.index
    end
    prioritisedSearches[#prioritisedSearches + 1] = details.search
    seenSearches[details.search] = true
  end

  local result = {
    details = allDetails,
    searches = {},
    section = {},
    categoryKeys = {},
    prioritisedSearches = prioritisedSearches,
  }

  for index, details in ipairs(allDetails) do
    if details.search then
      details.results = {}
    end
    details.index = nil
    details.priority = nil
    if details.type == "category" then
      table.insert(result.searches, details.search)
      table.insert(result.section, details.section)
      result.categoryKeys[details.search] = details.source
    end
  end

  return result
end
