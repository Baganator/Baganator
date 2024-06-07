if not Syndicator then
  return
end

Baganator.CategoryViews.Constants = {
  ProtectedCategory = "default_other",
  DividerName = "----",
  DividerLabel = "——————",

  GroupingState = {
    SplitStack = 1,
    NoGroupForced = 2,
  },

  RedisplaySettings = {
    Baganator.Config.Options.CATEGORY_HORIZONTAL_SPACING,
    Baganator.Config.Options.CATEGORY_DISPLAY_ORDER,
    Baganator.Config.Options.CATEGORY_ITEM_GROUPING,
  },
}

local notJunk = "&~" .. SYNDICATOR_L_KEYWORD_JUNK
--Baganator.Constants.DefaultCategories
if Baganator.Constants.IsEra then
  Baganator.CategoryViews.Constants.DefaultCategories = {
    {
      key = "hearthstone",
      name = BAGANATOR_L_CATEGORY_HEARTHSTONE,
      search = BAGANATOR_L_CATEGORY_HEARTHSTONE:lower(),
      searchPriority = 200,
    },
    {
      key = "consumable",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Consumable),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Consumable):lower() .. "_",
    },
    {
      key = "reagent",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Reagent),
      search = "_" .. SYNDICATOR_L_KEYWORD_REAGENT .. "_",
      searchPriority = 100,
    },
    {
      key = "auto_equipment_sets",
      name = BAGANATOR_L_CATEGORY_EQUIPMENT_SETS_AUTO,
      auto = "equipment_sets",
      searchPriority = 200,
    },
    {
      key = "weapon",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Weapon),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Weapon):lower() .. "_",
    },
    {
      key = "armor",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Armor),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Armor):lower() .. "_&_" .. SYNDICATOR_L_KEYWORD_GEAR .. "_",
    },
    {
      key = "quiver",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Quiver),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Quiver) .. "_",
    },
    {
      key = "container",
      name = BAGANATOR_L_CATEGORY_BAG,
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Container):lower() .. "_",
    },
    {
      key = "tradegoods",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods):lower() .. "_",
    },
    {
      key = "recipe",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Recipe),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Recipe):lower() .. "_",
    },
    {
      key = "questitem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Questitem),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Questitem):lower() .. "_",
    },
    {
      key = "key",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Key),
      -- Only era uses the KEYRING keyword as only era has a keyring bag
      search = "_" .. SYNDICATOR_L_KEYWORD_KEYRING or C_Item.GetItemClassInfo(Enum.ItemClass.Key):lower() .. "_",
      searchPriority = 165,
    },
    {
      key = "miscellaneous",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous):lower() .. "_",
    },
    {
      key = "other",
      name = BAGANATOR_L_CATEGORY_OTHER,
      search = "",
      searchPriority = 0,
    },
    {
      key = "junk",
      name = BAGANATOR_L_CATEGORY_JUNK,
      search = "_" .. SYNDICATOR_L_KEYWORD_JUNK .. "_",
      searchPriority = 180,
    },
  }

elseif Baganator.Constants.IsClassic then -- Cata
  Baganator.CategoryViews.Constants.DefaultCategories = {
    {
      key = "hearthstone",
      name = BAGANATOR_L_CATEGORY_HEARTHSTONE,
      search = BAGANATOR_L_CATEGORY_HEARTHSTONE:lower(),
      searchPriority = 200,
    },
    {
      key = "consumable",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Consumable),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Consumable):lower() .. "_",
    },
    {
      key = "reagent",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Reagent),
      search = "_" .. SYNDICATOR_L_KEYWORD_REAGENT .. "_",
      searchPriority = 100,
    },
    {
      key = "auto_equipment_sets",
      name = BAGANATOR_L_CATEGORY_EQUIPMENT_SETS_AUTO,
      auto = "equipment_sets",
      searchPriority = 200,
    },
    {
      key = "weapon",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Weapon),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Weapon):lower() .. "_",
    },
    {
      key = "armor",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Armor),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Armor):lower() .. "_&_" .. SYNDICATOR_L_KEYWORD_GEAR .. "_",
    },
    {
      key = "gem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Gem),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Gem):lower() .. "_",
    },
    {
      key = "container",
      name = BAGANATOR_L_CATEGORY_BAG,
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Container):lower() .. "_",
    },
    {
      key = "tradegoods",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods):lower() .. "_",
    },
    {
      key = "recipe",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Recipe),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Recipe):lower() .. "_",
    },
    {
      key = "questitem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Questitem),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Questitem):lower() .. "_",
    },
    {
      key = "key",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Key),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Key):lower() .. "_",
      searchPriority = 165,
    },
    {
      key = "miscellaneous",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous):lower() .. "&~" .. SYNDICATOR_L_KEYWORD_BATTLE_PET .. "_",
    },
    {
      key = "battlepet",
      name = TOOLTIP_BATTLE_PET,
      search = "_" .. SYNDICATOR_L_KEYWORD_BATTLE_PET .. "_",
      searchPriority = 140,
    },
    {
      key = "other",
      name = BAGANATOR_L_CATEGORY_OTHER,
      search = "",
      searchPriority = 0,
    },
    {
      key = "junk",
      name = BAGANATOR_L_CATEGORY_JUNK,
      search = "_" .. SYNDICATOR_L_KEYWORD_JUNK .. "_",
      searchPriority = 180,
    },
  }
