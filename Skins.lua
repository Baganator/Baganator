local _, addonTable = ...

addonTable.Skins.allFrames = {}

function addonTable.Skins.AddFrame(regionType, region, tags)
  if not region.added then
    local details = {regionType = regionType, region = region, tags = tags}
    table.insert(addonTable.Skins.allFrames, details)
    if addonTable.Skins.skinListeners then
      for _, listener in ipairs(addonTable.Skins.skinListeners) do
        xpcall(listener, CallErrorHandler, details)
      end
    end
    region.added = true
  end
end

Baganator.Skins = { AddFrame = addonTable.Skins.AddFrame }
