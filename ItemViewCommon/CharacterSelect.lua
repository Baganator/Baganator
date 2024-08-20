local _, addonTable = ...
BaganatorCharacterSelectMixin = {}

local arrowLeft = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\arrow", 22, 22, 18, 18, 0, 1, 0, 1)

local function SetRaceIcon(frame)
  frame.RaceIcon = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  frame.RaceIcon:SetSize(15, 15)
  frame.RaceIcon:SetPoint("TOPLEFT", 32, -2.5)
  frame.RaceIcon:SetFont(frame.RaceIcon:GetFont(), 12, nil)
end

local function SetArrowIcon(frame)
  frame.ArrowIcon = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
  frame.ArrowIcon:SetSize(20, 15)
  frame.ArrowIcon:SetPoint("TOPLEFT", 8, -2.5)
  frame.ArrowIcon:SetFont(frame.ArrowIcon:GetFont(), 12, nil)
end

function BaganatorCharacterSelectMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()
  self:SetClampedToScreen(true)

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetUserPlaced(false)

  addonTable.Skins.AddFrame("ButtonFrame", self)
  addonTable.Skins.AddFrame("Button", self.ManageCharactersButton)

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if tIndexOf(addonTable.Config.VisualsFrameOnlySettings, settingName) ~= nil then
      if self:IsVisible() then
        addonTable.Utilities.ApplyVisuals(self)
      end
    end
  end)

  self:SetTitle(BAGANATOR_L_ALL_CHARACTERS)

  local function UpdateForSelection(frame)
    if frame.fullName ~= self.selectedCharacter then
      frame:Enable()
      frame.ArrowIcon:SetText("")
    else
      frame:Disable()
      frame.ArrowIcon:SetText(arrowLeft)
    end
  end

  local view = CreateScrollBoxListLinearView()
  view:SetElementExtent(20)
  view:SetElementInitializer("Button", function(frame, elementData)
    frame:SetHighlightAtlas("search-highlight")
    frame:SetNormalFontObject(GameFontHighlight)
    if not frame.RealmName then
      frame.RealmName = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
      frame.RealmName:SetTextColor(0.75, 0.75, 0.75)
      frame.RealmName:SetPoint("RIGHT", -15, 0)
      frame.RealmName:SetJustifyH("RIGHT")
      frame.RealmName:SetJustifyV("MIDDLE")
    end
    frame.fullName = elementData.fullName
    if not frame.RaceIcon then
      SetRaceIcon(frame)
    end
    if not frame.ArrowIcon then
      SetArrowIcon(frame)
    end
    if elementData.race then
      frame.RaceIcon:SetText(Syndicator.Utilities.GetCharacterIcon(elementData.race, elementData.sex))
    end
    frame:SetText(elementData.name)
    frame.RealmName:SetText(elementData.realm)
    frame:GetFontString():SetPoint("LEFT", 48, 0)
    frame:GetFontString():SetPoint("RIGHT", -15, 0)
    frame:GetFontString():SetJustifyH("LEFT")
    if elementData.className then
      local classColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[elementData.className]
      frame:GetFontString():SetTextColor(classColor.r, classColor.g, classColor.b)
    else
      frame:GetFontString():SetTextColor(1, 1, 1)
    end
    frame:SetScript("OnClick", function()
      addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", elementData.fullName)
    end)
    UpdateForSelection(frame)
  end)
  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)

  addonTable.CallbackRegistry:RegisterCallback("CharacterSelect", function(_, character)
    self.selectedCharacter = character
    for _, frame in self.ScrollBox:EnumerateFrames() do
      UpdateForSelection(frame)
    end
  end)
  Syndicator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, character)
    self:UpdateList()
    if character == self.selectedCharacter then
      addonTable.CallbackRegistry:TriggerEvent("CharacterSelect", Syndicator.API.GetCurrentCharacter())
    end
  end)

  self.SearchBox:HookScript("OnTextChanged", function()
    self:UpdateList()
  end)
  addonTable.Skins.AddFrame("SearchBox", self.SearchBox)
end

function BaganatorCharacterSelectMixin:UpdateList()
  local characters = addonTable.Utilities.GetAllCharacters(self.SearchBox:GetText())
  local currentCharacter = Syndicator.API.GetCurrentCharacter()
  local connectedRealms = Syndicator.Utilities.GetConnectedRealms()
  local currentCharacterData
  local currentRealms = {}
  local everythingElse = {}
  for _, data in ipairs(characters) do
    if data.fullName == currentCharacter then
      table.insert(currentRealms, 1, data)
    elseif tIndexOf(connectedRealms, data.realmNormalized) ~= nil then
      table.insert(currentRealms, data)
    else
      table.insert(everythingElse, data)
    end
  end
  tAppendAll(currentRealms, everythingElse)

  self.ScrollBox:SetDataProvider(CreateDataProvider(currentRealms), true)
end

function BaganatorCharacterSelectMixin:OnShow()
  addonTable.Utilities.ApplyVisuals(self)
  self:UpdateList()
end

function BaganatorCharacterSelectMixin:OnDragStart()
  if not addonTable.Config.Get(addonTable.Config.Options.LOCK_FRAMES) then
    self:StartMoving()
    self:SetUserPlaced(false)
  end
end

function BaganatorCharacterSelectMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
  local point, _, relativePoint, x, y = self:GetPoint(1)
  addonTable.Config.Set(addonTable.Config.Options.CHARACTER_SELECT_POSITION, {point, x, y})
end
