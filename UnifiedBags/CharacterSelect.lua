CharacterSelectSidebarMixin = {}

local arrowRight = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\arrow", 22, 22, 13, 13, 1, 0, 0, 1)
local arrowLeft = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\arrow", 22, 22, 13, 13, 0, 1, 0, 1)

local hiddenColor = CreateColor(1, 0, 0)
local shownColor = CreateColor(0, 1, 0)

function CharacterSelectSidebarMixin:OnLoad()
  self:SetTitle(BAGANATOR_L_ALL_CHARACTERS)

  local function UpdateForSelection(frame)
    if frame.fullName ~= self.selectedCharacter then
      frame:Enable()
      frame:SetText(frame.fullName)
    else
      frame:Disable()
      frame:SetText(arrowLeft .. " " .. frame.fullName .. " " .. arrowRight)
    end
  end

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(20)
  view:SetElementInitializer("Button", function(frame, elementData)
    frame:SetNormalFontObject(GameFontHighlight)
    --local fs = frame:CreateFontString(nil, nil, "GameFontHighlight")
    frame.fullName = elementData.fullName
    frame:SetText(frame.fullName)
    if elementData.className then
      local classColor = RAID_CLASS_COLORS[elementData.className]
      frame:GetFontString():SetTextColor(classColor.r, classColor.g, classColor.b)
    else
      frame:GetFontString():SetTextColor(1, 1, 1)
    end
    --fs:SetAllPoints()
    frame:SetScript("OnClick", function()
      Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", elementData.fullName)
    end)
    frame.UpdateHideVisual = function()
      if BAGANATOR_DATA.Characters[frame.fullName].details.hidden then
        frame.HideButton:GetNormalTexture():SetVertexColor(hiddenColor.r, hiddenColor.g, hiddenColor.b)
      else
        frame.HideButton:GetNormalTexture():SetVertexColor(shownColor.r, shownColor.g, shownColor.b)
      end
    end
    if not frame.HideButton then
      frame.HideButton = CreateFrame("Button", nil, frame)
      frame.HideButton:SetNormalAtlas("UI_Editor_Eye_Icon")
      frame.HideButton:SetPoint("TOPLEFT", 8, -2.5)
      frame.HideButton:SetSize(15, 15)
      frame.HideButton:SetScript("OnClick", function()
        BAGANATOR_DATA.Characters[frame.fullName].details.hidden = not BAGANATOR_DATA.Characters[frame.fullName].details.hidden
        GameTooltip:Hide()
        frame:UpdateHideVisual()
      end)
      frame.HideButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.HideButton, "ANCHOR_RIGHT")
        if BAGANATOR_DATA.Characters[frame.fullName].details.hidden then
          GameTooltip:SetText(BAGANATOR_L_SHOW_IN_TOOLTIPS)
        else
          GameTooltip:SetText(BAGANATOR_L_HIDE_IN_TOOLTIPS)
        end
        GameTooltip:Show()
        frame.HideButton:SetAlpha(0.5)
      end)
      frame.HideButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
        frame.HideButton:SetAlpha(1)
      end)
    end
    frame:UpdateHideVisual()
    UpdateForSelection(frame)
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)

  Baganator.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    self.selectedCharacter = character
    for _, frame in self.ScrollBox:EnumerateFrames() do
      UpdateForSelection(frame)
    end
  end)

  self.SearchBox:HookScript("OnTextChanged", function()
    self:UpdateList()
  end)
end

function CharacterSelectSidebarMixin:UpdateList()
  local characters = Baganator.Utilities.GetAllCharacters(self.SearchBox:GetText())
  self.ScrollBox:SetDataProvider(CreateDataProvider(characters))
end

function CharacterSelectSidebarMixin:OnShow()
  self:UpdateList()
end
