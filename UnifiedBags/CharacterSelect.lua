CharacterSelectSidebarMixin = {}

local arrowRight = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\arrow", 22, 22, 13, 13, 1, 0, 0, 1)
local arrowLeft = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\arrow", 22, 22, 13, 13, 0, 1, 0, 1)

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
