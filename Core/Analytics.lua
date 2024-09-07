local _, addonTable = ...
-- This code will _ONLY_ do anything if analytics are manually enabled within
-- the Wago app.
--
-- If the user has enabled analytics we assume they are happy for this addon to
-- transmit them. All analytics collected are documented here.
function addonTable.Core.RunAnalytics()
  if not WagoAnalytics then
    return
  end
  local WagoAnalytics = WagoAnalytics:Register("kGr09M6y")
  addonTable.WagoAnalytics = WagoAnalytics

  WagoAnalytics:Switch("UsingSkin", false)
  WagoAnalytics:Switch("UsingCategories", addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_TYPE) == "category" or addonTable.Config.Get(addonTable.Config.Options.BANK_VIEW_TYPE) == "category")
  WagoAnalytics:Switch("DifferentViews", addonTable.Config.Get(addonTable.Config.Options.BAG_VIEW_TYPE) ~= addonTable.Config.Get(addonTable.Config.Options.BANK_VIEW_TYPE))

  WagoAnalytics:Switch("NoFrameBorders", addonTable.Config.Get(addonTable.Config.Options.NO_FRAME_BORDERS))

  WagoAnalytics:Switch("EmptySpaceAtTop", addonTable.Config.Get(addonTable.Config.Options.BAG_EMPTY_SPACE_AT_TOP))
  WagoAnalytics:Switch("FlashSimilarAlt", addonTable.Config.Get(addonTable.Config.Options.ICON_FLASH_SIMILAR_ALT))

  WagoAnalytics:Switch("HideBOEOnCommon", addonTable.Config.Get(addonTable.Config.Options.HIDE_BOE_ON_COMMON))

  WagoAnalytics:Switch("UsingJunkPlugin", addonTable.Config.Get(addonTable.Config.Options.JUNK_PLUGIN) ~= "poor_quality" and addonTable.Config.Get(addonTable.Config.Options.JUNK_PLUGIN) ~= "none")
  WagoAnalytics:Switch("UsingUpgradePlugin", addonTable.Config.Get(addonTable.Config.Options.UPGRADE_PLUGIN) ~= "none")
  WagoAnalytics:Switch("UsingGuildSort", addonTable.Config.Get(addonTable.Config.Options.GUILD_BANK_SORT_METHOD) ~= "unset")

  WagoAnalytics:Switch("RecentCharacterTabs", addonTable.Config.Get(addonTable.Config.Options.SHOW_RECENTS_TABS))
  WagoAnalytics:Switch("AutoSort", addonTable.Config.Get(addonTable.Config.Options.AUTO_SORT_ON_OPEN))

  WagoAnalytics:Switch("UsingMasque", (C_AddOns.IsAddOnLoaded("Masque")))

  local categoryCount = 0
  for _, category in pairs(addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)) do
    categoryCount = categoryCount + 1
  end

  local hiddenCount = 0
  for _, hidden in pairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_HIDDEN)) do
    if hidden then
      hiddenCount = hiddenCount + 1
    end
  end

  local groupByCount = 0
  for _, mods in pairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)) do
    if mods.group then
      groupByCount = groupByCount + 1
    end
  end

  local sectionCount = 0
  for _, source in pairs(addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    if source:match("^_.*") and source ~= "^__end" then
      sectionCount = sectionCount + 1
    end
  end

  WagoAnalytics:Switch("AnyCustomCategories", categoryCount > 0)
  WagoAnalytics:SetCounter("CustomCategories", categoryCount)
  WagoAnalytics:Switch("AnyHiddenCategories", hiddenCount > 0)
  WagoAnalytics:SetCounter("HiddenCategories", hiddenCount)
  WagoAnalytics:Switch("AnyGroupByCategories", groupByCount > 0)
  WagoAnalytics:SetCounter("GroupByCategories", groupByCount)
  WagoAnalytics:Switch("AnySections", sectionCount > 0)
  WagoAnalytics:SetCounter("Sections", sectionCount)

  local ignoreDefault = {
    [addonTable.Config.Options.SEEN_WELCOME] = true,
    [addonTable.Config.Options.CATEGORY_DISPLAY_ORDER] = true,
    [addonTable.Config.Options.CATEGORY_HIDDEN] = true,
    [addonTable.Config.Options.CATEGORY_MIGRATION] = true,
    [addonTable.Config.Options.CATEGORY_SECTION_TOGGLED] = true,
    [addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED] = true,
    [addonTable.Config.Options.CUSTOM_CATEGORIES] = true,
    [addonTable.Config.Options.CATEGORY_MODIFICATIONS] = true,
    [addonTable.Config.Options.AUTO_OPEN] = true,
    [addonTable.Config.Options.JUNK_PLUGINS_IGNORED] = true,
    [addonTable.Config.Options.UPGRADE_PLUGINS_IGNORED] = true,
  }

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    for option, value in pairs(addonTable.Config.Defaults) do
      if not ignoreDefault[option] then
        if type(value) == "table" then
          WagoAnalytics:Switch("NotDefault-" .. option, not tCompare(addonTable.Config.Get(option), value, 20))
        else
          WagoAnalytics:Switch("NotDefault-" .. option, addonTable.Config.Get(option) ~= value)
        end
      end
    end
  end)

  do
    local sortMethod = addonTable.Config.Get(addonTable.Config.SORT_METHOD)
    local possibleSortMethods = {
      "type",
      "quality",
      "item-level",
      "combine_stacks_only",
      "expansion",
      "blizzard",
      "SortBags",
      "tdPack2",
      "BankStack",
    }
    WagoAnalytics:SetCounter("SortMethod", tIndexOf(possibleSortMethods, sortMethod) or 0)
  end
end
