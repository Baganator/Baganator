local _, addonTable = ...

local IsRetailCheck = function()
  return addonTable.Constants.IsRetail
end

local NotIsEraCheck = function()
  return not addonTable.Constants.IsEra
end

local GENERAL_OPTIONS = {
}

local LAYOUT_OPTIONS = {
  {
    type = "dropdown",
    text = BAGANATOR_L_BAG_VIEW_TYPE,
    option = "bag_view_type",
    entries = {
      BAGANATOR_L_SINGLE_BAG,
      BAGANATOR_L_CATEGORY_GROUPS,
    },
    values = {
      "single",
      "category",
    }
  },
  {
    type = "dropdown",
    text = BAGANATOR_L_BANK_VIEW_TYPE,
    option = "bank_view_type",
    entries = {
      BAGANATOR_L_SINGLE_BAG,
      BAGANATOR_L_CATEGORY_GROUPS,
    },
    values = {
      "single",
      "category",
    }
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = BAGANATOR_L_SHOW_BUTTONS,
    option = "show_buttons_on_alt",
    entries = {
      BAGANATOR_L_ALWAYS,
      BAGANATOR_L_WHEN_HOLDING_ALT,
    },
    values = {
      false,
      true,
    }
  },
  {
    type = "slider",
    min = 1,
    max = 24,
    lowText = "1",
    highText = "24",
    text = BAGANATOR_L_BAG_COLUMNS,
    option = "bag_view_width",
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = BAGANATOR_L_BANK_COLUMNS,
    option = "bank_view_width",
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = BAGANATOR_L_WARBAND_BANK_COLUMNS,
    option = "warband_bank_view_width",
    check = function() return Syndicator.Constants.WarbandBankActive end,
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = BAGANATOR_L_GUILD_BANK_COLUMNS,
    option = "guild_view_width",
    check = NotIsEraCheck,
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = BAGANATOR_L_BLANK_SPACE,
    option = "bag_empty_space_at_top",
    entries = {
      BAGANATOR_L_AT_THE_BOTTOM,
      BAGANATOR_L_AT_THE_TOP,
    },
    values = {
      false,
      true,
    }
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_RECENT_CHARACTER_TABS,
    option = "show_recents_tabs_main_view",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_REDUCE_UI_SPACING,
    option = "reduce_spacing",
  },
  { type = "spacing" },
  {
    type = "slider",
    min = 0,
    max = 200,
    scale = 100,
    lowText = "0%",
    highText = "200%",
    text = BAGANATOR_L_CATEGORY_SPACING,
    option = "category_horizontal_spacing_2",
    valuePattern = BAGANATOR_L_PERCENTAGE_PATTERN,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_GROUP_IDENTICAL_ITEMS,
    rightText = BAGANATOR_L_BRACKETS_CATEGORY_VIEW_ONLY,
    option = "category_item_grouping",
  },
  { type = "spacing" },
  {
    type = "checkbox",
    text = BAGANATOR_L_LOCK_WINDOWS,
    option = "lock_frames",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_CHANGE_WINDOW_ANCHORS,
    option = "setting_anchors",
  },
}

local THEME_OPTIONS = {
  {
    type = "slider",
    min = 1,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    text = BAGANATOR_L_TRANSPARENCY,
    valuePattern = BAGANATOR_L_PERCENTAGE_PATTERN,
    option = "view_alpha",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_REMOVE_BORDERS,
    option = "no_frame_borders",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_HIDE_ICON_BACKGROUNDS,
    option = "empty_slot_background",
  },
}

