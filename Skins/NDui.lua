---@class addonTableBaganator
local addonTable = select(2, ...)

local B, _, _, DB

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
  ScrollButton = function(button, tags)
    button:ClearNormalTexture()
    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(DB.ArrowUp)
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
    button:SetScript("OnEnter", B.Texture_OnEnter)
    button:SetScript("OnLeave", B.Texture_OnLeave)
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
  CategoryLabel = function(button)
    button:GetFontString():SetTextColor(DB.r, DB.g, DB.b)
  end,
  CategorySectionHeader = function(button)
    button:GetFontString():SetTextColor(DB.r, DB.g, DB.b)
  end,
  Dropdown = function(button)
    B.ReskinDropDown(button)
  end,
  Dialog = function(frame)
    B.StripTextures(frame)
    B.SetBD(frame)
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

  B, C, L, DB = unpack(NDui or AuroraClassic)
end

if addonTable.Skins.IsAddOnLoading("NDui") or addonTable.Skins.IsAddOnLoading("AuroraClassic") then
  addonTable.Skins.RegisterSkin(addonTable.Locales.NDUI, "ndui", LoadSkin, SkinFrame, SetConstants, {}, true)
end
