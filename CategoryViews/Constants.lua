local _, addonTable = ...
if not Syndicator then
  return
end

addonTable.CategoryViews.Constants = {
  ProtectedCategories = { "default_other", "default_special_empty" },
  EmptySlotsCategory = "default_special_empty",
  DividerName = "----",
  DividerLabel = "——————",
  SectionEnd = "__end",
  MinWidth = 400,

  GroupingState = {
    SplitStack = 1,
    NoGroupForced = 2,
  },

  RedisplaySettings = {
    addonTable.Config.Options.CATEGORY_HORIZONTAL_SPACING,
    addonTable.Config.Options.CATEGORY_DISPLAY_ORDER,
    addonTable.Config.Options.CUSTOM_CATEGORIES,
    addonTable.Config.Options.CATEGORY_HIDDEN,
    addonTable.Config.Options.CATEGORY_ITEM_GROUPING,
    addonTable.Config.Options.CATEGORY_SECTION_TOGGLED,
    addonTable.Config.Options.CUSTOM_CATEGORIES,
    addonTable.Config.Options.CATEGORY_MODIFICATIONS,
    addonTable.Config.Options.CATEGORY_GROUP_EMPTY_SLOTS,
  },

  ClearCachesSettings = {
    addonTable.Config.Options.CATEGORY_DISPLAY_ORDER,
    addonTable.Config.Options.CUSTOM_CATEGORIES,
    addonTable.Config.Options.CATEGORY_ITEM_GROUPING,
    addonTable.Config.Options.CATEGORY_MODIFICATIONS,
    addonTable.Config.Options.JUNK_PLUGIN,
    addonTable.Config.Options.UPGRADE_PLUGIN,
  },

  OldPriorities = {
    [220] = -1,
    [250] = 0,
    [300] = 1,
    [350] = 2,
    [400] = 3,
  }
}

-- The "priorityOffset" field is used to ensure the categories assign the right
-- items to the right default category when at the same relative priority in the
-- settings (as configured by a user).
--addonTable.Constants.DefaultCategories
if addonTable.Constants.IsEra then
  addonTable.CategoryViews.Constants.OldDefaults = {
    "default_hearthstone",
    "default_consumable",
    "default_reagent",
    "default_auto_equipment_sets",
    "default_weapon",
    "default_armor",
    "default_quiver",
    "default_container",
    "default_tradegoods",
    "default_recipe",
    "default_questitem",
    "default_key",
    "default_miscellaneous",
    "default_other",
    "default_junk",
    "default_special_empty",
  }
  addonTable.CategoryViews.Constants.DefaultCategories = {
    {
      key = "projectile",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Projectile),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Projectile):lower(),
    },
    {
      key = "quiver",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Quiver),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Quiver):lower(),
    },
    {
      key = "key",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Key),
      search = "#" .. (SYNDICATOR_L_KEYWORD_KEY or SYNDICATOR_L_KEYWORD_KEYRING),
      priorityOffset = -35,
    },
  }

elseif addonTable.Constants.IsClassic then -- Cata
  addonTable.CategoryViews.Constants.OldDefaults = {
    "default_hearthstone",
    "default_consumable",
    "default_reagent",
    "default_auto_equipment_sets",
    "default_weapon",
    "default_armor",
    "default_gem",
    "default_container",
    "default_tradegoods",
    "default_recipe",
    "default_questitem",
    "default_key",
    "default_miscellaneous",
    "default_battlepet",
    "default_other",
    "default_junk",
    "default_special_empty",
  }
  addonTable.CategoryViews.Constants.DefaultCategories = {
    {
      key = "gem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Gem),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Gem):lower(),
    },
    {
      key = "key",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Key),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Key):lower(),
      priorityOffset = -35,
    },
    {
      key = "battlepet",
      name = TOOLTIP_BATTLE_PET,
      search = "#" .. SYNDICATOR_L_KEYWORD_BATTLE_PET,
      priorityOffset = -60,
    },
  }
