---@class addonTableBaganator
local addonTable = select(2, ...)
function addonTable.SingleViews.GetCollapsingBagSectionsPool(self)
  return CreateObjectPool(function(pool)
    local details = {
      live = CreateFrame("Frame", nil, self, "BaganatorLiveBagLayoutTemplate"),
      cached = CreateFrame("Frame", nil, self, "BaganatorCachedBagLayoutTemplate"),
      divider = CreateFrame("Frame", nil, self, "BaganatorBagDividerTemplate"),
      button = CreateFrame("Button", nil, self, "BaganatorTooltipIconButtonTemplate"),
    }
    local button = details.button
    button.Icon = button:CreateTexture(nil, "ARTWORK")
    button:SetPoint("CENTER")
    button.Icon:SetSize(17, 17)
    button.Icon:SetPoint("CENTER")
    button:HookScript("OnEnter", function(self)
      addonTable.CallbackRegistry:TriggerEvent("HighlightBagItems", button.bagIDsToUse)

      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.tooltipHeader)
      if self.tooltipText then
        GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
      end
      GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function(self)
      addonTable.CallbackRegistry:TriggerEvent("ClearHighlightBag")

      GameTooltip:Hide()
    end)
    button:SetScript("OnShow", function(self)
      addonTable.CallbackRegistry:RegisterCallback("SearchMonitorComplete", self.CheckResults, self)
      addonTable.CallbackRegistry:RegisterCallback("SpecialBagToggled", self.CheckResults, self)
    end)
    button:SetScript("OnHide", function(self)
      addonTable.CallbackRegistry:UnregisterCallback("SearchMonitorComplete", self)
      addonTable.CallbackRegistry:UnregisterCallback("SpecialBagToggled", self)
      self.fadeAnimation:Stop()
    end)
    button.fadeAnimation = button:CreateAnimationGroup()
    button.fadeAnimation:SetLooping("REPEAT")
    do
      local fade1 = button.fadeAnimation:CreateAnimation("Alpha")
      fade1:SetFromAlpha(1)
      fade1:SetToAlpha(0.4)
      fade1:SetDuration(0.5)
      fade1:SetTarget(button.Icon)
      fade1:SetOrder(1)
      fade1:SetSmoothing("IN_OUT")
      local fade2 = button.fadeAnimation:CreateAnimation("Alpha")
      fade2:SetFromAlpha(0.4)
      fade2:SetToAlpha(1)
      fade2:SetDuration(0.5)
      fade1:SetSmoothing("IN_OUT")
      fade2:SetTarget(button.Icon)
      fade2:SetOrder(2)
    end
    function button:CheckResults(text)
      self.fadeAnimation:Stop()
      text = text or button.lastSearch
      button.lastSearch = text
      if text == "" or not addonTable.Config.Get(addonTable.Config.Options.HIDE_SPECIAL_CONTAINER)[details.key] then
        return
      end
      local layout = details.live:IsShown() and details.live or details.cached
      for _, button in ipairs(layout.buttons) do
        if button.BGR and button.BGR.matchesSearch and (button.BGR.contextMatch == nil or button.BGR.contextMatch) then
          self.fadeAnimation:Play()
          return -- done
        end
      end
    end

    return details
  end,
  function(pool, details)
    details.live:Deallocate()
    details.live:Hide()
    details.live:ClearAllPoints()
    details.cached:Hide()
    details.cached:ClearAllPoints()
    details.divider:Hide()
    details.divider:ClearAllPoints()
    details.button:Hide()
    details.button:ClearAllPoints()
  end)
end
