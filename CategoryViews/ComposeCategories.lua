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

local groupings = {}
do
  groupings["expansion"] = {
    {label = "Dragonflight", search = "#df"},
    {label = "Shadowlands", search = "#shadowlands"},
    {label = "Battle for Azeroth", search = "#bfa"},
    {label = "Cataclysm", search = "#cataclysm"},
    {label = "Legion", search = "#legion"},
    {label = "Warlords of Draenor", search = "#draenor"},
    {label = "Mists of Pandaria", search = "#mop"},
    {label = "Wrath of the Lich King", search = "#wrath"},
    {label = "The Burning Crusade", search = "#tbc"},
    {label = "Classic", search = "#classic"},
  }

  groupings["type"] = {}

  local subTypes = {
    -- Weapon
    2, 0, -- One-Handed Axes
    2, 4, -- One-Handed Maces
    2, 7, -- One-Handed Swords
    2, 9, -- Warglaives
    2, 15, -- Daggers
    2, 13, -- Fist Weapons
    2, 11, -- bear claws
    2, 12, -- cat claws
    2, 19, -- Wands
    2, 1, -- Two-Handed Axes
    2, 5, -- Two-Handed Maces
    2, 8, -- Two-Handed Swords
    2, 6, -- Polearms
    2, 10, -- Staves
    2, 2, -- Bows
    2, 18, -- Crossbows
    2, 3, -- Guns
    2, 16, -- Thrown
    2, 20, -- Fishing Poles

    -- Armor
    4, 1, -- Cloth
    4, 2, -- Leather
    4, 3, -- Mail
    4, 4, -- Plate
    4, 6, -- Shield
    4, 7, -- Libram
    4, 8, -- Idol
    4, 9, -- Totem
    4, 10, -- Sigil
    4, 11, -- Relic
    4, 5, -- Cosmetic
    4, 0, -- Generic

    -- Tradeskill
    7, 18, -- Optional Reagents
    7, 1, -- Parts
    7, 4, -- Jewelcrafting
    7, 7, -- Metal & Stone
    7, 6, -- Leather
    7, 5, -- Cloth
    7, 12, -- Enchanting
    7, 16, -- Inscription
    7, 10, -- Elemental
    7, 9, -- Herb
    7, 8, -- Cooking
    7, 11, -- Other

     -- Profession
    16, 7, -- Engineering
    16, 0, -- Blacksmithing
    16, 1, -- Leatherworking
    16, 6, -- Tailoring
    16, 8, -- Enchanting
    16, 11, -- Jewelcrafting
    16, 2, -- Alchemy
    16, 12, -- Inscription
    16, 5, -- Mining
    16, 10, -- Skinning
    16, 3, -- Herbalism
    16, 4, -- Cooking
    16, 9, -- Fishing
    16, 13, -- Archaeology

    -- Recipe
    9, 3, -- Engineering
    9, 4, -- Blacksmithing
    9, 1, -- Leatherworking
    9, 2, -- Tailoring
    9, 8, -- Enchanting
    9, 10, -- Jewelcrafting
    9, 6, -- Alchemy
    9, 11, -- Inscription
    9, 5, -- Cooking
    9, 8, -- Fishing
    9, 7, -- First Aid
    9, 0, -- Book

    -- Battle Pets
    17, 0, -- Humanoid
    17, 1, -- Dragonkin
    17, 2, -- Flying
    17, 3, -- Undead
    17, 4, -- Critter
    17, 5, -- Magic
    17, 6, -- Elemental
    17, 7, -- Beast
    17, 8, -- Aquatic
    17, 9, -- Mechanical
  }
  for i = 1, #subTypes, 2 do
    local root = C_Item.GetItemClassInfo(subTypes[i])
    local child = C_Item.GetItemSubClassInfo(subTypes[i], subTypes[i+1])
    if root and child then
      local search = "#" .. root:lower() .. "&"
      if child:find("%&") then
        search = search .. "_" .. (strsplit("&", child)):lower()
      else
        search = search .. "#" .. child:lower()
      end
      table.insert(groupings["type"], {label = child, search = search})
    end
  end

  local qualities = {}
  for key, quality in pairs(Enum.ItemQuality) do
    local term = _G["ITEM_QUALITY" .. quality .. "_DESC"]
    if term then
      table.insert(qualities, {label = term, search = "#" .. term:lower(), index = quality})
    end
  end
  table.sort(qualities, function(a, b) return a.index > b.index end)
  groupings["quality"] = qualities

  local inventorySlotsForGroupings = {}
  for _, slot in ipairs(inventorySlots) do
    local name = _G[slot]
    if name then
      table.insert(inventorySlotsForGroupings, {label = name, search = "#" .. name:lower()})
    end
  end
  groupings["slot"] = inventorySlotsForGroupings
