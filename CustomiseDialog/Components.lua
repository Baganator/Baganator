BaganatorCheckBoxMixin = {}
function BaganatorCheckBoxMixin:Init(details)
  Mixin(self, details)
  self.CheckBox:SetText(self.text)
  if self.root then
    self.CheckBox:SetScript("OnClick", function()
      Baganator.Config.Get(self.root)[self.option] = self.CheckBox:GetChecked()
    end)
  else
    self.CheckBox:SetScript("OnClick", function()
      Baganator.Config.Set(self.option, self.CheckBox:GetChecked())
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
  self.Slider.High:SetText(self.highText)
  self.Slider.Low:SetText(self.lowText)
  self.Slider:SetValueStep(1)
  self.Slider:SetObeyStepOnDrag(true)

  self.Slider:SetScript("OnValueChanged", function()
    local value = self.Slider:GetValue()
    if self.scale then
      value = value / self.scale
    else
    end
    Baganator.Config.Set(self.option, value)
    self.Slider.Text:SetText(self.valuePattern:format(math.floor(self.Slider:GetValue())))
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
  self.DropDown:SetupSelections(GetOptions(), 1)
  self.OnEntrySelected = function(_, option)
    Baganator.Config.Set(self.option, option.value)
  end
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