else -- retail
  Baganator.CategoryViews.Constants.DefaultCategories = {
    {
      key = "hearthstone",
      name = BAGANATOR_L_CATEGORY_HEARTHSTONE,
      search = BAGANATOR_L_CATEGORY_HEARTHSTONE:lower(),
      searchPriority = 200,
    },
    {
      key = "potion",
      name = BAGANATOR_L_CATEGORY_POTION,
      search = "_" .. SYNDICATOR_L_KEYWORD_POTION .. "_",
      searchPriority = 160,
    },
    {
      key = "food",
      name = BAGANATOR_L_CATEGORY_FOOD,
      search = "_" .. SYNDICATOR_L_KEYWORD_FOOD .. "_",
      searchPriority = 160,
    },
    {
      key = "consumable",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Consumable),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Consumable):lower() .. "_",
    },
    {
      key = "reagent",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Reagent),
      search = "_" .. SYNDICATOR_L_KEYWORD_REAGENT .. "_",
      searchPriority = 100,
    },
    {
      key = "auto_equipment_sets",
      name = BAGANATOR_L_CATEGORY_EQUIPMENT_SETS_AUTO,
      auto = "equipment_sets",
      searchPriority = 200,
    },
    {
      key = "weapon",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Weapon),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Weapon):lower() .. "_",
    },
    {
      key = "armor",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Armor),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Armor):lower() .. "_&_" .. SYNDICATOR_L_KEYWORD_GEAR .. "_",
    },
    {
      key = "gem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Gem),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Gem):lower() .. "_",
    },
    {
      key = "itemenhancement",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.ItemEnhancement),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.ItemEnhancement):lower() .. "_",
    },
    {
      key = "container",
      name = BAGANATOR_L_CATEGORY_BAG,
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Container):lower() .. "_",
    },
    {
      key = "tradegoods",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Tradegoods):lower() .. "_",
    },
    {
      key = "profession",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Profession),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Profession):lower() .. "_",
    },
    {
      key = "recipe",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Recipe),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Recipe):lower() .. "_",
    },
    {
      key = "questitem",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Questitem),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Questitem):lower() .. "_",
    },
    {
      key = "key",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Key),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Key):lower() .. "_",
      searchPriority = 165,
    },
    {
      key = "miscellaneous",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous),
      search = "_" .. C_Item.GetItemClassInfo(Enum.ItemClass.Miscellaneous):lower() .. "_",
    },
    {
      key = "battlepet",
      name = C_Item.GetItemClassInfo(Enum.ItemClass.Battlepet),
      search = "_" .. SYNDICATOR_L_KEYWORD_BATTLE_PET .. "_",
      searchPriority = 140,
    },
    {
      key = "toy",
      name = TOY,
      search = "_" .. TOY:lower() .. "_",
      searchPriority = 170,
    },
    {
      key = "other",
      name = BAGANATOR_L_CATEGORY_OTHER,
      search = "",
      searchPriority = 0,
    },
    {
      key = "junk",
      name = BAGANATOR_L_CATEGORY_JUNK,
      search = "_" .. SYNDICATOR_L_KEYWORD_JUNK .. "_",
      searchPriority = 180,
    },
  }
end

table.insert(Baganator.CategoryViews.Constants.DefaultCategories, {
  key = "auto_inventory_slots",
  name = BAGANATOR_L_CATEGORY_INVENTORY_SLOTS_AUTO,
  auto = "inventory_slots",
  searchPriority = 150,
  doNotAdd = true,
})

Baganator.CategoryViews.Constants.SourceToCategory = {}
for index, category in ipairs(Baganator.CategoryViews.Constants.DefaultCategories) do
  category.source = "default_" .. category.key
  category.searchPriority = category.searchPriority or 50
  Baganator.CategoryViews.Constants.SourceToCategory[category.source] = category
end
