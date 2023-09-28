local WINDOW_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_LOCK_BAGS_BANKS_FRAMES,
    option = "lock_frames",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_CUSTOMISE_REMOVE_BORDERS,
    option = "no_frame_borders",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_SORT_BUTTON,
    option = "show_sort_button",
    isRetailOnly = true,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_CUSTOMISE_SHOW_TABS,
    option = "show_recents_tabs_main_view",
  },
  {
    type = "slider",
    min = 1,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    valuePattern = BAGANATOR_L_X_TRANSPARENCY,
    option = "view_alpha",
  },
  {
    type = "slider",
    min = 1,
    max = 24,
    lowText = "1",
    highText = "24",
    valuePattern = BAGANATOR_L_X_BAG_COLUMNS,
    option = "bag_view_width",
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    valuePattern = BAGANATOR_L_X_BANK_COLUMNS,
    option = "bank_view_width",
  },
}

local ICON_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_CUSTOMISE_EMPTY_SLOTS,
    option = "empty_slot_background",
    isRetailOnly = true,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_ITEM_LEVEL,
    option = "show_item_level",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_BOE_STATUS,
    option = "show_boe_status",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_BOA_STATUS,
    option = "show_boa_status",
    isRetailOnly = true,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_USE_ITEM_QUALITY_COLORS_FOR_ICON_TEXT,
    option = "icon_text_quality_colors",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_PAWN_UPGRADE_ARROW,
    option = "show_pawn_arrow",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_CAN_I_MOG_IT_ICON,
    option = "show_cimi_icon",
  },
  {
    type = "slider",
    min = 1,
    max = 70,
    lowText = "10",
    highText = "70",
    valuePattern = BAGANATOR_L_X_ICON_SIZE,
    option = "bag_icon_size",
  },
  {
    type = "slider",
    min = 5,
    max = 40,
    lowText = "5",
    highText = "40",
    valuePattern = BAGANATOR_L_X_ICON_TEXT_FONT_SIZE,
    option = "icon_text_font_size",
  },
}

local TOOLTIP_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_INVENTORY_IN_TOOLTIPS,
    option = "show_inventory_tooltips",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_PRESS_SHIFT_TO_SHOW_TOOLTIPS,
    option = "show_tooltips_on_shift",
  },
}

local function GenerateFrames(options, parent)
  local lastFrame = nil
  local allFrames = {}
  for _, option in ipairs(options) do
    if not option.isRetailOnly or Baganator.Constants.IsRetail then
      if option.type == "checkbox" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorCheckBoxTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
        frame:SetPoint("LEFT", parent, 40, 0)
        frame:SetPoint("RIGHT", parent, -40, 0)
      elseif option.type == "slider" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorSliderTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
      end
      frame:Init(option)
      table.insert(allFrames, frame)
      lastFrame = frame
    end
  end

  allFrames[1]:ClearAllPoints()
  allFrames[1]:SetPoint("TOP", parent)
  allFrames[1]:SetPoint("LEFT", parent, 40, 0)
  allFrames[1]:SetPoint("RIGHT", parent, -40, 0)

  return allFrames
end

local function GetTab(parent)
  local tab
  if Baganator.Constants.IsRetail then
    tab = CreateFrame("Button", nil, parent, "BaganatorRetailTabTopTemplate")
  else
    tab = CreateFrame("Button", nil, parent, "BaganatorClassicTabTopTemplate")
  end

  if tIndexOf(parent.Tabs, tab) == nil then
    table.insert(parent.Tabs, tab)
  end

  if #parent.Tabs > 1 then
    tab:SetPoint("TOPLEFT", parent.Tabs[#parent.Tabs - 1], "TOPRIGHT", 5, 0)
  else
    tab:SetPoint("TOPLEFT", 10, -20)
  end

  local tabIndex = #parent.Tabs
  tab:SetScript("OnClick", function()
    parent:SetIndex(tabIndex)
  end)

  return tab
end

local function GetWrapperFrame(parent)
  local frame = CreateFrame("Frame", nil, parent)
  frame:SetPoint("TOP", 0, -70)
  frame:SetPoint("LEFT")
  frame:SetPoint("RIGHT")
  frame:SetPoint("BOTTOM")
  frame:Hide()

  table.insert(parent.Views, frame)

  return frame
end

BaganatorCustomiseDialogMixin = {}

function BaganatorCustomiseDialogMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:SetTitle(BAGANATOR_L_CUSTOMISE_BAGANATOR)

  self.Tabs = {}
  self.Views = {}
  self.lowestFrames = {}
  self.optionFrames = {}

  self:SetupWindow()
  self:SetupIcon()
  self:SetupTooltip()

  PanelTemplates_SetNumTabs(self, #self.Tabs)
end

function BaganatorCustomiseDialogMixin:SetIndex(index)
  for _, v in ipairs(self.Views) do
    v:Hide()
  end
  self.Views[index]:Show()

  PanelTemplates_SetTab(self, index)
end

function BaganatorCustomiseDialogMixin:SetupWindow()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_WINDOWS)

  local frame = GetWrapperFrame(self)

  frame.ResetFramePositions = CreateFrame("Button", nil, frame, "UIPanelDynamicResizeButtonTemplate")
  frame.ResetFramePositions:SetPoint("TOPRIGHT", frame, -20, 0)
  frame.ResetFramePositions:SetText(BAGANATOR_L_RESET_POSITIONS)
  DynamicResizeButton_Resize(frame.ResetFramePositions)
  frame.ResetFramePositions:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("ResetFramePositions")
  end)

  local allFrames = GenerateFrames(WINDOW_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(Baganator.Config.Get(frame.option))
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupIcon()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_ICONS)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(ICON_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(Baganator.Config.Get(frame.option))
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupTooltip()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_TOOLTIPS)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(TOOLTIP_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(Baganator.Config.Get(frame.option))
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:RefreshOptions()
  local bottom = self.lowestFrames[1]:GetBottom()
  for _, f in ipairs(self.lowestFrames) do
    bottom = math.min(bottom, f:GetBottom())
  end

  self:SetHeight(self:GetTop() - bottom + 20)
end

function BaganatorCustomiseDialogMixin:OnShow()
  self:SetIndex(1)
  self:RefreshOptions()
end
