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
  IconButton = function(frame, tags)
    B.Reskin(frame)
    frame.__bg:SetParent(hidden)
    frame:ClearNormalTexture()
    frame:ClearPushedTexture()
    frame:ClearDisabledTexture()
    frame:ClearHighlightTexture()
    frame.Icon:SetAlpha(0.9)
    if tags.sort then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Sorting_White.png")
    elseif tags.bank then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Chest_White.png")
    elseif tags.guildBank then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Guild_White.png")
    elseif tags.allCharacters then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/All_Characters_White.png")
    elseif tags.customise then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Cog_White.png")
    elseif tags.bagSlots then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Bags_White.png")
    elseif tags.search then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Search_White.png")
    elseif tags.transfer then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Transfer_White.png")
    elseif tags.savedSearches then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/SavedSearches_White.png")
    elseif tags.currency then
      frame.Icon:SetTexture("Interface/AddOns/Baganator/Assets/Currency_White.png")
    else
      frame.Icon:SetDesaturated(true)
      frame.Icon:SetAlpha(1)
    end
    local highlight = frame:CreateTexture(nil, "OVERLAY")
    local atlas = frame.Icon:GetAtlas()
    if atlas then
      highlight:SetAtlas(atlas)
    else
      highlight:SetTexture(frame.Icon:GetTexture(), "BLEND")
    end
    highlight:SetParent(frame)
    highlight:SetDesaturated(true)
    highlight:SetVertexColor(21/255, 121/255, 190/255)
    highlight:SetSize(frame.Icon:GetSize())
    highlight:SetPoint(frame.Icon:GetPoint(1))
    highlight:Hide()
    frame:HookScript("OnEnter", function()
      if frame:IsEnabled() then
        highlight:Show()
      end
    end)
    frame:HookScript("OnLeave", function()
      highlight:Hide()
    end)
    frame:HookScript("OnDisable", function()
      highlight:Hide()
    end)
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
    frame.NineSlice:SetAlpha(0)
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
  end,
  Divider = function(tex)
    tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", 0, 0)
    tex:SetHeight(1)
    tex:SetColorTexture(0.93, 0.93, 0.93, 0.45)
  end,
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
