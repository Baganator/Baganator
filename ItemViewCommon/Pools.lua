local classicCachedObjectCounter = 0

function Baganator.ItemViewCommon.GetCachedItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailCachedItemButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRCachedItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicCachedItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetLiveItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailLiveContainerItemButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, self, "BaganatorClassicLiveContainerItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetLiveGuildItemButtonPool(parent)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", parent, "BaganatorRetailLiveGuildItemButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRLiveItemButton" .. classicCachedObjectCounter, parent, "BaganatorClassicLiveGuildItemButtonTemplate")
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetLiveWarbandItemButtonPool(self)
  if Baganator.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailLiveWarbandItemButtonTemplate")
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
    end, FramePool_HideAndClearAnchors)
  end
end

function Baganator.ItemViewCommon.GetSideTabButtonPool(parent)
  return CreateObjectPool(function(pool)
    classicCachedObjectCounter = classicCachedObjectCounter + 1
    return CreateFrame("Button", "BGRItemViewCommonTabButton" .. classicCachedObjectCounter, parent, "BaganatorRightSideTabButtonTemplate")
  end, FramePool_HideAndClearAnchors)
end