local ICON_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_ITEM_QUALITY_TEXT_COLORS,
    option = "icon_text_quality_colors",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_GREY_JUNK_ITEMS,
    option = "icon_grey_junk",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_FLASH_DUPLICATE_ITEMS,
    rightText = BAGANATOR_L_ALT_CLICK,
    option = "icon_flash_similar_alt",
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_HIDE_BOE_STATUS_ON_COMMON_2,
    option = "hide_boe_on_common",
  },
  { type = "spacing" },
  {
    type = "slider",
    min = 10,
    max = 70,
    lowText = "10",
    highText = "70",
    text = BAGANATOR_L_ICON_SIZE,
    valuePattern = BAGANATOR_L_PIXEL_PATTERN,
    option = "bag_icon_size",
  },
  {
    type = "slider",
    min = 5,
    max = 40,
    lowText = "5",
    highText = "40",
    text = BAGANATOR_L_ICON_TEXT_FONT_SIZE,
    valuePattern = BAGANATOR_L_PIXEL_PATTERN,
    option = "icon_text_font_size",
  },
  { type = "spacing" },
  {
    type = "header",
    text = BAGANATOR_L_ICON_CORNERS,
    level = 2,
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
  {
    type = "checkbox",
    text = BAGANATOR_L_FORGE_OF_BONDS,
    option = "forge_of_bonds",
    root = "auto_open",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = BAGANATOR_L_CHARACTER_PANEL,
    option = "character_panel",
    root = "auto_open",
  },
}
local SORTING_OPTIONS = {
  {
    type = "checkbox",
    text = BAGANATOR_L_SHOW_SORT_BUTTON,
    option = "show_sort_button_2",
  },
  { type = "spacing" },
  {
    type = "checkbox",
    text = BAGANATOR_L_SORT_ON_OPEN,
    option = "auto_sort_on_open",
  },
  { type = "spacing" },
  {
    type = "checkbox",
    text = BAGANATOR_L_REVERSE_GROUPS_SORT_ORDER,
    option = "reverse_groups_sort_order",
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = BAGANATOR_L_ARRANGE_ITEMS,
    option = "sort_start_at_bottom",
    entries = {
      BAGANATOR_L_FROM_THE_TOP,
      BAGANATOR_L_FROM_THE_BOTTOM,
    },
    values = {
      false,
      true,
    }
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = BAGANATOR_L_IGNORED_SLOTS,
    option = "sort_ignore_slots_at_end",
    entries = {
      BAGANATOR_L_FROM_THE_TOP,
      BAGANATOR_L_FROM_THE_BOTTOM,
    },
    values = {
      false,
      true,
    }
  },
  {
    type = "slider",
    min = 0,
    max = 128,
    lowText = "0",
    highText = "128",
    text = BAGANATOR_L_IGNORED_BAG_SLOTS,
    option = "sort_ignore_slots_count_2",
  },
  {
    type = "slider",
    min = 0,
    max = 500,
    lowText = "0",
    highText = "500",
    text = BAGANATOR_L_IGNORED_BANK_SLOTS,
    option = "sort_ignore_bank_slots_count",
  },
}

local CATEGORIES_OPTIONS = {
}

table.sort(OPEN_CLOSE_OPTIONS, function(a, b)
  return a.text < b.text
end)

local function GenerateFrames(options, parent)
  local lastFrame = nil
  local allFrames = {}
  local offsetY = 0
  for _, option in ipairs(options) do
    if not option.check or option.check() then
      local frame
      if option.type == "checkbox" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorCheckBoxTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, offsetY)
        frame:SetPoint("LEFT", parent, 40, 0)
        frame:SetPoint("RIGHT", parent, -40, 0)
      elseif option.type == "slider" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorSliderTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, offsetY)
      elseif option.type == "dropdown" then
        frame = addonTable.CustomiseDialog.GetBasicDropdown(parent)
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, offsetY)
      elseif option.type == "header" then
        frame = CreateFrame("Frame", nil, parent, "BaganatorHeaderTemplate")
        frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, offsetY)
      elseif option.type == "spacing" then
        offsetY = -30
      end
      if frame then
        offsetY = 0
        frame:Init(option)
        table.insert(allFrames, frame)
        lastFrame = frame
      end
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
  if addonTable.Constants.IsRetail then
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

  addonTable.Skins.AddFrame("TopTabButton", tab)

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
  addonTable.Skins.AddFrame("ButtonFrame", self)
  self:SetScript("OnMouseWheel", function() end)

  self:SetTitle(BAGANATOR_L_CUSTOMISE_BAGANATOR)

  self.Tabs = {}
  self.Views = {}
  self.lowestFrames = {}
  self.optionFrames = {}

  self:SetupGeneral()
  self:SetupLayout()
  self:SetupTheme()
  self:SetupIcon()
  self:SetupOpenClose()
  self:SetupSorting()
  self:SetupCategoriesOptions()

  PanelTemplates_SetNumTabs(self, #self.Tabs)

  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)

  if TSM_API then
    self:SetFrameStrata("HIGH")
  end
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
  self.lastIndex = index
end

