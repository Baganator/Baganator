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
  self:SetSize(self:GetFontString():GetUnboundedStringWidth(), self:GetFontString():GetLineHeight())
end

function BaganatorCategoryViewsCategoryButtonMixin:OnClick(button)
  if button == "RightButton" and self.sourceKey then
    CallMethodOnNearestAncestor(self, "TransferCategory", self.sourceKey)
  elseif button == "LeftButton" and self.source == addonTable.CategoryViews.Constants.RecentItemsCategory then
    addonTable.NewItems:ForceClearNewItemsForTimeout()
  end
end

function BaganatorCategoryViewsCategoryButtonMixin:OnEnter()
  local _, transferActive = CallMethodOnNearestAncestor(self, "IsTransferActive")
  local isRecent = self.source == addonTable.CategoryViews.Constants.RecentItemsCategory
  if self:GetFontString():IsTruncated() or transferActive or isRecent then
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(self:GetText())
    if isRecent then
      GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_CLICK_TO_CLEAR_RECENT))
    end
    if transferActive then
      if C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.Merchant) then
        GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_RIGHT_CLICK_TO_VENDOR_6))
        GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_SHIFT_CLICK_TO_VENDOR_ALL))
      else
        GameTooltip:AddLine(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_RIGHT_CLICK_TO_TRANSFER))
      end
    end
    GameTooltip:Show()
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
    button:RegisterForClicks("RightButtonUp", "LeftButtonUp")
    button.fadeAnimation = button:CreateAnimationGroup()
    local function GenerateAnimations(region)
      local fade1 = button.fadeAnimation:CreateAnimation("Alpha")
      fade1:SetFromAlpha(1)
      fade1:SetToAlpha(0.4)
      fade1:SetDuration(0.5)
      fade1:SetTarget(region)
      fade1:SetOrder(1)
      fade1:SetSmoothing("IN_OUT")
      local fade2 = button.fadeAnimation:CreateAnimation("Alpha")
      fade2:SetFromAlpha(0.4)
      fade2:SetToAlpha(1)
      fade2:SetDuration(0.5)
      fade1:SetSmoothing("IN_OUT")
      fade2:SetTarget(region)
      fade2:SetOrder(2)
    end
    GenerateAnimations(button:GetFontString())
    GenerateAnimations(button.arrow)
    button.fadeAnimation:SetLooping("REPEAT")

    function button:SetExpanded()
      button.arrow:SetRotation(math.pi/2)
      button.collapsed = false
    end
    function button:SetCollapsed()
      button.arrow:SetRotation(-math.pi)
      button.collapsed = true
    end
    button:SetScript("OnClick", function(self, button)
      if button == "LeftButton" then
        local sectionToggled = addonTable.Config.Get(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED)
        sectionToggled[self.source] = not sectionToggled[self.source]
        addonTable.Config.Set(addonTable.Config.Options.CATEGORY_SECTION_TOGGLED, CopyTable(sectionToggled))
      elseif button == "RightButton" then
        local tree = CopyTable(self.section)
        table.insert(tree, self.source)
        CallMethodOnNearestAncestor(self, "TransferSection", tree)
      end
    end)
    button:SetScript("OnEnter", BaganatorCategoryViewsCategoryButtonMixin.OnEnter)
    button:SetScript("OnLeave", BaganatorCategoryViewsCategoryButtonMixin.OnLeave)
    button:SetScript("OnShow", function(self)
      self:CheckResults(self.lastText or "")
      addonTable.CallbackRegistry:RegisterCallback("SearchMonitorComplete", self.CheckResults, self)
    end)
    button:SetScript("OnHide", function(self)
      addonTable.CallbackRegistry:UnregisterCallback("SearchMonitorComplete", self)
      self.fadeAnimation:Stop()
    end)
    function button:CheckResults(text)
      self.fadeAnimation:Stop()
      self.lastText = text
      if text == "" or not self.collapsed then
        return
      end
      local found, layouts = CallMethodOnNearestAncestor(self, "GetActiveLayouts")
      for _, layout in ipairs(layouts) do
        if layout.type == "category" and layout.section[#self.section + 1] == self.source then
          local rootMatch = true
          for index = 1, #self.section do
            rootMatch = layout.section[index] == self.section[index]
            if not rootMatch then
              break
            end
          end
          if rootMatch then
            for _, button in ipairs(layout.buttons) do
              if button.BGR and button.BGR.matchesSearch and (button.BGR.contextMatch == nil or button.BGR.contextMatch) then
                self.fadeAnimation:Play()
                return -- done
              end
            end
          end
        end
      end
    end
    addonTable.Skins.AddFrame("CategorySectionHeader", button)
    return button
  end)
end
