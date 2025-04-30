---@class addonTableBaganator
local addonTable = select(2, ...)

local function ToHSL(r, g, b)
  local M = math.max(r, g, b)
  local m = math.min(r, g, b)

  local c = M - m

  local h_dash
  if c == 0 then
    h_dash = 0
  elseif M == r then
    h_dash = ((g - b) / c) % 6
  elseif M == g then
    h_dash = (b - r) / c + 2
  elseif M == b then
    h_dash = (r - g) / c + 4
  end
  local h = h_dash * 60

  local l = 1/2 * (M + m)

  local s
  if l == 1 or l == 0 then
    s = 0
  else
    s = c / (1 - math.abs(2 * l - 1))
  end

  return h, s, l
end

local function FromHSL(h, s, l)
  local function f(n)
    local k = (n + h/30) % 12
    local a = s * math.min(l, 1-l)
    return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
  end
  return f(0), f(8), f(4)
end

local function Lighten(r, g, b, shift)
  local h, s, l = ToHSL(r, g, b)
  l = math.max(0, math.min(1, l + shift))

  return FromHSL(h, s, l)
end

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local backdropInfo = {
  bgFile = "Interface/AddOns/Baganator/Assets/Skins/dark-backgroundfile",
  edgeFile = "Interface/AddOns/Baganator/Assets/Skins/dark-edgefile",
  tile = true,
  tileEdge = true,
  tileSize = 32,
  edgeSize = 6,
}

local frameBackdropInfo = {
  bgFile = "Interface/AddOns/Baganator/Assets/Skins/dark-backgroundfile",
  edgeFile = "Interface/AddOns/Baganator/Assets/Skins/dark-edgefile",
  tile = true,
  tileEdge = true,
  tileSize = 32,
  edgeSize = 9,
}

--local color = CreateColor(65/255, 137/255, 64/255) -- green
--local color = CreateColor(65/255, 138/255, 180/255) -- blue
local color = CreateColor(0.05, 0.05, 0.05) -- black

local possibleVisuals = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder", "TitleBg", "Bg",
  "TopTileStreaks",
}
local function RemoveFrameTextures(frame)
  for _, key in ipairs(possibleVisuals) do
    if frame[key] then
      frame[key]:Hide()
      frame[key]:SetTexture()
      frame[key] = nil -- Necessary as classic NineSlice pieces have names which clash
    end
  end
  if frame.NineSlice then
    for _, region in ipairs({frame.NineSlice:GetRegions()}) do
      region:Hide()
    end
  end
end

local texCoords = {0.08, 0.92, 0.08, 0.92}
local function ItemButtonQualityHook(frame, quality)
  if frame.bgrSimpleHooked then
    frame.IconBorder:SetTexture("Interface/AddOns/Baganator/Assets/Skins/dark-icon-border")
    frame:ClearNormalTexture()
    local c = ITEM_QUALITY_COLORS[quality]
    if c then
      frame.IconBorder:SetVertexColor(c.r, c.g, c.b, quality > 1 and 1 or 0.5)
      frame.IconBorder:Show()
    else
      frame.IconBorder:SetVertexColor(color.r, color.g, color.b, 1)
      frame.IconBorder:Show()
    end
  end
end
local function ItemButtonTextureHook(frame)
  if frame.bgrSimpleHooked then
    frame.icon:SetTexCoord(unpack(texCoords))
  end
end

local function StyleButton(button)
  button.Left:Hide()
  button.Right:Hide()
  button.Middle:Hide()
  button:ClearHighlightTexture()

  Mixin(button, BackdropTemplateMixin)
  button:SetBackdrop(backdropInfo)
  local color = CreateColor(Lighten(color.r, color.g, color.b, -0.20))
  button:SetBackdropColor(color.r, color.g, color.b, 0.5)
  button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
  button:HookScript("OnEnter", function()
    if button:IsEnabled() then
      local r, g, b = Lighten(color.r, color.g, color.b, 0.3)
      button:SetBackdropColor(r, g, b, 0.8)
      button:SetBackdropBorderColor(r, g, b, 1)
    end
  end)
  button:HookScript("OnMouseDown", function()
    if button:IsEnabled() then
      local r, g, b = Lighten(color.r, color.g, color.b, 0.2)
      button:SetBackdropColor(r, g, b, 0.8)
      button:SetBackdropBorderColor(r, g, b, 1)
    end
  end)
  button:HookScript("OnMouseUp", function()
    if button:IsEnabled() and button:IsMouseOver() then
      local r, g, b = Lighten(color.r, color.g, color.b, 0.3)
      button:SetBackdropColor(r, g, b, 0.8)
      button:SetBackdropBorderColor(r, g, b, 1)
    end
  end)
  button:HookScript("OnLeave", function()
    button:SetBackdropColor(color.r, color.g, color.b, 0.5)
    button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
  end)
  button:HookScript("OnDisable", function()
    button:SetBackdropColor(color.r, color.g, color.b, 0.1)
  end)
  button:HookScript("OnEnable", function()
    button:SetBackdropColor(color.r, color.g, color.b, 0.5)
  end)
