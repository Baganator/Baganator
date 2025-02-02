local _, addonTable = ...
addonTable.SlashCmd = {}

function addonTable.SlashCmd.Initialize()
  SlashCmdList["Baganator"] = addonTable.SlashCmd.Handler
  SLASH_Baganator1 = "/baganator"
  SLASH_Baganator2 = "/bgr"
end

local INVALID_OPTION_VALUE = "Wrong config value type %s (required %s)"
function addonTable.SlashCmd.Config(optionName, value1, ...)
  if optionName == nil then
    addonTable.Utilities.Message("No config option name supplied")
    for _, name in pairs(addonTable.Config.Options) do
      addonTable.Utilities.Message(name .. ": " .. tostring(addonTable.Config.Get(name)))
    end
    return
  end

  local currentValue = addonTable.Config.Get(optionName)
  if currentValue == nil then
    addonTable.Utilities.Message("Unknown config: " .. optionName)
    return
  end

  if value1 == nil then
    addonTable.Utilities.Message("Config " .. optionName .. ": " .. tostring(currentValue))
    return
  end

  if type(currentValue) == "boolean" then
    if value1 ~= "true" and value1 ~= "false" then
      addonTable.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    addonTable.Config.Set(optionName, value1 == "true")
  elseif type(currentValue) == "number" then
    if tonumber(value1) == nil then
      addonTable.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    addonTable.Config.Set(optionName, tonumber(value1))
  elseif type(currentValue) == "string" then
    addonTable.Config.Set(optionName, strjoin(" ", value1, ...))
  else
    addonTable.Utilities.Message("Unable to edit option type " .. type(currentValue))
    return
  end
  addonTable.Utilities.Message("Now set " .. optionName .. ": " .. tostring(addonTable.Config.Get(optionName)))
end

function addonTable.SlashCmd.Reset()
  BAGANATOR_CONFIG = nil
  ReloadUI()
end

function addonTable.SlashCmd.ResetCategories()
  addonTable.Config.ResetOne(addonTable.Config.Options.CUSTOM_CATEGORIES)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_SECTIONS)
  addonTable.Config.ResetOne(addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_HIDDEN)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_GROUP_EMPTY_SLOTS)
  addonTable.Config.ResetOne(addonTable.Config.Options.RECENT_TIMEOUT)
  addonTable.Config.ResetOne(addonTable.Config.Options.CATEGORY_DEFAULT_IMPORT)
  ReloadUI()
end

function addonTable.SlashCmd.RemoveUnusedCategories()
  local customCategories = addonTable.Config.Get(addonTable.Config.Options.CUSTOM_CATEGORIES)
  local displayOrder = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_DISPLAY_ORDER)
  for name in pairs(customCategories) do
    if tIndexOf(displayOrder, name) == nil then
      customCategories[name] = nil
    end
  end
  local categoryMods = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_MODIFICATIONS)
  for name in pairs(categoryMods) do
    if tIndexOf(displayOrder, name) == nil then
      categoryMods[name] = nil
    end
  end
  addonTable.Config.Set(addonTable.Config.Options.CUSTOM_CATEGORIES, CopyTable(customCategories))
  addonTable.Config.Set(addonTable.Config.Options.CATEGORY_MODIFICATIONS, CopyTable(categoryMods))
  addonTable.Utilities.Message(BAGANATOR_L_REMOVED_UNUSED_CATEGORIES)
end

function addonTable.SlashCmd.Search(text)
  addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", text)
  addonTable.CallbackRegistry:TriggerEvent("BagShow")
end

function addonTable.SlashCmd.Keywords()
  addonTable.Config.Set(addonTable.Config.Options.DEBUG_KEYWORDS, not addonTable.Config.Get(addonTable.Config.Options.DEBUG_KEYWORDS))
  addonTable.Utilities.Message(BAGANATOR_L_KEYWORDS_IN_TOOLTIPS_X:format(addonTable.Config.Get(addonTable.Config.Options.DEBUG_KEYWORDS) and BAGANATOR_L_ENABLED or BAGANATOR_L_DISABLED))
