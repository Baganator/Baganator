local _, addonTable = ...
BaganatorCategoryViewsCategoryButtonMixin = {}

function BaganatorCategoryViewsCategoryButtonMixin:OnLoad()
  self:GetFontString():SetJustifyH("LEFT")
  self:GetFontString():SetWordWrap(false)
  self:GetFontString():SetPoint("LEFT")
  self:GetFontString():SetPoint("RIGHT")
  self:RegisterForClicks("AnyUp")
end

function BaganatorCategoryViewsCategoryButtonMixin:Resize()
  self:SetSize(self:GetFontString():GetUnboundedStringWidth(), self:GetFontString():GetHeight())
end

function BaganatorCategoryViewsCategoryButtonMixin:OnClick(button)
  if button == "RightButton" and self.categorySearch then
    CallMethodOnNearestAncestor(self, "TransferCategory", self.categorySearch, self.source, self.groupLabel)
  elseif button == "LeftButton" then
    addonTable.NewItems:ForceClearNewItemsForTimeout()
  end
end

function BaganatorCategoryViewsCategoryButtonMixin:OnEnter()
  if self:GetFontString():IsTruncated() then
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(self:GetText())
  end
end

function BaganatorCategoryViewsCategoryButtonMixin:OnLeave()
  GameTooltip:Hide()
end

function addonTable.CategoryViews.GetSectionButtonPool(parent)
  return CreateFramePool("Button", parent, nil, nil, false, function(button)
    if button.arrow then
      return
    end
    button:SetNormalFontObject("GameFontNormalMed2")
    button:SetText(" ")
    button:GetFontString():SetPoint("LEFT", 20, 0)
    button:GetFontString():SetPoint("RIGHT")
    button:GetFontString():SetJustifyH("LEFT")
    button:SetHeight(20)
    button.arrow = button:CreateTexture(nil, "ARTWORK")
    button.arrow:SetSize(14, 14)
    button.arrow:SetAtlas("bag-arrow")
    button.arrow:SetPoint("LEFT")
    function button:SetExpanded()
      button.arrow:SetRotation(math.pi/2)
    end
    function button:SetCollapsed()
      button.arrow:SetRotation(-math.pi)
    end
    addonTable.Skins.AddFrame("CategorySectionHeader", button)
    return button
  end)
end
