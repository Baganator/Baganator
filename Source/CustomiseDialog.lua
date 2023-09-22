local OPTIONS = {
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
    text = BAGANATOR_L_CUSTOMISE_EMPTY_SLOTS,
    option = "empty_slot_background",
    isRetailOnly = true,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_CUSTOMISE_SHOW_TABS,
    option = "show_recents_tabs_main_view",
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
    text = BAGANATOR_L_SHOW_INVENTORY_IN_TOOLTIPS,
    option = "show_inventory_tooltips",
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
  {
    type = "slider",
    min = 1,
    max = 70,
    lowText = "10",
    highText = "70",
    valuePattern = BAGANATOR_L_X_ICON_SIZE,
    option = "bag_icon_size",
  },
}

BaganatorCustomiseDialogMixin = {}

function BaganatorCustomiseDialogMixin:OnLoad()
  ButtonFrameTemplate_HidePortrait(self)
  ButtonFrameTemplate_HideButtonBar(self)
  self.Inset:Hide()

  self:SetTitle(BAGANATOR_L_CUSTOMISE_BAGANATOR)

  self.ResetFramePositions:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("ResetFramePositions")
  end)

  local lastFrame = nil
  self.allFrames = {}
  for _, option in ipairs(OPTIONS) do
    if not option.isRetailOnly or Baganator.Constants.IsRetail then
      if option.type == "checkbox" then
        frame = CreateFrame("Frame", nil, self, "BaganatorCheckBoxTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -20)
        frame:SetPoint("LEFT", self, 40, 0)
      elseif option.type == "slider" then
        frame = CreateFrame("Frame", nil, self, "BaganatorSliderTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -20)
      end
      frame:Init(option)
      table.insert(self.allFrames, frame)
      lastFrame = frame
    end
  end
  self.allFrames[1]:ClearAllPoints()
  self.allFrames[1]:SetPoint("TOP", self.ResetFramePositions)
  self.allFrames[1]:SetPoint("RIGHT", self.ResetFramePositions, "LEFT", -20, 0)
  self.allFrames[1]:SetPoint("LEFT", 40, 0)
end

function BaganatorCustomiseDialogMixin:RefreshOptions()
  for index, frame in ipairs(self.allFrames) do
    frame:SetValue(Baganator.Config.Get(frame.option))
  end
  self:SetHeight(self:GetTop() - self.allFrames[#self.allFrames]:GetBottom() + 20)
end
