local _, addonTable = ...
function addonTable.Utilities.Message(text)
  print(LINK_FONT_COLOR:WrapTextInColorCode("Baganator") .. ": " .. text)
end

do
  local callbacksPending = {}
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", function(self, eventName, addonName)
    if callbacksPending[addonName] then
      for _, cb in ipairs(callbacksPending[addonName]) do
        xpcall(cb, CallErrorHandler)
      end
      callbacksPending[addonName] = nil
    end
  end)

  local AddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

  -- Necessary because cannot nest EventUtil.ContinueOnAddOnLoaded
  function addonTable.Utilities.OnAddonLoaded(addonName, callback)
    if select(2, AddOnLoaded(addonName)) then
      xpcall(callback, CallErrorHandler)
    else
      callbacksPending[addonName] = callbacksPending[addonName] or {}
      table.insert(callbacksPending[addonName], callback)
    end
  end
end

function addonTable.Utilities.GetCharacterFullName()
  local characterName, realm = UnitFullName("player")
  return characterName .. "-" .. realm
end

local queue = {}
local reporter = CreateFrame("Frame")
reporter:SetScript("OnUpdate", function()
  if #queue > 0 then
    for _, entry in ipairs(queue) do
      print(entry[1], entry[2])
    end
    queue = {}
  end
end)
function addonTable.Utilities.DebugOutput(label, value)
  table.insert(queue, {label, value})
end
