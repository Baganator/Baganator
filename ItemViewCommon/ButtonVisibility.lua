local _, addonTable = ...
BaganatorItemViewButtonVisibilityMixin = {}

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

function BaganatorItemViewButtonVisibilityMixin:OnLoad()
  self.originalParents = {}
end

function BaganatorItemViewButtonVisibilityMixin:OnEvent(...)
  self:Update()
end

function BaganatorItemViewButtonVisibilityMixin:OnShow()
  self:RegisterEvent("MODIFIER_STATE_CHANGED")
  addonTable.CallbackRegistry:RegisterCallback("PropagateAlt", self.Update, self)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if settingName == addonTable.Config.Options.SHOW_BUTTONS_ON_ALT then
      self:Update()
    end
  end, self)

  self:Update()
end

function BaganatorItemViewButtonVisibilityMixin:OnHide()
  self:UnregisterEvent("MODIFIER_STATE_CHANGED")
  addonTable.CallbackRegistry:UnregisterCallback("PropagateAlt", self)
  addonTable.CallbackRegistry:UnregisterCallback("SettingChanged", self)

  local AllButtons = self:GetParent().AllButtons
  if not AllButtons then
    return
  end
  for _, button in ipairs(AllButtons) do
    if button:GetParent() == hiddenParent then
      button:SetParent(self.originalParents[button])
      button:SetFrameLevel(700)
    end
  end
end

function BaganatorItemViewButtonVisibilityMixin:Update()
  local AllButtons = self:GetParent().AllButtons
  if not AllButtons then
    return
  end

  local shown = true
  if addonTable.Config.Get(addonTable.Config.Options.SHOW_BUTTONS_ON_ALT) and not IsAltKeyDown() then
    shown = false
  end

  for _, button in ipairs(AllButtons) do
    if shown and button:GetParent() == hiddenParent then
      button:SetParent(self.originalParents[button])
      button:SetFrameLevel(700)
    elseif not shown and button:GetParent() ~= hiddenParent then
      self.originalParents[button] = button:GetParent()
      button:SetParent(hiddenParent)
    end
  end
end
