CharacterSelectSidebarMixin = {}

function CharacterSelectSidebarMixin:OnLoad()
  self:SetTitle(BAGANATOR_L_ALL_CHARACTERS)

  local function UpdateForSelection(frame)
    if frame:GetText() ~= self.selectedCharacter then
      frame:Enable()
      frame:GetFontString():SetTextColor(1, 1, 1)
    else
      frame:Disable()
      frame:GetFontString():SetTextColor(0, 1, 0)
    end
  end

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(20)
  view:SetElementInitializer("Button", function(frame, elementData)
    frame:SetNormalFontObject(GameFontHighlight)
    --local fs = frame:CreateFontString(nil, nil, "GameFontHighlight")
    frame:SetText(elementData)
    --fs:SetAllPoints()
    frame:SetScript("OnClick", function()
      Baganator.CallbackRegistry:TriggerEvent("CharacterSelect", elementData)
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
  local character = Baganator.Utilities.GetAllCharacters(self.SearchBox:GetText())
  local justNames = {}
  for _, details in ipairs(characters) do
    table.insert(justNames, details.fullName)
  end
  self.ScrollBox:SetDataProvider(CreateDataProvider(justNames))
end

function CharacterSelectSidebarMixin:OnShow()
  self:UpdateList()
end
