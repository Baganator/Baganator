---@class addonTableBaganator
local addonTable = select(2, ...)

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
      table.insert(searchLabels, addonTable.Locales.CATEGORY_EQUIPMENT_SET)
      table.insert(searches, "#" .. Syndicator.Locales.KEYWORD_EQUIPMENT_SET)
    else
      local groupedItems = {}
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
        local index = #searches + 1
        searches[index] = ""
        searchLabels[index] = n
        attachedItems[index] = groupedItems[n] -- nil if no items
      end
    end
  elseif category.auto == "inventory_slots" then
    for _, slot in ipairs(inventorySlots) do
      local name = _G[slot]
      if name then
        table.insert(searchLabels, name)
        table.insert(searches, "#" .. Syndicator.Locales.KEYWORD_GEAR .. "&#" .. name:lower())
      end
    end
  elseif category.auto == "recents" then
    table.insert(searches, "")
    table.insert(searchLabels, addonTable.Locales.CATEGORY_RECENT)
    local newItems = {}
    local newByKey = {}
    for _, item in ipairs(everything) do
      if newItems[item.key] ~= false and item.bagID ~= nil then
        newItems[item.key] = addonTable.NewItems:IsNewItemTimeout(item.bagID, item.slotID) == true
        if newItems[item.key] == false and newByKey[item.key] ~= nil then
          for _, prevItem in ipairs(newByKey[item.key]) do
            addonTable.NewItems:ClearNewItem(item.bagID, item.slotID)
            addonTable.NewItems:ClearNewItemTimeout(prevItem.bagID, prevItem.slotID)
          end
        else
          newByKey[item.key] = newByKey[item.key] or {}
          table.insert(newByKey[item.key], item)
        end
      elseif newItems[item.key] == false then
        addonTable.NewItems:ClearNewItem(item.bagID, item.slotID)
        addonTable.NewItems:ClearNewItemTimeout(item.bagID, item.slotID)
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
          if not groups[groupPath] then
            groups[groupPath] = {}
          end
          groups[groupPath][item.key] = addonTable.CategoryViews.Utilities.GetAddedItemData(item.itemID, item.itemLink)
        end
      end
    end
    local prevLevel = 1
    for _, groupPath in ipairs(TSM_API.GetGroupPaths({})) do
      local parts = {strsplit("`", groupPath)}
      if #parts > prevLevel then
        -- Previous entry will be root of group
        attachedItems[#searches + 1] = attachedItems[#searches]
        attachedItems[#searches] = nil
        table.insert(searches, #searches, "__start")
        searchLabels[#searches] = searchLabels[#searches - 1]
        searchLabels[#searches - 1] = parts[prevLevel]
      end
      while #parts < prevLevel do
        prevLevel = prevLevel - 1
        table.insert(searches, "__end")
      end
      local index = #searches + 1
      searches[index] = ""
      searchLabels[index] = parts[#parts]
      assert(searchLabels[index], #searches)
      attachedItems[index] = groups[groupPath] -- nil if no items
      prevLevel = #parts
    end
    while prevLevel > 1 do
      prevLevel = prevLevel - 1
      table.insert(searches, "__end")
    end
  else
    error("automatic category type not supported")
  end
  return {searches = searches, searchLabels = searchLabels, attachedItems = attachedItems}
end

-- Organise category data ready for display, including removing duplicate
-- searches with priority determining which gets kept.
function addonTable.CategoryViews.ComposeCategories(everything, location)
  local allDetails = {}

  local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
  local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
  local sections = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTIONS)
  local currentSection = {}
  for _, source in ipairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local section = CopyTable(currentSection)
    if source == addonTable.CategoryViews.Constants.DividerName then
      table.insert(allDetails, {
        type = "divider",
        section = section,
      })
    end
    if source == addonTable.CategoryViews.Constants.SectionEnd then
      table.remove(currentSection)
      table.remove(section)
      table.insert(allDetails, {
        type = "divider",
        section = section,
      })
    elseif source:sub(1, 1) == "_" then
      local sectionID = source:match("^_(.*)")
      table.insert(allDetails, {
        type = "divider",
        section = section,
      })
      local sectionDetails = sections[sectionID]
      local sectionName = sectionDetails.name
      local label = addonTable.Locales["SECTION_" .. sectionName] or sectionName
      table.insert(currentSection, sectionID)
      table.insert(allDetails, {
        type = "section",
        source = sectionID,
        label = label,
        section = section,
      })
    end

    local priority = categoryMods[source] and categoryMods[source].priority and (categoryMods[source].priority + 1) * 200 or 0

    local mods = categoryMods[source]
    local group, groupPrefix, attachedItems
    local shouldShow = true
    if mods then
      if mods.addedItems and next(mods.addedItems) then
        attachedItems = mods.addedItems
      end
      group = mods.group
      groupPrefix = mods.showGroupPrefix
      shouldShow = mods.hideIn == nil or not mods.hideIn[location]
    end

    local category = addonTable.CategoryViews.Constants.SourceToCategory[source]
    if category and shouldShow then
      if category.auto then
        local autoDetails = GetAuto(category, everything)
        local currentTree = {}
        for index = 1, #autoDetails.searches do
          section = CopyTable(currentSection)
          local search = autoDetails.searches[index]
          if search == "__start" or search == "__end" then
            if search == "__end" then
              table.remove(currentTree)
              table.remove(currentSection)
              table.remove(section)
              table.insert(allDetails, {
                type = "divider",
                section = section,
              })
            elseif search == "__start" then
              table.insert(allDetails, {
                type = "divider",
                section = section,
              })
              table.insert(currentTree, autoDetails.searchLabels[index])
              local sectionSource = source .. "$" .. table.concat(currentTree, "$")
              table.insert(currentSection, sectionSource)
              table.insert(allDetails, {
                type = "section",
                color = category.source,
                source = sectionSource,
                label = autoDetails.searchLabels[index],
                section = section,
              })
            end
          else
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
              color = category.source,
              auto = true,
              autoIndex = index,
              section = section,
            }
          end
        end
      elseif category.emptySlots then
        allDetails[#allDetails + 1] = {
          type = "category",
          source = source,
          index = #allDetails + 1,
          section = section,
          search = "________" .. (#allDetails + 1),
          priority = 0,
          auto = true,
          emptySlots = true,
          label = addonTable.Locales.EMPTY,
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
          section = section,
        }
      end
    end
    category = customCategories[source]
    if category and shouldShow then
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
        section = section,
      }
    end
  end

  local copy = tFilter(allDetails, function(a) return a.type == "category" end, true)
  table.sort(copy, function(a, b)
    if a.priority == b.priority then
      return a.index < b.index
    else
      return a.priority > b.priority
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
    start = 1,
    searches = {},
    section = {},
    categoryKeys = {},
    prioritisedSearches = prioritisedSearches,
  }

  for index, details in ipairs(allDetails) do
    if details.search then
      details.results = {}
    end
    details.next = index + 1
    details.index = nil
    details.priority = nil
    if details.type == "category" then
      table.insert(result.searches, details.search)
      table.insert(result.section, details.section)
      result.categoryKeys[details.search] = details.source
    end
  end
  if next(allDetails) then
    allDetails[#allDetails].next = nil
  end

  return result
end
