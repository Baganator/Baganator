local classicCachedObjectCounter = 0

function Baganator.UnifiedViews.GetCachedItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailCachedItemButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRCachedItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.UnifiedViews.GetLiveItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailLiveContainerItemButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicLiveContainerItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.UnifiedViews.GetCollapsingBagSectionsPool(self)
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

function Baganator.UnifiedViews.GetLiveGuildItemButtonPool(parent)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", parent, "BaganatorRetailLiveGuildItemButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, parent, "BaganatorClassicLiveGuildItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.UnifiedViews.GetTabButtonPool(parent)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("Button", parent, "BaganatorRetailTabButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRUnifiedViewsTabButton" .. classicCachedObjectCounter, parent, "BaganatorClassicTabButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.UnifiedViews.GetSideTabButtonPool(parent)
  return CreateObjectPool(function(pool)
    classicCachedObjectCounter = classicCachedObjectCounter + 1
    return CreateFrame("Button", "BGRUnifiedViewsTabButton" .. classicCachedObjectCounter, parent, "BaganatorRightSideTabButtonTemplate")
  end, FramePool_HideAndClearAnchors)
end
