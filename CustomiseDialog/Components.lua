local _, addonTable = ...
BaganatorCheckBoxMixin = {}
function BaganatorCheckBoxMixin:OnLoad()
  if DoesTemplateExist("SettingsCheckBoxTemplate") then
    self.CheckBox = CreateFrame("CheckButton", nil, self, "SettingsCheckBoxTemplate")
  else
    self.CheckBox = CreateFrame("CheckButton", nil, self, "SettingsCheckboxTemplate")
  end
  self.CheckBox:SetPoint("LEFT", self, "CENTER", -35, 0)
  self.CheckBox:SetText(" ")
  self.CheckBox:SetNormalFontObject(GameFontHighlight)
  self.CheckBox:GetFontString():SetPoint("RIGHT", self, "CENTER", -50, 0)
  self.rightLabel = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.rightLabel:SetPoint("LEFT", self.CheckBox, "RIGHT", 15, 0)
end
function BaganatorCheckBoxMixin:Init(details)
  Mixin(self, details)
  self.CheckBox:SetText(self.text)
  addonTable.Skins.AddFrame("CheckBox", self.CheckBox)
  self.rightLabel:SetText(self.rightText or "")
  if self.root then
    self.CheckBox:SetScript("OnClick", function()
      addonTable.Config.Get(self.root)[self.option] = self.CheckBox:GetChecked()
    end)
  else
    self.CheckBox:SetScript("OnClick", function()
      addonTable.Config.Set(self.option, self.CheckBox:GetChecked())
    end)
  end
end

function BaganatorCheckBoxMixin:SetValue(value)
  self.CheckBox:SetChecked(value)
end

function BaganatorCheckBoxMixin:OnEnter()
  self.CheckBox:OnEnter()
end

function BaganatorCheckBoxMixin:OnLeave()
  self.CheckBox:OnLeave()
end

function BaganatorCheckBoxMixin:OnMouseUp()
  self.CheckBox:Click()
end

BaganatorSliderMixin = {}

function BaganatorSliderMixin:Init(details)
  Mixin(self, details)
  self.Slider:SetMinMaxValues(self.min, self.max)

  self.Slider:SetValueStep(1)
  self.Slider:SetObeyStepOnDrag(true)
  self.Label:SetText(self.text)
  self.valuePattern = self.valuePattern or "%s"

  addonTable.Skins.AddFrame("Slider", self.Slider)

  self.Slider:SetScript("OnValueChanged", function()
    local value = self.Slider:GetValue()
    if self.scale then
      value = value / self.scale
    else
    end
    addonTable.Config.Set(self.option, value)
    self.ValueText:SetText(self.valuePattern:format(math.floor(self.Slider:GetValue())))
  end)
end

function BaganatorSliderMixin:SetValue(value)
  self.Slider:SetValue(value * (self.scale or 1))
end

function BaganatorSliderMixin:OnMouseWheel(delta)
  self.Slider:SetValue(self.Slider:GetValue() + delta)
end

BaganatorDropDownMixin = {}

function BaganatorDropDownMixin:Init(details)
  Mixin(self, details)
  local function GetOptions()
    local container = Settings.CreateControlTextContainer();
    for index, option in ipairs(self.entries) do
      container:Add(self.values[index], option);
    end
    return container:GetData();
  end
  self.Label:SetText(self.text)
  self.DropDown:SetupSelections(GetOptions(), 1)
  self.OnEntrySelected = function(_, option)
    addonTable.Config.Set(self.option, option.value)
  end
  addonTable.Skins.AddFrame("DropDownWithPopout", self.DropDown)
end

function BaganatorDropDownMixin:SetValue(value)
  self.DropDown:SetSelectedIndex(tIndexOf(self.values, value))
end

BaganatorHeaderMixin = {}

function BaganatorHeaderMixin:Init(details)
  self.Label:SetText(details.text);
end

function BaganatorHeaderMixin:SetValue(value)
end

