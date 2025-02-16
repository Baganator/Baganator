local _, addonTable = ...

local B, C, L, DB

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local icons = {}
local frame = CreateFrame("Frame")
frame:RegisterEvent("UI_SCALE_CHANGED")
frame:SetScript("OnEvent", function()
  C_Timer.After(0, function()
    for _, frame in ipairs(icons) do
      local c1, c2, c3, c4 = frame.bg:GetBackdropBorderColor()
      frame.bg:SetIgnoreParentScale(true)
      frame.bg:SetScale(UIParent:GetScale())
      frame.bg:SetBackdropBorderColor(c1, c2, c3, c4)
    end
  end)
end)

local hidden = CreateFrame("Frame")
hidden:Hide()
local skinners = {
  ItemButton = function(button, tags)
    if not tags.containerBag then
      button.SlotBackground:SetParent(hidden)
    end
    button:SetNormalTexture(0)
    button:SetPushedTexture(0)
    if button.Background then button.Background:SetAlpha(0) end
    button:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
    button.searchOverlay:SetOutside()

    button.icon:SetTexCoord(unpack(DB.TexCoord))
    button.SlotBackground:SetTexCoord(unpack(DB.TexCoord))
    button.bg = B.CreateBDFrame(button.icon, .25)
    B.ReskinIconBorder(button.IconBorder)
    button.bg:SetBackdropColor(.3,.3,.3,.3)

    local questTexture = button.IconQuestTexture
    if questTexture then
      questTexture:SetDrawLayer("BACKGROUND")
      questTexture:SetSize(1, 1)
    end

    local hl = button.SlotHighlightTexture
    if hl then
      hl:SetColorTexture(1, .8, 0, .5)
    end
    table.insert(icons, button)
    button.bg:SetIgnoreParentScale(true)
    button.bg:SetScale(UIParent:GetScale())
  end,
  IconButton = function(frame)
    B.Reskin(frame)
  end,
  Button = function(frame)
    B.Reskin(frame)
  end,
  ButtonFrame = function(frame)
    B.ReskinPortraitFrame(frame)
  end,
  SearchBox = function(frame)
    B.ReskinEditBox(frame)
  end,
  EditBox = function(frame)
    B.ReskinEditBox(frame)
  end,
  TabButton = function(frame)
    B.ReskinTab(frame)
  end,
  TopTabButton = function(frame)
    B.ReskinTab(frame)
  end,
  SideTabButton = function(button)
  	local icon = button.Icon

  	B.StripTextures(button)
  	button:SetNormalTexture(0)
  	button:SetPushedTexture(0)
  	button:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
  	button.SelectedTexture:SetTexture(DB.pushedTex)
    B.CreateBDFrame(button)
  	icon:SetTexCoord(unpack(DB.TexCoord))
  end,
  TrimScrollBar = function(frame)
    B.ReskinTrimScroll(frame)
  end,
  CheckBox = function(frame)
    B.ReskinCheck(frame)
  end,
  Slider = function(frame)
    B.ReskinSlider(frame)
  end,
  InsetFrame = function(frame)
    if frame.NineSlice then
      frame.NineSlice:SetAlpha(0)
    end
  end,
  CornerWidget = function(frame, tags)
    if frame:IsObjectType("FontString") and BAGANATOR_ELVUI_USE_BAG_FONT then
      frame:FontTemplate(LSM:Fetch('font', E.db.bags.countFont), BAGANATOR_CONFIG["icon_text_font_size"], E.db.bags.countFontOutline)
    end

  end,
  CategoryLabel = function(button)
    button:GetFontString():SetTextColor(DB.r, DB.g, DB.b)
  end,
  CategorySectionHeader = function(button)
    button:GetFontString():SetTextColor(DB.r, DB.g, DB.b)
  end,
  Dropdown = function(button)
    B.ReskinDropDown(button)
  end
}

local function SetConstants()
  addonTable.Constants.ButtonFrameOffset = 0
end

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and ConvertTags(details.tags) or {})
  end
end

local function LoadSkin()
  if addonTable.Utilities.IsMasqueApplying() then
    skinners.ItemButton = function(frame, tags)
      if not tags.containerBag then
        frame.SlotBackground:SetParent(hidden)
      end
    end
  end

  B, C, L, DB = unpack(NDui)
end

if addonTable.Skins.IsAddOnLoading("NDui") then
  addonTable.Skins.RegisterSkin(BAGANATOR_L_NDUI, "ndui", LoadSkin, SkinFrame, SetConstants, {}, true)
end
