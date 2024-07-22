local _, addonTable = ...
do
  if C_Engraving and C_Engraving.IsEngravingEnabled() then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ENGRAVING_MODE_CHANGED")
    frame:RegisterEvent("RUNE_UPDATED")
    frame:SetScript("OnEvent", function()
      if Baganator.API.IsCornerWidgetActive("engraved_rune") then
        Baganator.API.RequestItemButtonsRefresh()
      end
    end)
  end
end