BaganatorCustomiseGetSelectionPopoutButtonMixin = CreateFromMixins(CallbackRegistryMixin, EventButtonMixin);

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnLoad()
  CallbackRegistryMixin.OnLoad(self);

  self.Label = self:CreateFontString(nil, nil, "GameFontNormal")
  self.Label:SetAllPoints()
  self.Label:SetSize(250, 20)

  self.parent = self:GetParent();

  self.Popout.logicalParent = self;

  self.buttonPool = CreateFramePool("BUTTON", self.Popout, "SettingsSelectionPopoutEntryTemplate");
  self.initialAnchor = AnchorUtil.CreateAnchor("TOPLEFT", self.Popout, "TOPLEFT", 6, -12);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:SetText(text)
  self.Label:SetText(text)
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:HandlesGlobalMouseEvent(buttonID, event)
  return event == "GLOBAL_MOUSE_DOWN" and buttonID == "LeftButton";
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnEnter()
  if not self.Popout:IsShown() then
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox-hover");
  end
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnLeave()
  if not self.Popout:IsShown() then
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox");
  end
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:SetEnabled_(enabled)
  self:SetEnabled(enabled);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnPopoutShown()
  if self.parent.OnPopoutShown then
    self.parent:OnPopoutShown();
  end
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnHide()
  self:HidePopout();
  self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox");
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:HidePopout()
  self.Popout:Hide();

  if (GetMouseFocus and GetMouseFocus() == self) or (GetMouseFoci and GetMouseFoci()[1]) == self then
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox-hover");
  else
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox");
  end

  self.HighlightTexture:SetAlpha(0);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnClick()
  self:TogglePopout()
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:ShowPopout()
  if self.popoutNeedsUpdate then
    self:UpdatePopout();
  end
  SelectionPopouts:CloseAll();

  self.Popout:Show();
  self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox-open");
  self.HighlightTexture:SetAlpha(0.2);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:SetPopoutStrata(strata)
  self.Popout:SetFrameStrata(strata);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:SetupOptions(entries, values)
  local container = Settings.CreateControlTextContainer();
  for index, option in ipairs(entries) do
    container:Add(values[index], option);
  end

  self.selections = container:GetData()
  self.selectedIndex = 1;

  if self.Popout:IsShown() then
    self:UpdatePopout();
  else
    self.popoutNeedsUpdate = true;
  end

  return self:UpdateButtonDetails();
end

local MAX_POPOUT_ENTRIES_FOR_1_COLUMN = 10;
local MAX_POPOUT_ENTRIES_FOR_2_COLUMNS = 24;
local MAX_POPOUT_ENTRIES_FOR_3_COLUMNS = 36;

