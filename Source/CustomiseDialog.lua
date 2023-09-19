BaganatorCustomiseDialogMixin = {}

function BaganatorCustomiseDialogMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:SetTitle(BAGANATOR_L_CUSTOMISE_BAGANATOR)

  self.ResetFramePositions:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("ResetFramePositions")
  end)
end

function BaganatorCustomiseDialogMixin:RefreshOptions()
  self.LockFrames.CheckBox:SetChecked(Baganator.Config.Get(Baganator.Config.Options.LOCK_FRAMES))
  self.NoFrameBorders.CheckBox:SetChecked(Baganator.Config.Get(Baganator.Config.Options.NO_FRAME_BORDERS))
  self.EmptySlotBackground.CheckBox:SetChecked(Baganator.Config.Get(Baganator.Config.Options.EMPTY_SLOT_BACKGROUND))
  self.AlphaSlider.Slider:SetValue(Baganator.Config.Get(Baganator.Config.Options.VIEW_ALPHA) * 100)
  self.BagWidthSlider.Slider:SetValue(Baganator.Config.Get(Baganator.Config.Options.BAG_VIEW_WIDTH))
  self.BankWidthSlider.Slider:SetValue(Baganator.Config.Get(Baganator.Config.Options.BANK_VIEW_WIDTH))
end