end

-- Generate automatic categories
local function GetAuto(category, everything)
  local searches, searchLabels, attachedItems = {}, {}, {}
  if category.auto == "equipment_sets" then
    local names = Baganator.ItemViewCommon.GetEquipmentSetNames()
    if #names == 0 then
      table.insert(searchLabels, BAGANATOR_L_CATEGORY_EQUIPMENT_SET)
      table.insert(searches, SYNDICATOR_L_KEYWORD_EQUIPMENT_SET)
    else
      for _, name in ipairs(names) do
        table.insert(searchLabels, name)
        table.insert(searches, SYNDICATOR_L_KEYWORD_EQUIPMENT_SET .. "&" .. name:lower())
      end
    end
  elseif category.auto == "inventory_slots" then
    for _, slot in ipairs(inventorySlots) do
      local name = _G[slot]
      if name then
        table.insert(searchLabels, name)
        table.insert(searches, SYNDICATOR_L_KEYWORD_GEAR .. "&" .. name:lower())
      end
    end
  elseif category.auto == "recents" then
    table.insert(searches, "")
    table.insert(searchLabels, BAGANATOR_L_CATEGORY_RECENT)
    local newItems = {}
    for _, item in ipairs(everything) do
      if Baganator.NewItems:IsNewItemTimeout(item.bagID, item.slotID) then
        newItems[item.key] = true
      end
    end
    attachedItems[1] = newItems
  else
    error("automatic category type not supported")
  end
  return {searches = searches, searchLabels = searchLabels, attachedItems = attachedItems}
end

-- Organise category data ready for display, including removing duplicate
-- searches with priority determining which gets kept.
function Baganator.CategoryViews.ComposeCategories(everything)
  local allDetails = {}

  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  local sectionToggled = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_SECTION_TOGGLED)
  local categoryMods = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_MODIFICATIONS)
  local categoryKeys = {}
  local emptySlots = {index = -1, section = ""}
  local currentSection = ""
  local prevSection = ""
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local section = source:match("^_(.*)")
    if source == Baganator.CategoryViews.Constants.DividerName and not sectionToggled[currentSection] then
      table.insert(allDetails, {
        type = "divider",
      })
    end
    if source == Baganator.CategoryViews.Constants.SectionEnd then
      table.insert(allDetails, {
        type = "divider",
      })
      prevSection = currentSection
      currentSection = ""
    elseif section then
      table.insert(allDetails, {
        type = "divider",
      })
      table.insert(allDetails, {
        type = "section",
        label = section,
      })
      currentSection = section
    end

    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
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
            priority = category.searchPriority,
            index = #allDetails + 1,
            attachedItems = autoDetails.attachedItems[index],
            auto = true,
            section = currentSection,
          }
        end
      elseif category.emptySlots then
        allDetails[#allDetails + 1] = {
          type = "empty slots category",
          index = #allDetails + 1,
          section = currentSection,
        }
      else
        allDetails[#allDetails + 1] = {
          type = "category",
          source = source,
          search = category.search,
          label = category.name,
          priority = category.searchPriority,
          index = #allDetails + 1,
          attachedItems = nil,
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
        priority = category.searchPriority,
        index = #allDetails + 1,
        attachedItems = nil,
        section = currentSection,
      }
    end

    local mods = categoryMods[source]
    if mods then
      if mods.addedItems and next(mods.addedItems) then
        local attachedItems = {}
        for _, details in ipairs(mods.addedItems) do
          if details.itemID then
            attachedItems["i:" .. details.itemID] = true
          elseif details.petID then
            attachedItems["p:" .. details.petID] = true
          end
        end
        allDetails[#allDetails].attachedItems = attachedItems
      end
      local searchDetails = groupings[mods.group]
      if searchDetails then
        local mainSearch = allDetails[#allDetails].search
        local mainLabel = allDetails[#allDetails].label
        local mainPriority = allDetails[#allDetails].priority
        for _, details in ipairs(searchDetails) do
          allDetails[#allDetails + 1] = {
            type = "category",
            source = source,
            search = details.search .. "&(" .. mainSearch .. ")",
            label = mainLabel .. ": " .. details.label,
            priority = mainPriority + 1,
            auto = true,
            index = #allDetails + 1,
            attachedItems = nil,
            section = currentSection,
          }
        end
      end
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
    autoSearches = {},
    attachedItems = {},
    categoryKeys = {},
    prioritisedSearches = prioritisedSearches,
  }

  for _, details in ipairs(allDetails) do
    if details.type == "category" then
      table.insert(result.searches, details.search)
      table.insert(result.section, details.section)
      result.autoSearches[details.search] = details.auto
      result.attachedItems[details.search] = details.attachedItems
      result.categoryKeys[details.search] = details.source
    end
  end

  return result
end