else -- retail
  addonTable.CategoryViews.Constants.OldDefaults = {
    "default_hearthstone",
    "default_potion",
    "default_food",
    "default_consumable",
    "default_reagent",
    "default_auto_equipment_sets",
    "default_weapon",
    "default_armor",
    "default_gem",
    "default_itemenhancement",
    "default_container",
    "default_tradegoods",
    "default_profession",
    "default_recipe",
    "default_questitem",
    "default_key",
    "default_miscellaneous",
    "default_battlepet",
    "default_toy",
    "default_other",
    "default_junk",
    "default_special_empty",
  }
  addonTable.CategoryViews.Constants.DefaultCategories = {
    {
      key = "keystone",
      name = BAGANATOR_L_CATEGORY_KEYSTONE,
      search = "#" .. SYNDICATOR_L_KEYWORD_KEYSTONE,
      priorityOffset = -40,
    },
    {
      key = "potion",
      name = BAGANATOR_L_CATEGORY_POTION,
      search = "#" .. SYNDICATOR_L_KEYWORD_POTION,
      priorityOffset = -40,
    },
    {
      key = "food",
      name = BAGANATOR_L_CATEGORY_FOOD,
      search = "#" .. SYNDICATOR_L_KEYWORD_FOOD,
      priorityOffset = -40,
    },
    {
      key = "consumable",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Consumable),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Consumable):lower(),
    },
    {
      key = "gem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Gem),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Gem):lower(),
    },
    {
      key = "itemenhancement",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.ItemEnhancement),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.ItemEnhancement):lower(),
    },
    {
      key = "profession",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Profession),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Profession):lower(),
    },
    {
      key = "key",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Key),
      search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Key):lower(),
      priorityOffset = -35,
    },
    {
      key = "battlepet",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Battlepet),
      search = "#" .. SYNDICATOR_L_KEYWORD_BATTLE_PET,
      priorityOffset = -60,
    },
    {
      key = "toy",
      name = TOY,
      search = "#" .. TOY:lower(),
      priorityOffset = -20,
    },
  }
end

tAppendAll(addonTable.CategoryViews.Constants.DefaultCategories, {
  {
    key = "hearthstone",
    name = BAGANATOR_L_CATEGORY_HEARTHSTONE,
    search = BAGANATOR_L_CATEGORY_HEARTHSTONE:lower(),
    priorityOffset = -10,
  },
  {
    key = "consumable",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Consumable),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Consumable):lower(),
  },
  {
    key = "reagent",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Reagent),
    search = "#" .. SYNDICATOR_L_KEYWORD_REAGENT,
    priorityOffset = -50,
  },
  {
    key = "auto_equipment_sets",
    name = BAGANATOR_L_CATEGORY_EQUIPMENT_SETS_AUTO,
    auto = "equipment_sets",
    priorityOffset = -10,
  },
  {
    key = "weapon",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Weapon),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Weapon):lower(),
  },
  {
    key = "armor",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Armor),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Armor):lower() .. "&#" .. SYNDICATOR_L_KEYWORD_GEAR,
  },
  {
    key = "container",
    name = BAGANATOR_L_CATEGORY_BAG,
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Container):lower(),
  },
  {
    key = "tradegoods",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods):lower(),
  },
  {
    key = "recipe",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Recipe),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Recipe):lower(),
  },
  {
    key = "questitem",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Questitem),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Questitem):lower(),
  },
  {
    key = "miscellaneous",
    name = C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous),
    search = "#" .. C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous):lower(),
  },
  {
    key = "other",
    name = BAGANATOR_L_CATEGORY_OTHER,
    search = "",
    priorityOffset = -90,
  },
  {
    key = "junk",
    name = BAGANATOR_L_CATEGORY_JUNK,
    search = "#" .. SYNDICATOR_L_KEYWORD_JUNK,
    priorityOffset = -15,
  },

  {
    key = "auto_inventory_slots",
    name = BAGANATOR_L_CATEGORY_INVENTORY_SLOTS_AUTO,
    auto = "inventory_slots",
    priorityOffset = -40,
  },
  {
    key = "auto_recents",
    name = BAGANATOR_L_CATEGORY_RECENT_AUTO,
    auto = "recents",
    priorityOffset = 600,
    doNotAdd = true,
  },
  {
    key = "special_empty",
    name = BAGANATOR_L_EMPTY,
    emptySlots = true,
    doNotAdd = true,
  },
})

