local _, addonTable = ...
local classicCachedObjectCounter = 0

function addonTable.ItemViewCommon.GetCachedItemButtonPool(self)
  if addonTable.Constants.IsRetail then
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

function addonTable.ItemViewCommon.GetLiveItemButtonPool(self)
  if addonTable.Constants.IsRetail then
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

function addonTable.ItemViewCommon.GetLiveGuildItemButtonPool(parent)
  if addonTable.Constants.IsRetail then
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

function addonTable.ItemViewCommon.GetLiveWarbandItemButtonPool(self)
  if addonTable.Constants.IsRetail then
    return CreateFramePool("ItemButton", self, "BaganatorRetailLiveWarbandItemButtonTemplate", nil, false, function(b) b:UpdateTextures() end)
  else
    error("no warbands here")
  end
end

function addonTable.ItemViewCommon.GetTabButtonPool(parent)
  if addonTable.Constants.IsRetail then
    return CreateFramePool("Button", parent, "BaganatorRetailTabButtonTemplate")
  else
    return CreateObjectPool(function(pool)
      classicCachedObjectCounter = classicCachedObjectCounter + 1
      return CreateFrame("Button", "BGRItemViewCommonTabButton" .. classicCachedObjectCounter, parent, "BaganatorClassicTabButtonTemplate")
    end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
  end
end

function addonTable.ItemViewCommon.GetSideTabButtonPool(parent)
  return CreateObjectPool(function(pool)
    classicCachedObjectCounter = classicCachedObjectCounter + 1
    return CreateFrame("Button", "BGRItemViewCommonTabButton" .. classicCachedObjectCounter, parent, "BaganatorRightSideTabButtonTemplate")
  end, FramePool_HideAndClearAnchors or Pool_HideAndClearAnchors)
end
