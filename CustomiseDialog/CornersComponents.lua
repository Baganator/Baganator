BaganatorCustomiseCornersSelectionPopoutButtonMixin = CreateFromMixins(CallbackRegistryMixin, EventButtonMixin);

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnLoad()
  CallbackRegistryMixin.OnLoad(self);

  self.Label = self:CreateFontString(nil, nil, "GameFontNormal")
  self.Label:SetAllPoints()
  self.Label:SetSize(250, 20)

  self.parent = self:GetParent();

  self.Popout.logicalParent = self;

  self.buttonPool = CreateFramePool("BUTTON", self.Popout, "SettingsSelectionPopoutEntryTemplate");
  self.initialAnchor = AnchorUtil.CreateAnchor("TOPLEFT", self.Popout, "TOPLEFT", 6, -12);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:SetText(text)
  self.Label:SetText(text)
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:HandlesGlobalMouseEvent(buttonID, event)
  return event == "GLOBAL_MOUSE_DOWN" and buttonID == "LeftButton";
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnEnter()
  if not self.Popout:IsShown() then
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox-hover");
  end
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnLeave()
  if not self.Popout:IsShown() then
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox");
  end
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:SetEnabled_(enabled)
  self:SetEnabled(enabled);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnPopoutShown()
  if self.parent.OnPopoutShown then
    self.parent:OnPopoutShown();
  end
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnHide()
  self:HidePopout();
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:HidePopout()
  self.Popout:Hide();

  if GetMouseFocus() == self then
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox-hover");
  else
    self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox");
  end

  self.HighlightTexture:SetAlpha(0);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnClick()
  self:TogglePopout()
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:ShowPopout()
  if self.popoutNeedsUpdate then
    self:UpdatePopout();
  end
  SelectionPopouts:CloseAll();

  self.Popout:Show();
  self.NormalTexture:SetAtlas("charactercreate-customize-dropdownbox-open");
  self.HighlightTexture:SetAlpha(0.2);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:SetPopoutStrata(strata)
  self.Popout:SetFrameStrata(strata);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:SetupOptions(entries, values)
  local container = Settings.CreateControlTextContainer();
  for index, option in ipairs(entries) do
    container:Add(values[index], option);
  end

  self.selections = container:GetData()
  self.selectedIndex = selectedIndex;

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

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:GetMaxPopoutStride()
  local maxPopoutHeight = self.parent.GetMaxPopoutHeight and self.parent:GetMaxPopoutHeight() or nil;
  if maxPopoutHeight then
    local selectionHeight = 20;
    return math.floor(maxPopoutHeight / selectionHeight);
  end
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:UpdatePopout()
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
    maxDetailsWidth = math.max(maxDetailsWidth, button.SelectionDetails:GetWidth());

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

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:GetSelections()
  return self.selections;
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:GetCurrentSelectedData()
  local selections = self:GetSelections();
  return selections[self.selectedIndex];
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:UpdateButtonDetails()
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:TogglePopout()
  local showPopup = not self.Popout:IsShown();
  if showPopup then
    self:ShowPopout();
  else
    self:HidePopout();
  end
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:FindIndex(predicate)
  return FindInTableIf(self:GetSelections(), predicate);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:IsDataMatch(data1, data2)
  return data1 == data2;
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnEntryClicked(entryData)
  self:HidePopout();

  PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON);
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnEntryMouseEnter(entry)
  if self.parent.OnEntryMouseEnter then
    self.parent:OnEntryMouseEnter(entry);
  end
end

function BaganatorCustomiseCornersSelectionPopoutButtonMixin:OnEntryMouseLeave(entry)
  if self.parent.OnEntryMouseLeave then
    self.parent:OnEntryMouseLeave(entry);
  end
end
