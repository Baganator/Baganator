local _, addonTable = ...
function addonTable.SingleViews.GetCollapsingBagSectionsPool(self)
  return CreateObjectPool(function(pool)
    local button = CreateFrame("Button", nil, self, "BaganatorTooltipIconButtonTemplate")
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
    return {
      live = CreateFrame("Frame", nil, self, "BaganatorLiveBagLayoutTemplate"),
      cached = CreateFrame("Frame", nil, self, "BaganatorCachedBagLayoutTemplate"),
      divider = CreateFrame("Frame", nil, self, "BaganatorBagDividerTemplate"),
      button = button,
    }
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
