function Baganator.SingleViews.GetCollapsingBagSectionsPool(self)
  return CreateObjectPool(function(pool)
    local button = CreateFrame("Button", nil, self, "BaganatorTooltipIconButtonTemplate")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button:SetPoint("CENTER")
    button.icon:SetSize(17, 17)
    button.icon:SetPoint("CENTER")
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
