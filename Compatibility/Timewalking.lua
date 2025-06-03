---@class addonTableBaganator
local addonTable = select(2, ...)

local frame = CreateFrame("Frame")

local prevInstanceDifficulty
local timewalking = {
  [24] = true, -- dungeon
  [33] = true, -- raid
}

frame:SetScript("OnEvent", function()
  local instanceDifficulty = select(3, GetInstanceInfo())
  if instanceDifficulty ~= prevInstanceDifficulty and timewalking[prevInstanceDifficulty] or timewalking[instanceDifficulty] then
    Baganator.API.RequestItemButtonsRefresh()
  end
  prevInstanceDifficulty = instanceDifficulty
end)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