local function getNumColumnsAndStride(numSelections, maxStride)
  local numColumns, stride;
  if numSelections > MAX_POPOUT_ENTRIES_FOR_3_COLUMNS then
    numColumns, stride = 4, math.ceil(numSelections / 4);
  elseif numSelections > MAX_POPOUT_ENTRIES_FOR_2_COLUMNS then
    numColumns, stride = 3, math.ceil(numSelections / 3);
  elseif numSelections > MAX_POPOUT_ENTRIES_FOR_1_COLUMN then
    numColumns, stride =  2, math.ceil(numSelections / 2);
  else
    numColumns, stride =  1, numSelections;
  end

  if maxStride and stride > maxStride then
    numColumns = math.ceil(numSelections / maxStride);
    stride = math.ceil(numSelections / numColumns);
  end

  return numColumns, stride;
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:GetMaxPopoutStride()
  local maxPopoutHeight = self.parent.GetMaxPopoutHeight and self.parent:GetMaxPopoutHeight() or nil;
  if maxPopoutHeight then
    local selectionHeight = 20;
    return math.floor(maxPopoutHeight / selectionHeight);
  end
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:UpdatePopout()
  self.buttonPool:ReleaseAll();

  local selections = self:GetSelections();
  local numColumns, stride = getNumColumnsAndStride(#selections, self:GetMaxPopoutStride());
  local buttons = {};

  local hasIneligibleChoice = false;
  local hasLockedChoice = false;
  for _, selectionData in ipairs(selections) do
    if selectionData.ineligibleChoice then
      hasIneligibleChoice = true;
    end
    if selectionData.isLocked then
      hasLockedChoice = true;
    end
  end

  local maxDetailsWidth = 0;
  for index, selectionInfo in ipairs(selections) do
    local button = self.buttonPool:Acquire();

    local isSelected = false--(index == self.selectedIndex);
    button:SetupEntry(selectionInfo, index, isSelected, numColumns > 1, hasIneligibleChoice, hasLockedChoice);
    maxDetailsWidth = math.max(maxDetailsWidth, button.SelectionDetails:GetWidth(), button.SelectionDetails.SelectionName:GetWidth() + 10);

    table.insert(buttons, button);
  end

  for _, button in ipairs(buttons) do
    button.SelectionDetails:SetWidth(maxDetailsWidth);
    button:Layout();
    button:Show();
  end

  if stride ~= self.lastStride then
    self.layout = AnchorUtil.CreateGridLayout(GridLayoutMixin.Direction.TopLeftToBottomRightVertical, stride);
    self.lastStride = stride;
  end

  AnchorUtil.GridLayout(buttons, self.initialAnchor, self.layout);

  self.popoutNeedsUpdate = false;
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:GetSelections()
  return self.selections;
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:GetCurrentSelectedData()
  local selections = self:GetSelections();
  return selections[self.selectedIndex];
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:UpdateButtonDetails()
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:TogglePopout()
  local showPopup = not self.Popout:IsShown();
  if showPopup then
    self:ShowPopout();
  else
    self:HidePopout();
  end
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:FindIndex(predicate)
  return FindInTableIf(self:GetSelections(), predicate);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:IsDataMatch(data1, data2)
  return data1 == data2;
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnEntryClicked(entryData)
  self:HidePopout();

  PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnEntryMouseEnter(entry)
  if self.parent.OnEntryMouseEnter then
    self.parent:OnEntryMouseEnter(entry);
  end
end

function BaganatorCustomiseGetSelectionPopoutButtonMixin:OnEntryMouseLeave(entry)
  if self.parent.OnEntryMouseLeave then
    self.parent:OnEntryMouseLeave(entry);
  end
end

function addonTable.CustomiseDialog.GetDraggable(callback, movedCallback)
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetSize(80, 20)
  frame.background = frame:CreateTexture(nil, "OVERLAY", nil)
  --frame.background:SetColorTexture(0.5, 0, 0.5, 0.5)
  frame.background:SetAtlas("auctionhouse-nav-button-highlight")
  frame.background:SetAllPoints()
  frame.text = frame:CreateFontString(nil, nil, "GameFontNormal")
  frame.text:SetAllPoints()
  frame:EnableMouse(true)
  frame:SetFrameStrata("DIALOG")
  frame:SetScript("OnMouseDown", function()
    callback()
    frame:Hide()
  end)
  frame:Hide()
  frame.KeepMoving = function(self)
    local uiScale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / uiScale, y / uiScale)
    if movedCallback then
      movedCallback()
    end
  end
  frame:SetScript("OnUpdate", frame.KeepMoving)

  return frame
end

function addonTable.CustomiseDialog.GetContainerForDragAndDrop(parent, callback)
  local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  addonTable.Skins.AddFrame("InsetFrame", container)
  container.ScrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  container.ScrollBox:SetPoint("TOPLEFT", 1, -3)
  container.ScrollBox:SetPoint("BOTTOMRIGHT", -1, 3)
  local scrollView = CreateScrollBoxListLinearView()
  scrollView:SetElementExtent(22)
  scrollView:SetElementInitializer("Button", function(frame, elementData)
    if not frame.initialized then
      frame.initialized = true
      frame:SetNormalFontObject(GameFontHighlight)
      frame:SetHighlightAtlas("auctionhouse-ui-row-highlight")
      frame:SetScript("OnClick", function(self, button)
        callback(self.value, self:GetText(), self.indexValue)
      end)
      frame.number = frame:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
      frame.number:SetPoint("LEFT", 5, 0)
    end
    frame.indexValue = container.ScrollBox:GetDataProvider():FindIndex(elementData)
    frame.number:SetText(frame.indexValue)
    frame.value = elementData.value
    frame:SetText(elementData.label)
  end)
  container.ScrollBar = CreateFrame("EventFrame", nil, container, "WowTrimScrollBar")
  container.ScrollBar:SetPoint("TOPRIGHT")
  container.ScrollBar:SetPoint("BOTTOMRIGHT")
  ScrollUtil.InitScrollBoxListWithScrollBar(container.ScrollBox, container.ScrollBar, scrollView)
  ScrollUtil.AddManagedScrollBarVisibilityBehavior(container.ScrollBox, container.ScrollBar)
  addonTable.Skins.AddFrame("TrimScrollBar", container.ScrollBar)

  return container