function BaganatorCustomiseDialogMixin:SetupGeneral()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_GENERAL)

  local frame = GetWrapperFrame(self)

  local infoInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")

  do
    infoInset:SetPoint("TOP")
    infoInset:SetPoint("LEFT", 20 + addonTable.Constants.ButtonFrameOffset, 0)
    infoInset:SetPoint("RIGHT", -20, 0)
    infoInset:SetHeight(75)
    addonTable.Skins.AddFrame("InsetFrame", infoInset)

    local logo = infoInset:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\Baganator\\Assets\\logo")
    logo:SetSize(52, 52)
    logo:SetPoint("LEFT", 8, 0)

    local name = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    name:SetText(BAGANATOR_L_BAGANATOR)
    name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, 0)

    local credit = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    credit:SetText(BAGANATOR_L_BY_PLUSMOUSE)
    credit:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 5, 0)

    local discordLinkDialog = "Baganator_General_Settings_Discord_Dialog"
    StaticPopupDialogs[discordLinkDialog] = {
      text = BAGANATOR_L_CTRL_C_TO_COPY,
      button1 = DONE,
      hasEditBox = 1,
      OnShow = function(self)
        self.editBox:SetText("https://discord.gg/TtSN6DxSky")
        self.editBox:HighlightText()
      end,
      EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
      end,
      EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
      editBoxWidth = 230,
      timeout = 0,
      hideOnEscape = 1,
    }
    local discordButton = CreateFrame("Button", nil, infoInset, "UIPanelDynamicResizeButtonTemplate")
    discordButton:SetText(BAGANATOR_L_JOIN_THE_DISCORD)
    DynamicResizeButton_Resize(discordButton)
    discordButton:SetPoint("BOTTOMLEFT", logo, "BOTTOMRIGHT", 8, 0)
    discordButton:SetScript("OnClick", function()
      StaticPopup_Show(discordLinkDialog)
    end)
    addonTable.Skins.AddFrame("Button", discordButton)
    local discordText = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    discordText:SetPoint("LEFT", discordButton, "RIGHT", 10, 0)
    discordText:SetText(BAGANATOR_L_DISCORD_DESCRIPTION)
  end

  do
    local junkPlugins = {
      {label = BAGANATOR_L_POOR_QUALITY, id = "poor_quality"},
    }
    for id, pluginDetails in pairs(addonTable.API.JunkPlugins) do
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
      text = BAGANATOR_L_JUNK_DETECTION_2,
      option = "junk_plugin",
      entries = {},
      values = {},
    }
    for _, pluginInfo in ipairs(junkPlugins) do
      table.insert(dropdown.entries, pluginInfo.label)
      table.insert(dropdown.values, pluginInfo.id)
    end
    if addonTable.API.JunkPlugins[addonTable.Config.Get("junk_plugin")] == nil then
      addonTable.Config.ResetOne("junk_plugin")
    end

    table.insert(GENERAL_OPTIONS, dropdown)
  end

  do
    local upgradePlugins = {
      {label = BAGANATOR_L_NONE, id = "none"},
    }
    for id, pluginDetails in pairs(addonTable.API.UpgradePlugins) do
      table.insert(upgradePlugins, {
        label = pluginDetails.label,
        id = id,
      })
    end
    table.sort(upgradePlugins, function(a, b)
      return a.label < b.label
    end)
    local dropdown = {
      type = "dropdown",
      text = BAGANATOR_L_UPGRADE_DETECTION,
      option = "upgrade_plugin",
      entries = {},
      values = {},
    }
    for _, pluginInfo in ipairs(upgradePlugins) do
      table.insert(dropdown.entries, pluginInfo.label)
      table.insert(dropdown.values, pluginInfo.id)
    end
    if addonTable.API.UpgradePlugins[addonTable.Config.Get("upgrade_plugin")] == nil then
      addonTable.Config.ResetOne("upgrade_plugin")
    end

    table.insert(GENERAL_OPTIONS, dropdown)
  end

  local allFrames = {infoInset}

  do
    local function GetTipsSection(rowContainer, details)
      local header = rowContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
      header:SetJustifyH("LEFT")
      header:SetPoint("TOP")
      header:SetText(details.header)
      header:SetHeight(30)
      local text = rowContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
      text:SetJustifyH("LEFT")
      text:SetPoint("TOP", header, "BOTTOM")
      text:SetText(details.text)
      text:SetSpacing(3)

      return {header, text}
    end

    local function MakeTipsRow(details1, details2)
      local rowContainer = CreateFrame("Frame", nil, frame)
      rowContainer:SetPoint("LEFT", 35 + addonTable.Constants.ButtonFrameOffset, 0)
      rowContainer:SetPoint("RIGHT", -35, 0)
      rowContainer:SetHeight(110)
      for _, row in ipairs(GetTipsSection(rowContainer, details1)) do
        row:SetPoint("LEFT")
        row:SetPoint("RIGHT", rowContainer, "CENTER", -15, 0)
      end
      for _, row in ipairs(GetTipsSection(rowContainer, details2)) do
        row:SetPoint("RIGHT")
        row:SetPoint("LEFT", rowContainer, "CENTER", 15, 0)
      end
      return rowContainer
    end

    local tipsRows = {
      MakeTipsRow({
        header = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\Search.png", 64, 64, 13, 13, 0, 1, 0, 1) .. "  " .. SEARCH,
        text = BAGANATOR_L_TIPS_SEARCH,
      }, {
        header = BAGANATOR_L_PLUGINS,
        text = BAGANATOR_L_TIPS_PLUGINS,
      }),
      MakeTipsRow({
        header = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\Transfer.png", 64, 64, 13, 13, 0, 1, 0, 1) .. " " .. BAGANATOR_L_TRANSFER,
        text = BAGANATOR_L_TIPS_TRANSFER,
      }, {
        header = BAGANATOR_L_SKINS,
        text = BAGANATOR_L_TIPS_SKINS_2,
      }),
    }
    for _, row in ipairs(tipsRows) do
      row:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
      table.insert(allFrames, row)
    end
    tipsRows[1]:SetPoint("TOP", allFrames[#allFrames - #tipsRows], "BOTTOM", 0, -30)

    local searchHelpButton = CreateFrame("Button", nil, tipsRows[1], "BaganatorHelpButtonTemplate")
    searchHelpButton:SetPoint("TOP", 0, -2)
    searchHelpButton:SetPoint("RIGHT", tipsRows[1], "CENTER", -15, 0)
    searchHelpButton:SetScript("OnClick", function() addonTable.Help.ShowSearchDialog() end)
  end

  local optionFrames = GenerateFrames(GENERAL_OPTIONS, frame)
  optionFrames[1]:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)

  tAppendAll(allFrames, optionFrames)

  local tooltipButtonFrame = CreateFrame("Frame", nil, frame)
  do
    tooltipButtonFrame:SetPoint("LEFT")
    tooltipButtonFrame:SetPoint("RIGHT")
    tooltipButtonFrame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
    tooltipButtonFrame:SetHeight(40)
    local text = tooltipButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("RIGHT", tooltipButtonFrame, "CENTER", -50, 0)
    text:SetText(BAGANATOR_L_TOOLTIP_SETTINGS)
    text:SetJustifyH("RIGHT")
    local button = CreateFrame("Button", nil, tooltipButtonFrame, "UIPanelDynamicResizeButtonTemplate")
    button:SetText(BAGANATOR_L_OPEN_SYNDICATOR)
    DynamicResizeButton_Resize(button)
    button:SetPoint("LEFT", tooltipButtonFrame, "CENTER", -35, 0)
    button:SetScript("OnClick", function()
      Settings.OpenToCategory(SYNDICATOR_L_SYNDICATOR)
    end)
    addonTable.Skins.AddFrame("Button", button)
    table.insert(allFrames, tooltipButtonFrame)
  end

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupIcon()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_ICONS)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(ICON_OPTIONS, frame)

  local cornersEditor = addonTable.CustomiseDialog.GetCornersEditor(frame)
  cornersEditor:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -3)
  table.insert(allFrames, cornersEditor)

  local itemButton
  if addonTable.Constants.IsRetail then
    itemButton = CreateFrame("ItemButton", nil, frame)
  else
    itemButton = CreateFrame("Button", nil, frame, "ItemButtonTemplate")
  end
  itemButton:SetPoint("CENTER", cornersEditor, 0, 0)
  addonTable.Skins.AddFrame("ItemButton", itemButton)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupOpenClose()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_AUTO_OPEN)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(OPEN_CLOSE_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(addonTable.Config.Get(addonTable.Config.Options.AUTO_OPEN)[frame.option])
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupSorting()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_SORTING)

  local frame = GetWrapperFrame(self)

  do
    local allModes = {
      {"type", BAGANATOR_L_ITEM_TYPE},
      {"quality", BAGANATOR_L_ITEM_QUALITY},
      {"item-level", BAGANATOR_L_ITEM_LEVEL},
      {"combine_stacks_only", BAGANATOR_L_COMBINE_STACKS_ONLY},
      {"expansion", BAGANATOR_L_EXPANSION},
    }

    for id, details in pairs(addonTable.API.ExternalContainerSorts) do
      table.insert(allModes, {id, details.label})
    end

    table.sort(allModes, function(a, b) return a[2] < b[2] end)

    local typeDropDown = {
      type = "dropdown",
      text = BAGANATOR_L_SORT_METHOD_2,
      option = "sort_method",
      entries = {},
      values = {},
    }

    for _, details in ipairs(allModes) do
      if addonTable.Sorting.IsModeAvailable(details[1]) then
        table.insert(typeDropDown.values, details[1])
        table.insert(typeDropDown.entries, details[2])
      end
    end

    if not addonTable.Sorting.IsModeAvailable(addonTable.Config.Get("sort_method")) then
      addonTable.Config.ResetOne("sort_method")
    end

    table.insert(SORTING_OPTIONS, 5, typeDropDown)
  end

  local allFrames = GenerateFrames(SORTING_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(addonTable.Config.Get(frame.option))
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupLayout()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_LAYOUT)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(LAYOUT_OPTIONS, frame)

  local function UpdateValues()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(addonTable.Config.Get(frame.option))
    end
  end

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == "bag_view_type" or settingName == "bank_view_type" then
      local value = addonTable.Config.Get(settingName)
      if value ~= addonTable.Config.Get("view_type") then
        addonTable.Config.Set("view_type", "unset")
      end
      UpdateValues()
    end
  end)

  local _, resetAnchor = FindInTableIf(allFrames, function(f) return f.text == BAGANATOR_L_LOCK_WINDOWS end)
  frame.ResetFramePositions = CreateFrame("Button", nil, frame, "UIPanelDynamicResizeButtonTemplate")
  frame.ResetFramePositions:SetPoint("LEFT", resetAnchor, "CENTER", 55, 0)
  frame.ResetFramePositions:SetText(BAGANATOR_L_RESET_POSITIONS)
  DynamicResizeButton_Resize(frame.ResetFramePositions)
  frame.ResetFramePositions:SetScript("OnClick", function()
    addonTable.CallbackRegistry:TriggerEvent("ResetFramePositions")
  end)
  frame.ResetFramePositions:SetFrameLevel(10000)
  addonTable.Skins.AddFrame("Button", frame.ResetFramePositions)

  resetAnchor.CheckBox.HoverBackground:SetPoint("RIGHT", frame.ResetFramePositions, "LEFT")

  frame:SetScript("OnShow", UpdateValues)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupTheme()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_THEME)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(THEME_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      frame:SetValue(addonTable.Config.Get(frame.option))
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupCategoriesOptions()
  local tab = GetTab(self)
  tab:SetText(BAGANATOR_L_CATEGORIES)

  local frame = GetWrapperFrame(self)

  local allFrames = {}

  local showAddButtons, editorHeader = unpack(GenerateFrames({{
    type = "dropdown",
    text = BAGANATOR_L_SHOW_ADD_BUTTONS,
    option = "add_to_category_buttons_2",
    entries = {
      BAGANATOR_L_DRAGGING,
      BAGANATOR_L_DRAGGING_THEN_ALT,
      BAGANATOR_L_NEVER,
    },
    values = {
      "drag",
      "drag+alt",
      "never",
    }
  }, {
    type = "header",
    text = BAGANATOR_L_EDIT,
    level = 2,
  }}, frame))
  table.insert(allFrames, showAddButtons)
  editorHeader:SetPoint("TOP", showAddButtons, "BOTTOM")
  editorHeader:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset, 0)
  editorHeader:SetPoint("RIGHT", frame, -28, 0)
  table.insert(allFrames, editorHeader)

  showAddButtons:SetPoint("RIGHT", frame, -28, 0)
  showAddButtons.DropDown:SetWidth(155)
  showAddButtons:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset - 10, 0)

  local editors = {}

  local categoriesEditor = CreateFrame("Frame", nil, frame, "BaganatorCustomiseDialogCategoriesEditorTemplate")
  categoriesEditor:SetPoint("TOP", editorHeader, "BOTTOM")
  categoriesEditor:SetPoint("RIGHT", frame, -28, 0)
  categoriesEditor:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset - 10, 0)
  editors["EditCategory"] = categoriesEditor
  table.insert(allFrames, categoriesEditor)

  local categoriesSectionEditor = CreateFrame("Frame", nil, frame, "BaganatorCustomiseDialogCategoriesSectionEditorTemplate")
  categoriesSectionEditor:SetPoint("TOP", editorHeader, "BOTTOM")
  categoriesSectionEditor:SetPoint("RIGHT", frame, -28, 0)
  categoriesSectionEditor:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset - 10, 0)
  editors["EditCategorySection"] = categoriesSectionEditor
  table.insert(allFrames, categoriesSectionEditor)

  local categoriesRecentEditor = addonTable.CustomiseDialog.GetCategoriesRecentEditor(frame)
  categoriesRecentEditor:SetPoint("TOP", editorHeader, "BOTTOM")
  categoriesRecentEditor:SetPoint("RIGHT", frame, -28, 0)
  categoriesRecentEditor:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset - 10, 0)
  editors["EditCategoryRecent"] = categoriesRecentEditor
  table.insert(allFrames, categoriesRecentEditor)

  local categoriesEmptyEditor = addonTable.CustomiseDialog.GetCategoriesEmptyEditor(frame)
  categoriesEmptyEditor:SetPoint("TOP", editorHeader, "BOTTOM")
  categoriesEmptyEditor:SetPoint("RIGHT", frame, -28, 0)
  categoriesEmptyEditor:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset - 10, 0)
  editors["EditCategoryEmpty"] = categoriesEmptyEditor
  table.insert(allFrames, categoriesEmptyEditor)

  local categoriesDividerEditor = CreateFrame("Frame", nil, frame, "BaganatorCustomiseDialogCategoriesDividerEditorTemplate")
  categoriesDividerEditor:SetPoint("TOP", editorHeader, "BOTTOM")
  categoriesDividerEditor:SetPoint("RIGHT", frame, -28, 0)
  categoriesDividerEditor:SetPoint("LEFT", frame, "CENTER", addonTable.Constants.ButtonFrameOffset - 10, 0)
  editors["EditCategoryDivider"] = categoriesDividerEditor
  table.insert(allFrames, categoriesDividerEditor)

  local function ShowEditor(event)
    for key, editor in pairs(editors) do
      editor:SetShown(key == event)
    end
  end
  for event, editor in pairs(editors) do
    addonTable.CallbackRegistry:RegisterCallback(event, function()
      ShowEditor(event)
    end)
    editor.Return = function()
      categoriesEditor:Disable()
      ShowEditor("EditCategory")
    end
  end

  local categoriesOrder = addonTable.CustomiseDialog.GetCategoriesOrganiser(frame)
  categoriesOrder:SetPoint("TOP")
  table.insert(allFrames, categoriesOrder)
  categoriesOrder:SetPoint("LEFT", frame, addonTable.Constants.ButtonFrameOffset + 20, 0)
  categoriesOrder:SetPoint("RIGHT", frame, "CENTER")

  local enableDialog = "BaganatorCategoryEnableDialog"
  StaticPopupDialogs[enableDialog] = {
    text = BAGANATOR_L_ENABLE_CATEGORY_MODE_WARNING,
    button1 = ENABLE,
    button2 = CANCEL,
    OnAccept = function()
      addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, "category")
      addonTable.Config.Set(addonTable.Config.Options.BANK_VIEW_TYPE, "category")
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if frame:IsVisible() and tIndexOf(addonTable.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      if addonTable.Config.Get("bag_view_type") ~= "category" and addonTable.Config.Get("bank_view_type") ~= "category" then
        StaticPopup_Hide(enableDialog)
        StaticPopup_Show(enableDialog)
      end
    end
  end)

  frame:SetScript("OnShow", function()
    for index, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
    ShowEditor("EditCategory")
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
  self:SetIndex(self.lastIndex or 1)
  self:RefreshOptions()

  local tabsWidth = self.Tabs[#self.Tabs]:GetRight() - self.Tabs[1]:GetLeft()

  self:SetWidth(math.max(self:GetWidth(), tabsWidth + 20))
end
