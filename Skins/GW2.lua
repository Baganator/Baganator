---@class addonTableBaganator
local addonTable = select(2, ...)
local GW

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local function AddHeader(frame, texture)
  frame:GwStripTextures()
  GW.CreateFrameHeaderWithBody(frame, frame:GetTitleText(), texture, {})
  frame.gwHeader:ClearAllPoints()
  frame.gwHeader:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -25)
  frame.gwHeader:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -25)
  ;(frame.CloseButton.GwSkinButton or frame.CloseButton.SkinButton)(frame.CloseButton, true)
  frame.CloseButton:SetPoint("TOPRIGHT", -10, 4)
  frame.CloseButton:SetSize(20, 20)
end

local function SkinContainerFrame(frame, topButtons, topRightButtons)
  AddHeader(frame, "Interface/AddOns/GW2_UI/textures/bag/bagicon")

  frame:GetTitleText():ClearAllPoints()
  frame:GetTitleText():SetPoint("BOTTOMLEFT", frame.gwHeader, "BOTTOMLEFT", 35, 10)

  frame.gwHeader.windowIcon:ClearAllPoints()
  frame.gwHeader.windowIcon:SetPoint("CENTER", frame, "TOPLEFT", -16, 0)
  frame.gwHeader.windowIcon:SetSize(84, 84)

  frame.footer = frame:CreateTexture(nil, "BACKGROUND", nil, 7)
  frame.footer:SetTexture("Interface/AddOns/GW2_UI/textures/bag/bagfooter")
  frame.footer:SetHeight(55)
  frame.footer:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 30)
  frame.footer:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 30)

  frame.panelLeft = frame:CreateTexture(nil, "BACKGROUND", nil, 7)
  frame.panelLeft:SetTexture("Interface/AddOns/GW2_UI/textures/bag/bagleftpanel")
  frame.panelLeft:SetWidth(40)
  frame.panelLeft:SetPoint("TOPRIGHT", frame, "TOPLEFT", 0, 25)
  frame.panelLeft:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 0, 25)

  frame.borderBottomRight = frame:CreateTexture(nil, "BORDER")
  frame.borderBottomRight:SetTexture("Interface/AddOns/GW2_UI/textures/bag/bottom-right")
  frame.borderBottomRight:SetSize(128, 128)
  frame.borderBottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

  frame:SetHitRectInsets(-40, 0, -15, 0)
  frame:SetClampRectInsets(-40, 0, 15, 0)

  local buttonFrameOffset = 0
  if Baganator.Constants.IsRetail then
    buttonFrameOffset = 6
  end
  hooksecurefunc(frame.SearchWidget, "SetSpacing", function(_, sideSpacing)
    frame.SearchWidget:ClearAllPoints()
    frame.SearchWidget.SearchBox:SetPoint("RIGHT", frame, -sideSpacing - (frame.SearchWidget.showButtons and 106 or 0), 0)
    frame.SearchWidget.SearchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", buttonFrameOffset, - 28)
  end)
  frame.SearchWidget.SearchBox:SetHeight(22)

  local buttonOffsetX = -36
  local originalOffsetY = -30
  local buttonOffsetY = originalOffsetY
  local buttonHeight = topButtons[1]:GetHeight()
  local lastButtonsEnd = 0

  for index, _ in ipairs(topButtons) do
    local button = topButtons[index]
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", buttonOffsetX, buttonOffsetY)
    buttonOffsetY = buttonOffsetY - buttonHeight - 5
    lastButtonsEnd = math.abs(buttonOffsetY)
  end

  local function SetupRightButtons()
    if not frame:IsVisible() then
      return
    end
    local buttonOffsetYForRight = buttonOffsetY - 40
    if not topButtons[1]:IsVisible() then
      buttonOffsetYForRight = originalOffsetY
    end
    for index = #topRightButtons, 1, -1 do
      local button = topRightButtons[index]
      if button:IsShown() then
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", buttonOffsetX, buttonOffsetYForRight)
        buttonOffsetYForRight = buttonOffsetYForRight - buttonHeight - 5
      end
    end
    lastButtonsEnd = math.abs(buttonOffsetYForRight)
  end

  hooksecurefunc(frame, "SetSize", function(_, _, height)
    local missingHeight = lastButtonsEnd - frame:GetHeight()
    if missingHeight > 0 then
      frame:SetHeight(height + missingHeight)
    end
  end)

  topButtons[1]:HookScript("OnShow", function()
    SetupRightButtons()
  end)

  topButtons[1]:HookScript("OnHide", function()
    SetupRightButtons()
  end)

  if frame.ButtonVisibility then
    hooksecurefunc(frame.ButtonVisibility, "Update", SetupRightButtons)
  end

  frame.backgroundMask = UIParent:CreateMaskTexture()
  frame.backgroundMask:SetPoint("TOPLEFT", frame, "TOPLEFT", -64, 64)
  frame.backgroundMask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT",-64, 0)
  frame.backgroundMask:SetTexture(
      "Interface/AddOns/GW2_UI/textures/masktest",
      "CLAMPTOBLACKADDITIVE",
      "CLAMPTOBLACKADDITIVE"
  )

  frame.tex:AddMaskTexture(frame.backgroundMask)
  frame.panelLeft:AddMaskTexture(frame.backgroundMask)
  frame.borderBottomRight:AddMaskTexture(frame.backgroundMask)
  frame.footer:AddMaskTexture(frame.backgroundMask)

  Baganator.CallbackRegistry:RegisterCallback("ResetFramePositions", function()
    C_Timer.After(0, function()
      if frame:GetLeft() < 60 then
        frame:SetPoint("LEFT", 60, 0)
        frame:OnDragStop()
      end
    end)
  end)
