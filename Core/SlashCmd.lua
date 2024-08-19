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

function addonTable.SlashCmd.CustomiseUI()
  addonTable.CallbackRegistry:TriggerEvent("ShowCustomise")
end

local COMMANDS = {
  ["c"] = addonTable.SlashCmd.Config,
  ["config"] = addonTable.SlashCmd.Config,
  ["reset"] = addonTable.SlashCmd.Reset,
  [""] = addonTable.SlashCmd.CustomiseUI,
  ["search"] = function(text)
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", text)
    addonTable.CallbackRegistry:TriggerEvent("BagShow")
  end,
  ["keywords"] = function()
    addonTable.Config.Set(addonTable.Config.Options.DEBUG_KEYWORDS, not addonTable.Config.Get(addonTable.Config.Options.DEBUG_KEYWORDS))
  end,
  ["categories"] = function()
    addonTable.Config.Set(addonTable.Config.Options.DEBUG_CATEGORIES, not addonTable.Config.Get(addonTable.Config.Options.DEBUG_CATEGORIES))
  end,
}
function addonTable.SlashCmd.Handler(input)
  local split = {strsplit("\a", (input:gsub("%s+","\a")))}

  local root = split[1]
  if COMMANDS[root] ~= nil then
    table.remove(split, 1)
    COMMANDS[root](unpack(split))
  else
    addonTable.Utilities.Message("Unknown command '" .. root .. "'")
  end
end
