---@class addonTableBaganator
local addonTable = select(2, ...)

local E
local S
local B
local LSM

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local icons = {}
local scaleMonitor = CreateFrame("Frame")
scaleMonitor:RegisterEvent("UI_SCALE_CHANGED")
scaleMonitor:SetScript("OnEvent", function()
  C_Timer.After(0, function()
    for _, frame in ipairs(icons) do
      local c1, c2, c3 = frame.backdrop:GetBackdropBorderColor()
      frame.backdrop:SetTemplate(nil, true, nil, nil, nil, nil, nil, true)
      frame.backdrop:SetIgnoreParentScale(true)
      frame.backdrop:SetScale(UIParent:GetScale())
      frame.backdrop:SetBackdropBorderColor(c1, c2, c3)
    end
  end)
end)

local hidden = CreateFrame("Frame")
hidden:Hide()
local skinners = {
  ItemButton = function(frame, tags)
    frame.bgrElvUISkin = true
    S:HandleItemButton(frame, true)
    S:HandleIconBorder(frame.IconBorder)
    frame.SlotBackground:Show()
    frame.SlotBackground:SetAllPoints()
    frame.SlotBackground:SetParent(frame.backdrop)
    frame.SlotBackground:SetDrawLayer("BACKGROUND", 7)
    frame.SlotBackground:SetColorTexture(unpack(E.media.backdropcolor))
    hooksecurefunc(frame.IconBorder, "SetVertexColor", function(_, r, g, b, a)
      if a == 0 then
        frame.backdrop.forcedBorderColors = nil
      else
        frame.backdrop.forcedBorderColors = {r, g, b, a}
      end
    end)
    if frame.SetItemButtonTexture then
      hooksecurefunc(frame, "SetItemButtonTexture", function()
        frame.icon:SetTexCoord(unpack(E.TexCoords))
      end)
    end
    if frame.JunkIcon then
      frame.JunkIcon:SetAtlas('bags-junkcoin', true)
    end
    -- Fix search overlay being removed by ElvUI in classic
    if Baganator.Constants.IsClassic then
      frame.searchOverlay:SetColorTexture(0, 0, 0, 0.8)
    end
    local cooldown = frame.Cooldown or frame:GetName() and _G[frame:GetName() .. "Cooldown"]
    if cooldown then
      E:RegisterCooldown(cooldown)
    end
    if frame.BGRUpdateQuests then
      local questTexture = frame:GetName() and _G[frame:GetName() .. "IconQuestTexture"] or frame.IconQuestTexture
      hooksecurefunc(frame, "BGRUpdateQuests", function()
        if questTexture:IsShown() then
          local textureID = questTexture:GetTexture()
          if textureID == 368362 then -- quest border only
            questTexture:SetTexture(E.Media.Textures.BagQuestIcon)
          else
            questTexture:Hide()
          end
          frame.IconBorder:SetVertexColor(unpack(B.QuestColors['questStarter']))
        end
      end)
    end
    table.insert(icons, frame)
    frame.backdrop:SetIgnoreParentScale(true)
    frame.backdrop:SetScale(UIParent:GetScale())
  end,
  IconButton = function(frame)
    S:HandleButton(frame)
  end,
  Button = function(frame)
    S:HandleButton(frame)
  end,
  ButtonFrame = function(frame)
    S:HandlePortraitFrame(frame)
  end,
  SearchBox = function(frame)
    S:HandleEditBox(frame)
  end,
  EditBox = function(frame)
    S:HandleEditBox(frame)
  end,
  TabButton = function(frame)
    S:HandleTab(frame)
  end,
  TopTabButton = function(frame)
    S:HandleTab(frame)
  end,
  SideTabButton = function(frame)
    frame.Background:Hide()

    frame.Icon:ClearAllPoints()
    frame.Icon:SetPoint("CENTER")
    frame.Icon:SetSize(25, 25)
    frame.Icon:SetTexCoord(unpack(E.TexCoords))

    frame.SelectedTexture:ClearAllPoints()
    frame.SelectedTexture:SetPoint("CENTER")
    frame.SelectedTexture:SetSize(25, 25)
    frame.SelectedTexture:SetTexture(E.Media.Textures.Melli)
    frame.SelectedTexture:SetVertexColor(1, .82, 0, 0.6)

    S:HandleTab(frame)
    frame:SetTemplate("Transparent")
  end,
  TrimScrollBar = function(frame)
    S:HandleTrimScrollBar(frame)
  end,
  ScrollButton = function(button, tags)
    button:ClearNormalTexture()
    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(E.Media.Textures.ArrowUp)
    tex:SetSize(16, 16)
    button:SetSize(16, 16)
    button:SetAlpha(1)
    if tags.left then
      tex:SetPoint("RIGHT")
      tex:SetRotation(math.pi/2)
    elseif tags.right then
      tex:SetPoint("LEFT")
      tex:SetRotation(-math.pi/2)
    end
    button.__texture = tex
    button:SetScript("OnEnter", function()
      tex:SetVertexColor(unpack(E.media.rgbvaluecolor))
    end)
    button:SetScript("OnLeave", function()
      tex:SetVertexColor(1, 1, 1)
    end)
  end,
  CheckBox = function(frame)
    S:HandleCheckBox(frame)
  end,
  Slider = function(frame)
    S:HandleSliderFrame(frame)
  end,
  InsetFrame = function(frame)
    if frame.NineSlice then
      frame.NineSlice:SetTemplate("Transparent")
    else
      S:HandleInsetFrame(frame)
    end
  end,
  CornerWidget = function(frame)
    if frame:IsObjectType("FontString") and addonTable.Config.Get("skins.elvui.use_bag_font") then
      frame:FontTemplate(LSM:Fetch('font', E.db.bags.countFont), 14, E.db.bags.countFontOutline)
    end
  end,
  Dropdown = function(button)
    S:HandleDropDownBox(button)
  end,
  Divider = function(tex)
    tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", 0, 0)
    tex:SetHeight(1)
    tex:SetColorTexture(1, 0.93, 0.73, 0.45)
  end,
  Dialog = function(frame)
    frame:StripTextures()
    frame:SetTemplate('Transparent')
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
  E = unpack(ElvUI)
  S = E:GetModule("Skins")
  B = E:GetModule('Bags')
  LSM = E.Libs.LSM

  if addonTable.Utilities.IsMasqueApplying() then
    skinners.ItemButton = function(frame, tags)
      if not tags.containerBag then
        frame.SlotBackground:SetParent(hidden)
      end
    end
  else
    hooksecurefunc("SetItemButtonTexture", function(frame)
      if frame.bgrElvUISkin then
        (frame.icon or frame.Icon):SetTexCoord(unpack(E.TexCoords))
      end
    end)
  end
end

if addonTable.Skins.IsAddOnLoading("ElvUI") then
  addonTable.Skins.RegisterSkin(addonTable.Locales.ELVUI, "elvui", LoadSkin, SkinFrame, SetConstants, {
    {
      type = "checkbox",
      text = addonTable.Locales.USE_EXPRESSWAY_FONT_ON_ITEMS,
      option = "use_bag_font",
      rightText = addonTable.Locales.RELOAD_REQUIRED,
      default = false,
    },
  }, true)
end