end

function addonTable.CustomiseDialog.GetMouseOverInContainer(c)
  for index, f in c.ScrollBox:EnumerateFrames() do
    if f:IsMouseOver() then
      return f, f:IsMouseOver(0, f:GetHeight()/2), f.indexValue
    end
  end
end

BaganatorCustomSliderMixin = {}

function BaganatorCustomSliderMixin:Init(details)
  Mixin(self, details)
  self.callback = self.callback or function() end

  self.Slider:SetMinMaxValues(self.min, self.max)
  self.Label:SetText(self.text)

  self.Slider:SetValueStep(1)
  self.Slider:SetObeyStepOnDrag(true)

  self.Slider:SetScript("OnValueChanged", function(_, _, userInput)
    local value = self.Slider:GetValue()
    if userInput then
      self.callback(value)
    end
    self.ValueText:SetText(self.valueToText[value])
  end)
  addonTable.Skins.AddFrame("Slider", self.Slider)
end

function BaganatorCustomSliderMixin:SetValue(value)
  self.Slider:SetValue(value)
end

function BaganatorCustomSliderMixin:GetValue()
  return self.Slider:GetValue()
end

function BaganatorCustomSliderMixin:OnMouseWheel(delta)
  if self.Slider:IsEnabled() then
    self.Slider:SetValue(self.Slider:GetValue() + delta)
    self.callback(self.Slider:GetValue())
  end
end

function BaganatorCustomSliderMixin:Disable()
  self.Slider:Disable()
end

function BaganatorCustomSliderMixin:Enable()
  self.Slider:Enable()
end

function addonTable.CustomiseDialog.GetDropdown(parent)
  if DoesTemplateExist("WowStyle1DropdownTemplate") then
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown.SetupOptions = function(_, entries, values)
      dropdown:SetupMenu(function(_, rootDescription)
        for index = 1, #entries do
          local entry, value = entries[index], values[index]
          rootDescription:CreateButton(entry, function() dropdown:OnEntryClicked({value = value, label = entry}) end)
        end
      end)
    end
    dropdown.disableSelectionText = true
    dropdown.OnEntryClicked = function() end
    return dropdown
  else
    local dropDown = CreateFrame("EventButton", nil, parent, "BaganatorCustomiseGetSelectionPopoutButtonTemplate")
    addonTable.Skins.AddFrame("DropDownWithPopout", dropDown)
    return dropDown
  end
end

-- Dropdown for selecting and storing an option
function addonTable.CustomiseDialog.GetBasicDropdown(parent)
  if DoesTemplateExist("SelectionPopoutButtonTemplate") then
    return CreateFrame("Frame", nil, parent, "BaganatorDropDownTemplate")
  else
    local frame = CreateFrame("Frame", nil, parent)
    local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(250)
    dropdown:SetPoint("LEFT", frame, "CENTER", -32, 0)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 20, 0)
    label:SetPoint("RIGHT", frame, "CENTER", -50, 0)
    label:SetJustifyH("RIGHT")
    frame:SetPoint("LEFT", 30, 0)
    frame:SetPoint("RIGHT", -30, 0)
    frame.Init = function(_, option)
      label:SetText(option.text)
      local entries = {}
      for index = 1, #option.entries do
        table.insert(entries, {option.entries[index], option.values[index]})
      end
      MenuUtil.CreateRadioMenu(dropdown, function(value)
        return addonTable.Config.Get(option.option) == value
      end, function(value)
        addonTable.Config.Set(option.option, value)
      end, unpack(entries))
    end
    frame.SetValue = function(_, value)
      dropdown:GenerateMenu()
      -- don't need to do anything as dropdown's onshow handles this
    end
    frame.DropDown = dropdown
    frame:SetHeight(40)

    return frame
  end
end
