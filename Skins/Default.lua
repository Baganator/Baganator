local _, addonTable = ...

local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

local function UpdateButtonFrameVisuals(frame)
  local alpha = 1 - addonTable.Config.Get("skins.default.view_transparency")
  local noFrameBorders = addonTable.Config.Get("skins.default.no_frame_borders")

  frame.Bg:SetAlpha(alpha)
  frame.TopTileStreaks:SetAlpha(alpha)

  if frame.NineSlice then -- retail
    frame.NineSlice:SetAlpha(alpha)
    frame.NineSlice:SetShown(not noFrameBorders)
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 6, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 6, -21)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, -21)
    end
  elseif frame.TitleBg then -- classic
    frame.TitleBg:SetAlpha(alpha)
    for _, key in ipairs(classicBorderFrames) do
      frame[key]:SetAlpha(alpha)
      frame[key]:SetShown(not noFrameBorders)
    end
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 2, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, 0)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 2, -21)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, -21)
    end
  end
end

local allItemButtons = {}
local allButtonFrames = {}

local skinners = {
  ItemButton = function(frame)
    table.insert(allItemButtons, frame)
  end,
  ButtonFrame = function(frame, tags)
    table.insert(allButtonFrames, frame)
    UpdateButtonFrameVisuals(frame)
  end,
}

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local function LoadSkin()
  local function SkinFrame(details)
    local func = skinners[details.regionType]
    if func then
      func(details.region, details.tags and ConvertTags(details.tags) or {})
    end
  end

  addonTable.Skins.RegisterListener(SkinFrame)

  for _, details in ipairs(addonTable.Skins.GetAllFrames()) do
    SkinFrame(details)
  end

  local showSlots = not addonTable.Config.Get("skins.default.empty_slot_background")
  for _, button in ipairs(allItemButtons) do
    button.SlotBackground:SetShown(showSlots)
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == "skins.default.empty_slot_background" then
      local showSlots = not addonTable.Config.Get("skins.default.empty_slot_background")
      for _, button in ipairs(allItemButtons) do
        button.SlotBackground:SetShown(showSlots)
      end
    elseif settingName == "skins.default.no_frame_borders" or settingName == "skins.default.view_transparency" then
      for _, frame in ipairs(allButtonFrames) do
        UpdateButtonFrameVisuals(frame)
      end
    end
  end)
end

addonTable.Skins.RegisterSkin(BAGANATOR_L_BLIZZARD, "blizzard", LoadSkin, {
  {
    type = "slider",
    min = 0,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    text = BAGANATOR_L_TRANSPARENCY,
    valuePattern = BAGANATOR_L_PERCENTAGE_PATTERN,
    option = "view_transparency",
    default = 0,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_REMOVE_BORDERS,
    option = "no_frame_borders",
    default = false,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_HIDE_ICON_BACKGROUNDS,
    option = "empty_slot_background",
    default = false,
  },
})