addonTable.CategoryViews.Constants.SourceToCategory = {}
for index, category in ipairs(addonTable.CategoryViews.Constants.DefaultCategories) do
  category.source = "default_" .. category.key
  category.priorityOffset = category.priorityOffset or -70
  addonTable.CategoryViews.Constants.SourceToCategory[category.source] = category
end

if addonTable.Constants.IsEra then
  addonTable.CategoryViews.Constants.DefaultImportVersion = 2
  addonTable.CategoryViews.Constants.DefaultImport = {
    [[{"categories":[],"version":1,"order":["default_hearthstone","default_consumable","default_questitem","_EQUIPMENT","default_auto_equipment_sets","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_recipe","__end","default_projectile","default_container","default_quiver","default_key","default_miscellaneous","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
    [[{"categories":[],"version":1,"order":["default_auto_recents","default_hearthstone","default_consumable","default_questitem","_EQUIPMENT","default_auto_equipment_sets","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_recipe","__end","default_projectile","default_container","default_quiver","default_key","default_miscellaneous","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
  }
elseif addonTable.Constants.IsClassic then -- Cata
  addonTable.CategoryViews.Constants.DefaultImportVersion = 3
  addonTable.CategoryViews.Constants.DefaultImport = {
    [[{"categories":[],"version":1,"order":["_CRAFTING","__end","default_auto_recents","----","default_hearthstone","default_consumable","default_questitem","----","default_auto_equipment_sets","_EQUIPMENT","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_recipe","__end","default_gem","default_container","default_key","default_miscellaneous","default_battlepet","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
    [[{"categories":[],"version":1,"order":["default_auto_recents","----","default_hearthstone","default_consumable","default_questitem","----","default_auto_equipment_sets","_EQUIPMENT","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_recipe","__end","default_gem","default_container","default_key","default_miscellaneous","default_battlepet","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
    [[{"categories":[],"version":1,"order":["default_auto_recents","----","default_hearthstone","default_consumable","default_questitem","_EQUIPMENT","default_auto_equipment_sets","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_recipe","__end","default_gem","default_container","default_key","default_miscellaneous","default_battlepet","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
  }
elseif addonTable.Constants.IsRetail then
  addonTable.CategoryViews.Constants.DefaultImportVersion = 2
  addonTable.CategoryViews.Constants.DefaultImport = {
    [[{"categories":[],"version":1,"order":["default_auto_recents","----","default_hearthstone","default_potion","default_food","default_consumable","default_questitem","_EQUIPMENT","default_auto_equipment_sets","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_profession","default_recipe","__end","default_gem","default_itemenhancement","default_container","default_key","default_miscellaneous","default_battlepet","default_toy","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
    [[{"categories":[],"version":1,"order":["default_auto_recents","----","default_hearthstone","default_keystone","default_potion","default_food","default_consumable","default_questitem","_EQUIPMENT","default_auto_equipment_sets","default_weapon","default_armor","__end","_CRAFTING","default_reagent","default_tradegoods","default_profession","default_recipe","__end","default_gem","default_itemenhancement","default_container","default_key","default_miscellaneous","default_battlepet","default_toy","default_other","----","default_junk","default_special_empty"],"modifications":[],"hidden":[]}]],
  }
end

addonTable.Utilities.OnAddonLoaded("TradeSkillMaster", function()
  local spec = {
    source = "default_auto_tradeskillmaster",
    name = BAGANATOR_L_CATEGORY_TRADESKILLMASTER_AUTO,
    auto = "tradeskillmaster",
    priorityOffset = -15,
    doNotAdd = true,
  }
  table.insert(addonTable.CategoryViews.Constants.DefaultCategories, spec)
  addonTable.CategoryViews.Constants.SourceToCategory[spec.source] = spec
end)
