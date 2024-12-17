local _, addonTable = ...

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

local toColor = {
  backdrops = {},
  textures = {},
}

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
      frame.IconBorder:SetVertexColor(c.r, c.g, c.b)
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
  local color = CreateColor(addonTable.Skins.Lighten(color.r, color.g, color.b, -0.20))
  button:SetBackdropColor(color.r, color.g, color.b, 0.5)
  button:SetBackdropBorderColor(color.r, color.g, color.b, 1)
  table.insert(toColor.backdrops, {backdrop = button, bgAlpha = 0.5, borderAlpha = 1, lightened = -0.20})
  button:HookScript("OnEnter", function()
    if button:IsEnabled() then
      local r, g, b = addonTable.Skins.Lighten(color.r, color.g, color.b, 0.3)
      button:SetBackdropColor(r, g, b, 0.8)
      button:SetBackdropBorderColor(r, g, b, 1)
    end
  end)
  button:HookScript("OnMouseDown", function()
    if button:IsEnabled() then
      local r, g, b = addonTable.Skins.Lighten(color.r, color.g, color.b, 0.2)
      button:SetBackdropColor(r, g, b, 0.8)
      button:SetBackdropBorderColor(r, g, b, 1)
    end
  end)
  button:HookScript("OnMouseUp", function()
    if button:IsEnabled() and button:IsMouseOver() then
      local r, g, b = addonTable.Skins.Lighten(color.r, color.g, color.b, 0.3)
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

local showSlots = true
local allItemButtons = {}

local skinners = {
  ItemButton = function(frame, tags)
    frame.bgrSimpleHooked = true
    local r, g, b = addonTable.Skins.Lighten(color.r, color.g, color.b, -0.2)
    if not tags.containerBag then
      table.insert(allItemButtons, frame)
      frame.SlotBackground:SetColorTexture(r, g, b, 0.3)
      frame.SlotBackground:SetPoint("CENTER")
      frame.SlotBackground:SetSize(35, 35)
      table.insert(toColor.textures, {texture = frame.SlotBackground, alpha = 0.3, lightened = -0.2})
    end
    frame.SlotBackground:SetShown(showSlots)
    if frame.SetItemButtonQuality then
      hooksecurefunc(frame, "SetItemButtonQuality", ItemButtonQualityHook)
    end
    if frame.SetItemButtonTexture then
      hooksecurefunc(frame, "SetItemButtonTexture", ItemButtonTextureHook)
    end
  end,
  ButtonFrame = function(frame, tags)
    RemoveFrameTextures(frame)
    Mixin(frame, BackdropTemplateMixin)
    frame:SetBackdrop(frameBackdropInfo)
    frame:SetBackdropColor(color.r, color.g, color.b, 1 - addonTable.Config.Get("skins.dark.view_transparency"))
    addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
      if settingName == "skins.dark.view_transparency" then
        frame:SetBackdropColor(color.r, color.g, color.b, 1 - addonTable.Config.Get("skins.dark.view_transparency"))
      end
    end, frame)
    local r, g, b = addonTable.Skins.Lighten(color.r, color.g, color.b, 0.3)
    frame:SetBackdropBorderColor(r, g, b, 1)
    table.insert(toColor.backdrops, {backdrop = frame, bgAlpha = 0.7, borderAlpha = 1, borderLightened = 0.3})

    if tags.backpack then
      frame.TopButtons[1]:SetPoint("TOPLEFT", 1.5, -1)
    elseif tags.bank then
      frame.Character.TopButtons[1]:SetPoint("TOPLEFT", 1.5, -1)
    elseif tags.guild then
      frame.ToggleTabTextButton:SetPoint("TOPLEFT", 1.5, -1)
    end
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

addonTable.Skins.RegisterSkin(BAGANATOR_L_DARK, "dark", LoadSkin, SkinFrame, SetConstants, {
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
    default = 0.3,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SQUARE_ICONS,
    rightText = BAGANATOR_L_RELOAD_REQUIRED,
    option = "square_icons",
    default = false,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_HIDE_ICON_BACKGROUNDS,
    option = "empty_slot_background",
    default = false,
  },
})
