function Baganator.InitializeCustomiseDialog()
  local customiseDialog

  Baganator.CallbackRegistry:RegisterCallback("ShowCustomise", function()
    if not customiseDialog then
      customiseDialog = CreateFrame("Frame", "BaganatorCustomiseDialogFrame", UIParent, "BaganatorCustomiseDialogTemplate")
      customiseDialog:SetPoint("CENTER")
      table.insert(UISpecialFrames, customiseDialog:GetName())
    end
    customiseDialog:RefreshOptions()
    customiseDialog:SetShown(not customiseDialog:IsShown())
    customiseDialog:Raise()
  end)
end
