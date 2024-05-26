local function SetupCharacterSelect()
  local characterSelect = CreateFrame("Frame", "Baganator_CharacterSelectFrame", UIParent, "BaganatorCharacterSelectTemplate")

  table.insert(UISpecialFrames, characterSelect:GetName())

  local function SetPositions()
    characterSelect:ClearAllPoints()
    -- Fix for setting storing frame instead of just the frame name in previous
    -- versions
    local setting = Baganator.Config.Get(Baganator.Config.Options.CHARACTER_SELECT_POSITION)
    if type(setting[2]) == "table" then
      setting[2] = nil
    end
    local anchor = CopyTable(setting)
    if _G[anchor[2]] == nil then -- Accommodate renamed backpack frames
      anchor[2] = Baganator_SingleViewBackpackViewFrame or UIParent
      setting[2] = anchor[2]:GetName()
    end
    characterSelect:SetPoint(unpack(anchor))
  end

  local function ResetPositions()
    Baganator.Config.ResetOne(Baganator.Config.Options.CHARACTER_SELECT_POSITION)
    SetPositions()
  end

  local success = pcall(SetPositions) -- work around broken values
  if not success then
    ResetPositions()
  end

  Baganator.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    ResetPositions()
  end)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelectToggle", function(_, guildName)
    characterSelect:SetShown(not characterSelect:IsShown())
  end)
end

function Baganator.ItemViewCommon.Initialize()
  Baganator.ItemButtonUtil.UpdateSettings()

  xpcall(function()
    Baganator.InitializeOpenClose()
  end, CallErrorHandler)

  SetupCharacterSelect()
end
