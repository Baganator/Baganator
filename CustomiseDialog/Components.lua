---@class addonTableBaganator
local addonTable = select(2, ...)
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

BaganatorHeaderMixin = {}

function BaganatorHeaderMixin:Init(details)
  self.Label:SetText(details.text);
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
  frame.KeepMoving = function()
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
      frame:SetScript("OnClick", function(self)
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
  for _, f in c.ScrollBox:EnumerateFrames() do
    if f:IsMouseOver() then
      return f, f:IsMouseOver(0, f:GetHeight()/2), f.indexValue
    end
  end
end

BaganatorCustomSliderMixin = {}

function BaganatorCustomSliderMixin:Init(details)
  Mixin(self, details)
  self.callback = self.callback or function(_) end

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
  dropdown.OnEntryClicked = function(_, _) end
  addonTable.Skins.AddFrame("Dropdown", dropdown)
  return dropdown
end

-- Dropdown for selecting and storing an option
function addonTable.CustomiseDialog.GetBasicDropdown(parent)
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
    frame.option = option.option
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
  frame.SetValue = function(_, _)
    dropdown:GenerateMenu()
    -- don't need to do anything as dropdown's onshow handles this
  end
  frame.Label = label
  frame.DropDown = dropdown
  frame:SetHeight(40)
  addonTable.Skins.AddFrame("Dropdown", frame.DropDown)

  return frame
end
