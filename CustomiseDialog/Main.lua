local _, addonTable = ...

local IsRetailCheck = function()
  return Baganator.Constants.IsRetail
end

local NotIsEraCheck = function()
  return not Baganator.Constants.IsEra
end

local WINDOW_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_ENABLE_BAG_VIEWS_2,
    option = "enable_unified_bags",
  },
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
    text = BAGANATOR_L_CUSTOMISE_SHOW_TABS,
    option = "show_recents_tabs_main_view",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_PLACE_BAG_ROW_WITH_MISSING_SLOTS_AT_THE_TOP,
    option = "bag_empty_space_at_top",
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
    type = "checkbox",
    text = BAGANATOR_L_REDUCE_SPACING_BETWEEN_UI_COMPONENTS,
    option = "reduce_spacing",
  },
  {
    type = "header",
    text = BAGANATOR_L_JUNK_DETECTION,
    level = 2,
  },
}

local ICON_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_CUSTOMISE_EMPTY_SLOTS,
    option = "empty_slot_background",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_HIDE_BOE_STATUS_ON_COMMON,
    option = "hide_boe_on_common",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_USE_ITEM_QUALITY_COLORS_FOR_ICON_TEXT,
    option = "icon_text_quality_colors",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_ICON_GREY_JUNK_ITEMS,
    option = "icon_grey_junk",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_ITEMS_FLASH_ON_ALT_CLICK,
    option = "icon_flash_similar_alt",
  },
  {
    type = "slider",
    min = 10,
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
  {
    type = "header",
    text = BAGANATOR_L_ICON_CORNER_PRIORITIES,
    level = 2,
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
    text = BAGANATOR_L_SHOW_CURRENCY_TOOLTIPS,
    option = "show_currency_tooltips",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_PRESS_SHIFT_TO_SHOW_TOOLTIPS,
    option = "show_tooltips_on_shift",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_GUILD_BANKS_IN_INVENTORY_TOOLTIPS,
    option = "show_guild_banks_in_tooltips",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_ONLY_USE_SAME_CONNECTED_REALMS,
    option = "tooltips_connected_realms_only",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_ONLY_USE_SAME_FACTION_CHARACTERS,
    option = "tooltips_faction_only",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SORT_BY_CHARACTER_NAME,
    option = "tooltips_sort_by_name",
  },
  {
    type = "slider",
    min = 1,
    max = 40,
    lowText = "1",
    highText = "40",
    valuePattern = BAGANATOR_L_X_CHARACTERS_SHOWN,
    option = "tooltips_character_limit",
  },
}

local OPEN_CLOSE_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_BANK,
    option = "bank",
    root = "auto_open",
  },
  {
    type = "checkbox",
    text = GUILD_BANK,
    option = "guild_bank",
    root = "auto_open",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = TRADE,
    option = "trade_partner",
    root = "auto_open",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_CRAFTING_WINDOW,
    option = "tradeskill",
    root = "auto_open",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_AUCTION_HOUSE,
    option = "auction_house",
    root = "auto_open",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_VOID_STORAGE,
    option = "void_storage",
    root = "auto_open",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_MAIL,
    option = "mail",
    root = "auto_open",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_VENDOR,
    option = "merchant",
    root = "auto_open",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SOCKET_INTERFACE,
    option = "sockets",
    root = "auto_open",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SCRAPPING_MACHINE,
    option = "scrapping_machine",
    root = "auto_open",
    check = IsRetailCheck,
  },
}
local SORTING_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_SORT_BUTTON,
    option = "show_sort_button_2",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_AUTO_SORT_ON_OPENING_BAGS,
    option = "auto_sort_on_open",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SORT_START_AT_BOTTOM,
    option = "sort_start_at_bottom",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_SORT_IGNORE_SLOTS_AT_END_NOT_START,
    option = "sort_ignore_slots_at_end",
  },
  {
    type = "slider",
    min = 0,
    max = 128,
    lowText = "0",
    highText = "128",
    valuePattern = BAGANATOR_L_X_SLOTS_TO_IGNORE_WHEN_SORTING_CHARACTER_SPECIFIC,
    option = "sort_ignore_slots_count_2",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_REVERSE_GROUPS_SORT_ORDER,
    option = "reverse_groups_sort_order",
  },
  {
    type = "header",
    text = BAGANATOR_L_SORT_METHOD,
    level = 2,
  },
}
local TRANSFERS_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_TRANSFER_BUTTON,
    option = "show_transfer_button",
  },
}

table.sort(OPEN_CLOSE_OPTIONS, function(a, b)
  return a.text < b.text
end)

