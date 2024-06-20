local classicCachedObjectCounter = 0

function Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailCachedItemButtonTemplate", nil, false, function(b) b:UpdateTextures() end)
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      local b = CreateFrame("Button", "BGRCachedItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicCachedItemButtonTemplate")
      b:UpdateTextures()
      return b
    end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailLiveContainerItemButtonTemplate", nil, false, function(b) b:UpdateTextures() end)
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      local b = CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicLiveContainerItemButtonTemplate")
      b:UpdateTextures()
      return b
    end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetLiveGuildItemButtonPool(parent)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", parent, "BaganatorRetailLiveGuildItemButtonTemplate", nil, false, function(b) b:UpdateTextures() end)
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      local b = CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, parent, "BaganatorClassicLiveGuildItemButtonTemplate")
      b:UpdateTextures()
      return b
    end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetLiveWarbandItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailLiveWarbandItemButtonTemplate", nil, false, function(b) b:UpdateTextures() end)
  else
    error("no warbands here")
  end
end

function Baganator.ItemViewCommon.GetTabButtonPool(parent)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("Button", parent, "BaganatorRetailTabButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRItemViewCommonTabButton" .. classicCachedObjectCounter, parent, "BaganatorClassicTabButtonTemplate")
    end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetSideTabButtonPool(parent)
  return CreateObjectPool(function(pool)
    classicCachedObjectCounter = classicCachedObjectCounter + 1
    return CreateFrame("Button", "BGRItemViewCommonTabButton" .. classicCachedObjectCounter, parent, "BaganatorRightSideTabButtonTemplate")
  end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
end
