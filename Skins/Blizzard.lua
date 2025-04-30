---@class addonTableBaganator
local addonTable = select(2, ...)

local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

local function UpdateButtonFrameVisuals(frame)
  local alpha = 1 - addonTable.Config.Get("skins.blizzard.view_transparency")
  local noFrameBorders = addonTable.Config.Get("skins.blizzard.no_frame_borders")

  frame.Bg:SetAlpha(alpha)
  frame.TopTileStreaks:SetAlpha(alpha)

  if frame.NineSlice then -- retail
    frame.NineSlice:SetAlpha(alpha)
    frame.NineSlice:SetShown(not noFrameBorders)
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", addonTable.Constants.IsClassic and 2 or 6, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", addonTable.Constants.IsClassic and 2 or 6, -21)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, -21)
    end
    if frame.NineSlice:GetRegions() == nil then
      for _, key in ipairs(classicBorderFrames) do
        frame[key]:SetAlpha(alpha)
        frame[key]:SetShown(not noFrameBorders)
      end
    end
  elseif frame.TitleBg then -- older classic builds
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

local showSlots = true
local allItemButtons = {}
local allButtonFrames = {}

local skinners = {
  ItemButton = function(frame, tags)
    if not tags.containerBag then
      frame.SlotBackground:SetShown(showSlots)
      table.insert(allItemButtons, frame)
    end
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

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and ConvertTags(details.tags) or {})
  end
end

local function SetConstants()
  if addonTable.Constants.IsRetail then
    addonTable.Constants.ButtonFrameOffset = 6
  end
  if addonTable.Constants.IsClassic then
    addonTable.Constants.ButtonFrameOffset = 0
  end
end

local function LoadSkin()
  showSlots = not addonTable.Config.Get("skins.blizzard.empty_slot_background")

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == "skins.blizzard.empty_slot_background" then
      showSlots = not addonTable.Config.Get("skins.blizzard.empty_slot_background")
      for _, button in ipairs(allItemButtons) do
        button.SlotBackground:SetShown(showSlots)
      end
    elseif settingName == "skins.blizzard.no_frame_borders" or settingName == "skins.blizzard.view_transparency" then
      for _, frame in ipairs(allButtonFrames) do
        UpdateButtonFrameVisuals(frame)
      end
    end
  end)
end

addonTable.Skins.RegisterSkin(addonTable.Locales.BLIZZARD, "blizzard", LoadSkin, SkinFrame, SetConstants, {
  {
    type = "slider",
    min = 0,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    text = addonTable.Locales.TRANSPARENCY,
    valuePattern = addonTable.Locales.PERCENTAGE_PATTERN,
    option = "view_transparency",
    default = 0,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.REMOVE_BORDERS,
    option = "no_frame_borders",
    default = false,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.HIDE_ICON_BACKGROUNDS,
    option = "empty_slot_background",
    default = false,
  },
})
