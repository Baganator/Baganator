local addonName, addonTable = ...

addonTable.allFrames = {}

Baganator.Skins = {}

function Baganator.Skins.AddFrame(regionType, region, tags)
  if not region.added then
    local details = {regionType = regionType, region = region, tags = tags}
    table.insert(addonTable.allFrames, details)
    if addonTable.skinListeners then
      for _, listener in ipairs(addonTable.skinListeners) do
        xpcall(listener, CallErrorHandler, details)
      end
    end
    region.added = true
  end
end
