local _, addonTable = ...

local B, C, L, DB

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local skinners = {
  ItemButton = function(bu)
    bu:SetNormalTexture(0)
    bu:SetPushedTexture(0)
    if bu.Background then bu.Background:SetAlpha(0) end
    bu:GetHighlightTexture():SetColorTexture(1, 1, 1, .25)
    bu.searchOverlay:SetOutside()

    bu.icon:SetTexCoord(unpack(DB.TexCoord))
    bu.bg = B.CreateBDFrame(bu.icon, .25)
    B.ReskinIconBorder(bu.IconBorder)

    local questTexture = bu.IconQuestTexture
    if questTexture then
      questTexture:SetDrawLayer("BACKGROUND")
      questTexture:SetSize(1, 1)
    end

    local hl = bu.SlotHighlightTexture
    if hl then
      hl:SetColorTexture(1, .8, 0, .5)
    end
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
    B.ReskinTab(button)
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
  CategoryLabel = function(btn)
    btn:GetFontString():SetTextColor(DB.r, DB.g, DB.b)
  end,
  CategorySectionHeader = function(btn)
    btn:GetFontString():SetTextColor(DB.r, DB.g, DB.b)
  end,
}

local function LoadSkin()
  if C_AddOns.IsAddOnLoaded("Masque") then
    local Masque = LibStub("Masque", true)
    local masqueGroup = Masque:Group("Baganator", "Bag")
    if not masqueGroup.db.Disabled then
      skinners.ItemButton = function() end
    end
  end

  local function SkinFrame(details)
    local func = skinners[details.regionType]
    if func then
      func(details.region, details.tags and ConvertTags(details.tags) or {})
    end
  end

  EventUtil.ContinueAfterAllEvents(function()
    B, C, L, DB = unpack(NDui)
    addonTable.Skins.RegisterListener(SkinFrame)

    for _, details in ipairs(addonTable.Skins.GetAllFrames()) do
      SkinFrame(details)
    end
  end, "PLAYER_LOGIN")
end

if (select(4, C_AddOns.GetAddOnInfo("NDui"))) then
  addonTable.Skins.RegisterSkin(BAGANATOR_L_NDUI, "ndui", LoadSkin, {}, true)
end
