-- Refresh bags so that searches for #locked reflect the new unlocked status of
-- a particular lockbox
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_SPELLCAST_STOP")
frame:SetScript("OnEvent", function(self, eventName, unit, castID, spellID)
  if spellID == 1804 or spellID == 312890 then -- rogue lockpick or mechgnome racial
    C_Timer.After(0.25, function()
      Baganator.API.RequestItemButtonsRefresh()
    end)
  end
end)