end

local function SetupIconButton(button, texture)
  if button.Icon2 then
    button.Icon2:Hide()
  end
  button:SetSize(30, 30)
  button.Icon:SetSize(30, 30)
  button.Left:Hide()
  button.Right:Hide()
  button.Middle:Hide()
  button:ClearHighlightTexture()
  button:SetHighlightTexture(texture)
  button:GetHighlightTexture():SetTexCoord(0,1,0,1)
  button.Icon:SetTexture(texture)
  button.Icon:SetTexCoord(0,1,0,1)
end

local hidden = CreateFrame("Frame")
hidden:Hide()

local skinners = {
  ItemButton = function(frame, tags)
    frame.bgrGW2SkinHooked = true
    if not tags.containerBag then
      frame.SlotBackground:SetParent(GW.HiddenFrame)
    end
    frame.SlotBackground:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    -- Fix for GW2 assuming named frames have a named cooldown
    if frame:GetName() and not _G[frame:GetName().."Cooldown"] then
      CreateFrame("Cooldown", frame:GetName().."Cooldown", frame)
    end
    GW.SkinBagItemButton(frame, 37)
    -- Ensure item icon and border is set GW2 style
    if frame.SetItemButtonQuality then
      hooksecurefunc(frame, "SetItemButtonQuality", GW.SetBagItemButtonQualitySkin)
    end
    if addonTable.Constants.IsEra then
      local questTexture = frame.IconQuestTexture or frame:GetName() and _G[frame:GetName() .. "IconQuestTexture"]
      if questTexture then
        questTexture:SetParent(hidden)
      end
    end
    -- Show white border if none is shown, like default GW2
    if Baganator.Constants.IsClassic and frame.SetItemDetails then
      hooksecurefunc(frame, "SetItemDetails", function(_, details)
        if details.itemID and not frame.IconBorder:IsShown() then
          frame.IconBorder:Show()
        end
      end)
    end
  end,
  IconButton = function(button, tags)
    if tags.sort then
      SetupIconButton(button, "Interface/AddOns/GW2_UI/textures/icons/BagMicroButton-Up")
    elseif tags.bank then
      SetupIconButton(button, "Interface/AddOns/GW2_UI/textures/icons/microicons/CollectionsMicroButton-Up")
    elseif tags.guildBank then
      SetupIconButton(button, "Interface/AddOns/GW2_UI/textures/icons/microicons/GuildMicroButton-Up")
    elseif tags.allCharacters then
      SetupIconButton(button, "Interface/AddOns/GW2_UI/textures/icons/microicons/LFDMicroButton-Up")
    elseif tags.customise then
      SetupIconButton(button, "Interface/AddOns/GW2_UI/textures/icons/microicons/MainMenuMicroButton-Up")
    elseif tags.bagSlots then
      SetupIconButton(button, "Interface/AddOns/GW2_UI/textures/icons/microicons/BagMicroButton-Up")
    else
      button.Icon:SetDrawLayer("OVERLAY")
      if button.Icon2 then
        button.Icon2:SetDrawLayer("OVERLAY")
      end
      button.Left:Hide()
      button.Right:Hide()
      button.Middle:Hide()
      button:ClearHighlightTexture()
    end
  end,
  Button = function(frame)
    frame:GwSkinButton(false, true, false, false, false, false)
  end,
  ButtonFrame = function(frame, tags)
    frame:SetFrameStrata("HIGH")
    if tags.backpack then
      frame.BagSlots:ClearAllPoints()
      frame.BagSlots:SetPoint("BOTTOM", frame, "TOP", 0, 8)
      frame.BagSlots:SetPoint("LEFT", frame:GetTitleText(), "RIGHT")
      SkinContainerFrame(frame, frame.TopButtons, frame.AllFixedButtons)
    elseif tags.bank then
      if frame.Character.BagSlots then
        frame.Character.BagSlots:ClearAllPoints()
        frame.Character.BagSlots:SetPoint("BOTTOM", frame, "TOP", 0, 8)
        frame.Character.BagSlots:SetPoint("LEFT", frame:GetTitleText(), "RIGHT")
      end
      SkinContainerFrame(frame, frame.Character.TopButtons, frame.AllFixedButtons)
    elseif tags.guild then
      frame.LogsFrame:SetFrameStrata("DIALOG")
      frame.TabTextFrame:SetFrameStrata("DIALOG")
      SkinContainerFrame(frame, {frame.ToggleTabTextButton, frame.ToggleTabLogsButton, frame.ToggleGoldLogsButton}, frame.AllFixedButtons)
    elseif tags.customise then
      AddHeader(frame, "Interface/AddOns/GW2_UI/textures/character/settings-window-icon")
      frame.Tabs[1]:SetPoint("TOPLEFT", 65, -25)
      frame:HookScript("OnShow", function(self)
        local tabsWidth = self.Tabs[#self.Tabs]:GetRight() - self.Tabs[1]:GetLeft()

        self:SetWidth(math.max(self:GetWidth(), tabsWidth + 90))
      end)
    else
      GW.HandlePortraitFrame(frame, true)
    end
  end,
  SearchBox = function(frame)
    if GW.SkinBagSearchBox then
      GW.SkinBagSearchBox(frame)
    else
      frame:SetFont(UNIT_NAME_FONT, 14, "")
      GW.SkinTextBox(frame.Middle, frame.Left, frame.Right)
      frame:SetHeight(26)
      frame.searchIcon:Hide()
      frame:SetFont(UNIT_NAME_FONT, 14, "")
      frame.Instructions:SetFont(UNIT_NAME_FONT, 14, "")
      frame.Instructions:SetTextColor(178 / 255, 178 / 255, 178 / 255)
    end
  end,
  EditBox = function(frame)
    GW.SkinTextBox(frame.Middle, frame.Left, frame.Right)
  end,
  TabButton = function(frame)
    if GW.HandleTabs then
      GW.HandleTabs(frame, false)
    else
      frame:GwStripTextures()
      frame:GwSkinButton(false, true, false, false, false, false)
      if Baganator.Constants.IsRetail then
        -- Work around GW2 bug on retail where the hover texture doesn't hide
        -- properly
        frame:HookScript("OnDisable", function()
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnShow", function()
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnEnable", function()
          frame.hover:SetAlpha(0)
        end)
      end
    end
  end,
  TopTabButton = function(frame)
    if GW.HandleTabs then
      GW.HandleTabs(frame, true)
    else
      frame:GwStripTextures()
      frame:GwSkinButton(false, true, false, false, false, false)
      if Baganator.Constants.IsRetail then
        -- Work around GW2 bug on retail where the hover texture doesn't hide
        -- properly
        frame:HookScript("OnDisable", function()
          frame.hover:SetAlpha(0)
        end)
        frame:HookScript("OnEnable", function()
          frame.hover:SetAlpha(0)
        end)
      end
    end
  end,
  SideTabButton = function(_)
    --Not available in GW2
  end,
  TrimScrollBar = function(frame)
    GW.HandleTrimScrollBar(frame)
  end,
  CheckBox = function(frame)
    frame:GwSkinCheckButton()
    frame:SetPoint("TOP", 0, -12)
    frame:SetSize(15, 15)
  end,
  Slider = function(frame)
    frame:GwSkinSliderFrame()
    frame:GetThumbTexture():SetSize(16, 16)
    frame.tex:SetDrawLayer("ARTWORK")
    frame.tex:SetPoint("TOPLEFT", 0, 2)
    frame.tex:SetPoint("BOTTOMRIGHT", 0, -2)
  end,
  InsetFrame = function(frame)
    frame.Bg:Hide()
    frame:GwStripTextures()
    if frame.NineSlice then
      frame.NineSlice:Hide()
    end
    if GW.BackdropTemplates and GW.BackdropTemplates.ColorableBorderOnly then
      Mixin(frame, BackdropTemplateMixin)
      frame:SetBackdrop(GW.BackdropTemplates.ColorableBorderOnly)
      frame:SetBackdropBorderColor(0, 0, 0, 1)
    end
  end,
  Divider = function(tex)
    tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", 0, 0)
    tex:SetHeight(1)
    tex:SetColorTexture(1, 0.93, 0.73, 0.45)
  end,
  CategoryLabel = function(btn)
    btn:GetFontString():SetFont(UNIT_NAME_FONT, 11)
    btn:GetFontString():SetTextColor(1, 1, 1)
  end,
  CategorySectionHeader = function(btn)
    btn:GetFontString():SetFont(UNIT_NAME_FONT, 14)
    btn:GetFontString():SetTextColor(1, 1, 1)
    btn.arrow:SetDesaturated(true)
  end,
  CornerWidget = function(frame)
    if frame:IsObjectType("FontString") then
      frame:SetFont(UNIT_NAME_FONT, 12, "THINOUTLINED")
    end
  end,
  Dropdown = function(button)
    button:GwHandleDropDownBox(nil, nil, nil)
    button:OnEnter() -- Fix text colour
    button.Text:SetPoint("LEFT", 10, -2)
    button.backdrop:SetPoint("TOPLEFT", -5, 0)
    button:SetHitRectInsets(-5, 0, 0, 0)
  end,
  Dialog = function(frame)
    frame:GwStripTextures()
    if frame.NineSlice then
      frame.NineSlice:Hide()
    end
    frame:GwCreateBackdrop()
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(frame)
    tex:SetTexture("Interface/AddOns/GW2_UI/textures/party/manage-group-bg")
    frame.tex = tex
  end,
}

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and #details.tags > 0 and ConvertTags(details.tags) or {})
  end
end

local function DisableGW2Defaults()
  GW.settings.BAG_SHOW_EQUIPMENT_SET_NAME =  false
  GW.settings.BAG_ITEM_JUNK_ICON_SHOW =  false
  GW.settings.BAG_ITEM_UPGRADE_ICON_SHOW =  false
  -- needs to be on otherwise hides border used in Baganator
  GW.settings.BAG_ITEM_QUALITY_BORDER_SHOW =  true
  GW.settings.BAG_PROFESSION_BAG_COLOR =  false
  GW.settings.BAG_SHOW_ILVL =  false
end

local function HideBagButtons()
  MainMenuBarBackpackButton:SetParent(GW.HiddenFrame)
  for i = 0, 3 do
      _G["CharacterBag" .. i .. "Slot"]:SetParent(GW.HiddenFrame)
  end
  if CharacterReagentBag0Slot then
    CharacterReagentBag0Slot:SetParent(GW.HiddenFrame)
  end
  if BagBarExpandToggle then
    BagBarExpandToggle:SetParent(GW.HiddenFrame)
  end
end

local function SetConstants()
  addonTable.Constants.ButtonFrameOffset = 0
end

local function LoadSkin()
  GW = GW2_ADDON

  if addonTable.Utilities.IsMasqueApplying() then
    skinners.ItemButton = function(frame, tags)
      if not tags.containerBag then
        frame.SlotBackground:SetParent(hidden)
      end
    end
  else
    hooksecurefunc("SetItemButtonQuality", function(button, ...)
      if button.bgrGW2SkinHooked then
        GW.SetBagItemButtonQualitySkin(button, ...)
      end
    end)
  end

  DisableGW2Defaults()
  HideBagButtons()
end

if addonTable.Skins.IsAddOnLoading("GW2_UI") then
  addonTable.Skins.RegisterSkin(addonTable.Locales.GW2_UI, "gw2_ui", LoadSkin, SkinFrame, SetConstants, {}, true)
end
