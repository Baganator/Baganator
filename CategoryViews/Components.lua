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
  if button == "RightButton" and self.categorySearch and Baganator.Config.Get(Baganator.Config.Options.SHOW_TRANSFER_BUTTON) then
    self:GetParent():TransferCategory(self.categorySearch)
  end
end

function BaganatorCategoryViewsCategoryButtonMixin:OnEnter()
end

function BaganatorCategoryViewsCategoryButtonMixin:OnLeave()
end
