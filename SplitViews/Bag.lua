local _, addonTable = ...

BaganatorSplitViewBagMixin = {}

function BaganatorSplitViewBagMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  self:SetUserPlaced(false)

  self.liveItemButtonPool = addonTable.ItemViewCommon.GetLiveItemButtonPool(self)

  self.Anchor = addonTable.ItemViewCommon.GetAnchorSetter(self, addonTable.Config.Options.MAIN_VIEW_POSITION)

  -- DO NOT REMOVE
  -- Preallocating is necessary to avoid taint issues if a
  -- player logs in or first opens their bags when in combat
  -- 6 is bags + reagent bag (retail) or bags + keyring (wrath)
  addonTable.Utilities.PreallocateItemButtons(self.liveItemButtonPool, Syndicator.Constants.MaxBagSize)
end

function BaganatorSplitViewBagMixin:ApplySearch(text)
  if self.isLive then
    self.BagLive:ApplySearch(text)
  else
    self.BagCached:ApplySearch(text)
  end
end

function BaganatorSplitViewBagMixin:NotifyBagUpdate(updatedBags)
  self.BagLive:MarkBagsPending("bags", updatedBags)

  -- Update cached views with current items when live or on login
  if self.isLive == nil or self.isLive == true then
    self.BagCached:MarkBagsPending("bags", updatedBags)
  end
end

function BaganatorSplitViewBagMixin:UpdateForCharacter(character, isLive)
  self.isLive = isLive

  self.BagLive:SetShown(isLive)
  self.BagCached:SetShown(not isLive)

  local bag = self.BagLive:IsShown() and self.BagLive or self.BagCached

  local characterData = Syndicator.API.GetCharacter(character)
  local bagIndex = tIndexOf(Syndicator.Constants.AllBagIndexes, self:GetID())
  if not characterData.bags[bagIndex] or #characterData.bags[bagIndex] == 0 then
    self:Hide()
    return
  end
  self:Show()

  bag:ShowBags(characterData.bags, character, Syndicator.Constants.AllBagIndexes, {[bagIndex] = true}, 4)

  bag:SetPoint("TOPLEFT", 10 + addonTable.Constants.ButtonFrameOffset, -30)
  self:SetSize(bag:GetWidth() + 20 + addonTable.Constants.ButtonFrameOffset, bag:GetHeight() + 40)
end