end

local function StyleButtonFrameBorder(frame)
  if addonTable.Config.Get("skins.dark.no_frame_borders") then
    frame:SetBackdropBorderColor(1, 1, 1, 0)
  else
    local r, g, b = Lighten(color.r, color.g, color.b, 0.3)
    frame:SetBackdropBorderColor(r, g, b, 1)
  end
end

local showSlots = true
local allItemButtons = {}

local skinners = {
  ItemButton = function(frame, tags)
    frame.bgrSimpleHooked = true
    local r, g, b = Lighten(color.r, color.g, color.b, -0.2)
    if not tags.containerBag then
      table.insert(allItemButtons, frame)
      frame.SlotBackground:SetColorTexture(r, g, b, 0.3)
      frame.SlotBackground:SetPoint("CENTER")
      frame.SlotBackground:SetSize(35, 35)
    end
    frame.SlotBackground:SetShown(showSlots)
    if frame.SetItemButtonQuality then
      hooksecurefunc(frame, "SetItemButtonQuality", ItemButtonQualityHook)
    end
    if frame.SetItemButtonTexture then
      hooksecurefunc(frame, "SetItemButtonTexture", ItemButtonTextureHook)
    end
  end,
  IconButton = function(button)
    StyleButton(button)
  end,
  Button = function(button)
    StyleButton(button)
  end,
  ButtonFrame = function(frame, tags)
    RemoveFrameTextures(frame)
    Mixin(frame, BackdropTemplateMixin)
    frame:SetBackdrop(frameBackdropInfo)
    frame:SetBackdropColor(color.r, color.g, color.b, 1 - addonTable.Config.Get("skins.dark.view_transparency"))
    StyleButtonFrameBorder(frame)
    addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
      if settingName == "skins.dark.view_transparency" then
        frame:SetBackdropColor(color.r, color.g, color.b, 1 - addonTable.Config.Get("skins.dark.view_transparency"))
      elseif settingName == "skins.dark.no_frame_borders" then
        StyleButtonFrameBorder(frame)
      end
    end, frame)

    if tags.backpack then
      frame.TopButtons[1]:SetPoint("TOPLEFT", 1.5, -1)
    elseif tags.bank then
      frame.Character.TopButtons[1]:SetPoint("TOPLEFT", 1.5, -1)
    elseif tags.guild then
      frame.ToggleTabTextButton:SetPoint("TOPLEFT", 1.5, -1)
    end
  end,
  SearchBox = function(frame)
  end,
  EditBox = function(frame)
  end,
  TabButton = function(frame)
  end,
  TopTabButton = function(frame)
  end,
  SideTabButton = function(frame)
  end,
  TrimScrollBar = function(frame)
  end,
  CheckBox = function(frame)
  end,
  Slider = function(frame)
  end,
  InsetFrame = function(frame)
  end,
  CornerWidget = function(frame, tags)
  end,
  Dropdown = function(button)
  end,
}

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and ConvertTags(details.tags) or {})
  end
end

local function SetConstants()
  addonTable.Constants.ButtonFrameOffset = 0
end

local function LoadSkin()
  showSlots = not addonTable.Config.Get("skins.dark.empty_slot_background")
  if addonTable.Utilities.IsMasqueApplying() or not addonTable.Config.Get("skins.dark.square_icons") then
    skinners.ItemButton = function(frame, tags)
      if not tags.containerBag then
        table.insert(allItemButtons, frame)
        frame.SlotBackground:SetShown(showSlots)
      end
    end
  else
    hooksecurefunc("SetItemButtonQuality", ItemButtonQualityHook)
    hooksecurefunc("SetItemButtonTexture", ItemButtonTextureHook)
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == "skins.dark.empty_slot_background" then
      showSlots = not addonTable.Config.Get("skins.dark.empty_slot_background")
      for _, button in ipairs(allItemButtons) do
        button.SlotBackground:SetShown(showSlots)
      end
    end
  end)
end

addonTable.Skins.RegisterSkin(addonTable.Locales.DARK, "dark", LoadSkin, SkinFrame, SetConstants, {
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
    default = 0.3,
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
  {
    type = "checkbox",
    text = addonTable.Locales.SQUARE_ICONS,
    rightText = addonTable.Locales.RELOAD_REQUIRED,
    option = "square_icons",
    default = false,
  },
})