end

function addonTable.SlashCmd.Categories()
  addonTable.Config.Set(addonTable.Config.Options.DEBUG_CATEGORIES, not addonTable.Config.Get(addonTable.Config.Options.DEBUG_CATEGORIES))
  addonTable.Utilities.Message(BAGANATOR_L_CATEGORIES_IN_TOOLTIPS_X:format(addonTable.Config.Get(addonTable.Config.Options.DEBUG_CATEGORIES) and BAGANATOR_L_ENABLED or BAGANATOR_L_DISABLED))
end

function addonTable.SlashCmd.CustomiseUI()
  addonTable.CallbackRegistry:TriggerEvent("ShowCustomise")
end

function addonTable.SlashCmd.Timers()
  addonTable.Config.Set(addonTable.Config.Options.DEBUG_TIMERS, not addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS))
end

local COMMANDS = {
  ["c"] = addonTable.SlashCmd.Config,
  ["config"] = addonTable.SlashCmd.Config,
  ["timers"] = addonTable.SlashCmd.Timers,
  ["reset"] = addonTable.SlashCmd.Reset,
  [BAGANATOR_L_SLASH_RESET] = addonTable.SlashCmd.Reset,
  ["resetcategories"] = addonTable.SlashCmd.ResetCategories,
  [BAGANATOR_L_SLASH_RESETCATEGORIES] = addonTable.SlashCmd.ResetCategories,
  ["removeunusedcategories"] = addonTable.SlashCmd.RemoveUnusedCategories,
  [BAGANATOR_L_SLASH_REMOVEUNUSEDCATEGORIES] = addonTable.SlashCmd.RemoveUnusedCategories,
  [""] = addonTable.SlashCmd.CustomiseUI,
  ["search"] = addonTable.SlashCmd.Search,
  [BAGANATOR_L_SLASH_SEARCH] = addonTable.SlashCmd.Search,
  ["keywords"] = addonTable.SlashCmd.Keywords,
  [BAGANATOR_L_SLASH_KEYWORDS] = addonTable.SlashCmd.Keywords,
  ["categories"] = addonTable.SlashCmd.Categories,
  [BAGANATOR_L_SLASH_CATEGORIES] = addonTable.SlashCmd.Categories,
}
local HELP = {
  {"", BAGANATOR_L_SLASH_HELP},
  {BAGANATOR_L_SLASH_KEYWORDS, BAGANATOR_L_SLASH_KEYWORDS_HELP},
  {BAGANATOR_L_SLASH_CATEGORIES, BAGANATOR_L_SLASH_CATEGORIES_HELP},
  {BAGANATOR_L_SLASH_SEARCH_EXTENDED, BAGANATOR_L_SLASH_SEARCH_HELP},
  {BAGANATOR_L_SLASH_REMOVEUNUSEDCATEGORIES, BAGANATOR_L_SLASH_REMOVEUNUSEDCATEGORIES_HELP},
  {BAGANATOR_L_SLASH_RESET, BAGANATOR_L_SLASH_RESET_HELP},
  {BAGANATOR_L_SLASH_RESETCATEGORIES, BAGANATOR_L_SLASH_RESETCATEGORIES_HELP},
}

function addonTable.SlashCmd.Handler(input)
  local split = {strsplit("\a", (input:gsub("%s+","\a")))}

  local root = split[1]
  if COMMANDS[root] ~= nil then
    table.remove(split, 1)
    COMMANDS[root](unpack(split))
  else
    if root ~= "help" and root ~= "h" then
      addonTable.Utilities.Message(BAGANATOR_L_SLASH_UNKNOWN_COMMAND:format(root))
    end

    for _, entry in ipairs(HELP) do
      if entry[1] == "" then
        addonTable.Utilities.Message("/bgr - " .. entry[2])
      else
        addonTable.Utilities.Message("/bgr " .. entry[1] .. " - " .. entry[2])
      end
    end
  end
end