local function GenerateFrames(options, parent)
  local lastFrame = nil
  local allFrames = {}
  for _, option in ipairs(options) do
    if not option.check or option.check() then
      local frame
      if option.type == "checkbox" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorCheckBoxTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
        frame:SetPoint("LEFT", parent, 40, 0)
        frame:SetPoint("RIGHT", parent, -40, 0)
      elseif option.type == "slider" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorSliderTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
      elseif option.type == "dropdown" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorDropDownTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
      elseif option.type == "header" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorHeaderTemplate")
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
  self:SetupOpenClose()
  self:SetupSorting()
  self:SetupTransfers()

  PanelTemplates_SetNumTabs(self, #self.Tabs)

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
end

function BaganatorCustomiseDialogMixin:OnDragStart()
  self:StartMoving()
  self:SetUserPlaced(false)
end

function BaganatorCustomiseDialogMixin:OnDragStop()
  self:StopMovingOrSizing()
  self:SetUserPlaced(false)
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
  frame.ResetFramePositions:SetPoint("TOPRIGHT", frame, -20, -46)
  frame.ResetFramePositions:SetText(BAGANATOR_L_RESET_POSITIONS)
  DynamicResizeButton_Resize(frame.ResetFramePositions)
  frame.ResetFramePositions:SetScript("OnClick", function()
    Baganator.CallbackRegistry:TriggerEvent("ResetFramePositions")
  end)

  do
    local junkPlugins = {}
    for id, pluginDetails in pairs(addonTable.JunkPlugins) do
      table.insert(junkPlugins, {
        label = pluginDetails.label,
        id = id,
      })
    end
    table.sort(junkPlugins, function(a, b)
      return a.label < b.label
    end)
    local dropdown = {
      type = "dropdown",
      option = "junk_plugin",
      entries = {
        BAGANATOR_L_POOR_QUALITY,
      },
      values = {
        "poor_quality",
      },
    }
    for _, pluginInfo in ipairs(junkPlugins) do
      table.insert(dropdown.entries, pluginInfo.label)
      table.insert(dropdown.values, pluginInfo.id)
    end

    table.insert(WINDOW_OPTIONS, dropdown)
  end

  local allFrames = GenerateFrames(WINDOW_OPTIONS, frame)

  allFrames[2].CheckBox.HoverBackground:SetPoint("RIGHT", frame.ResetFramePositions, "LEFT")

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

  local cornersEditor = Baganator.CustomiseDialog.GetCornersEditor(frame)
  cornersEditor:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, 0)
  table.insert(allFrames, cornersEditor)

  local itemButton
  if Baganator.Constants.IsRetail then
    itemButton = CreateFrame("ItemButton", nil, frame)
  else
    itemButton = CreateFrame("Button", nil, frame, "ItemButtonTemplate")
  end
  itemButton:SetPoint("CENTER", cornersEditor, 0, -15)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(Baganator.Config.Get(frame.option))
      end
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

function BaganatorCustomiseDialogMixin:SetupOpenClose()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_AUTO_OPEN_CLOSE)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(OPEN_CLOSE_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(Baganator.Config.Get(Baganator.Config.Options.AUTO_OPEN)[frame.option])
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupSorting()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_SORTING)

  local frame = GetWrapperFrame(self)

  local allModes = {
    {"type", BAGANATOR_L_ITEM_TYPE_ENHANCED},
    {"quality", BAGANATOR_L_ITEM_QUALITY_ENHANCED},
    {"type-legacy", BAGANATOR_L_ITEM_TYPE_BASIC},
    {"quality-legacy", BAGANATOR_L_ITEM_QUALITY_BASIC},
    {"combine_stacks_only", BAGANATOR_L_COMBINE_STACKS_ONLY},
    {"blizzard", BAGANATOR_L_BLIZZARD},
    {"expansion", BAGANATOR_L_EXPANSION},
    {"sortbags", BAGANATOR_L_SORTBAGS},
  }

  table.sort(allModes, function(a, b) return a[2] < b[2] end)

  local typeDropDown = {
    type = "dropdown",
    option = "sort_method",
    entries = {},
    values = {},
  }

  for _, details in ipairs(allModes) do
    if Baganator.Sorting.IsModeAvailable(details[1]) then
      table.insert(typeDropDown.values, details[1])
      table.insert(typeDropDown.entries, details[2])
    end
  end

  if not Baganator.Sorting.IsModeAvailable(Baganator.Config.Get("sort_method")) then
    Baganator.Config.ResetOne("sort_method")
  end

  table.insert(SORTING_OPTIONS, typeDropDown)

  local allFrames = GenerateFrames(SORTING_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(Baganator.Config.Get(frame.option))
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupTransfers()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_TRANSFERS)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(TRANSFERS_OPTIONS, frame)

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
