---@class addonTableBaganator
local addonTable = select(2, ...)

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
    text = addonTable.Locales.BAG_VIEW_TYPE,
    option = "bag_view_type",
    entries = {
      addonTable.Locales.SINGLE_BAG,
      addonTable.Locales.CATEGORY_GROUPS,
    },
    values = {
      "single",
      "category",
    }
  },
  {
    type = "dropdown",
    text = addonTable.Locales.BANK_VIEW_TYPE,
    option = "bank_view_type",
    entries = {
      addonTable.Locales.SINGLE_BAG,
      addonTable.Locales.CATEGORY_GROUPS,
    },
    values = {
      "single",
      "category",
    }
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = addonTable.Locales.SHOW_BUTTONS,
    option = "show_buttons_on_alt",
    entries = {
      addonTable.Locales.ALWAYS,
      addonTable.Locales.WHEN_HOLDING_ALT,
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
    text = addonTable.Locales.BAG_COLUMNS,
    option = "bag_view_width",
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = addonTable.Locales.BANK_COLUMNS,
    option = "bank_view_width",
    check = function() return not Syndicator.Constants.CharacterBankTabsActive or not addonTable.Constants.IsRetail end,
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = addonTable.Locales.BANK_COLUMNS,
    option = "character_bank_view_width",
    check = function() return Syndicator.Constants.CharacterBankTabsActive and addonTable.Constants.IsRetail end,
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = addonTable.Locales.WARBAND_BANK_COLUMNS,
    option = "warband_bank_view_width",
    check = function() return Syndicator.Constants.WarbandBankActive end,
  },
  {
    type = "slider",
    min = 1,
    max = 42,
    lowText = "1",
    highText = "42",
    text = addonTable.Locales.GUILD_BANK_COLUMNS,
    option = "guild_view_width",
    check = NotIsEraCheck,
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = addonTable.Locales.BLANK_SPACE,
    option = "bag_empty_space_at_top",
    entries = {
      addonTable.Locales.AT_THE_BOTTOM,
      addonTable.Locales.AT_THE_TOP,
    },
    values = {
      false,
      true,
    }
  },
  {
    type = "checkbox",
    text = addonTable.Locales.SEARCH_BOX,
    option = "show_search_box",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.RECENT_CHARACTER_TABS,
    option = "show_recents_tabs_main_view",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.REDUCE_UI_SPACING,
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
    text = addonTable.Locales.CATEGORY_SPACING,
    option = "category_horizontal_spacing_2",
    valuePattern = addonTable.Locales.PERCENTAGE_PATTERN,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.GROUP_IDENTICAL_ITEMS,
    rightText = addonTable.Locales.BRACKETS_CATEGORY_VIEW_ONLY,
    option = "category_item_grouping",
  },
  { type = "spacing" },
  {
    type = "checkbox",
    text = addonTable.Locales.LOCK_WINDOWS,
    option = "lock_frames",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.CHANGE_WINDOW_ANCHORS,
    option = "setting_anchors",
  },
}

local ICON_OPTIONS = {
  {
    type = "checkbox",
    text = addonTable.Locales.ITEM_QUALITY_TEXT_COLORS,
    option = "icon_text_quality_colors",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.GREY_JUNK_ITEMS,
    option = "icon_grey_junk",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.MARK_UNUSABLE_ITEMS_IN_RED,
    option = "icon_mark_unusable",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.FADE_ITEMS_NOT_MATCHING_SITUATION,
    option = "icon_context_fading",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.FLASH_DUPLICATE_ITEMS,
    rightText = addonTable.Locales.ALT_CLICK,
    option = "icon_flash_similar_alt",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.HIDE_BOE_STATUS_ON_COMMON_2,
    option = "hide_boe_on_common",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.NEW_ITEMS_FLASHING_ANIMATION,
    option = "new_items_flashing",
  },
  { type = "spacing" },
  {
    type = "slider",
    min = 10,
    max = 70,
    lowText = "10",
    highText = "70",
    text = addonTable.Locales.ICON_SIZE,
    valuePattern = addonTable.Locales.PIXEL_PATTERN,
    option = "bag_icon_size",
  },
  {
    type = "slider",
    min = 5,
    max = 40,
    lowText = "5",
    highText = "40",
    text = addonTable.Locales.ICON_TEXT_FONT_SIZE,
    valuePattern = addonTable.Locales.PIXEL_PATTERN,
    option = "icon_text_font_size",
  },
  { type = "spacing" },
  {
    type = "header",
    text = addonTable.Locales.ICON_CORNERS,
    level = 2,
  },
}
local OPEN_CLOSE_OPTIONS = {
  {
    type = "checkbox",
    text = addonTable.Locales.BANK,
    option = "auto_open.bank",
  },
  {
    type = "checkbox",
    text = GUILD_BANK,
    option = "auto_open.guild_bank",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = TRADE,
    option = "auto_open.trade_partner",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.CRAFTING_WINDOW,
    option = "auto_open.tradeskill",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.AUCTION_HOUSE,
    option = "auto_open.auction_house",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.VOID_STORAGE,
    option = "auto_open.void_storage",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.MAIL,
    option = "auto_open.mail",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.VENDOR,
    option = "auto_open.merchant",
  },
  {
    type = "checkbox",
    text = addonTable.Locales.ITEM_UPGRADE,
    option = "auto_open.item_upgrade",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.CATALYST,
    option = "auto_open.item_interaction",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.SOCKET_INTERFACE,
    option = "auto_open.sockets",
    check = NotIsEraCheck,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.SCRAPPING_MACHINE,
    option = "auto_open.scrapping_machine",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.FORGE_OF_BONDS,
    option = "auto_open.forge_of_bonds",
    check = IsRetailCheck,
  },
  {
    type = "checkbox",
    text = addonTable.Locales.CHARACTER_PANEL,
    option = "auto_open.character_panel",
  },
}
local SORTING_OPTIONS = {
  {
    type = "checkbox",
    text = addonTable.Locales.SHOW_SORT_BUTTON,
    option = "show_sort_button_2",
  },
  { type = "spacing" },
  {
    type = "checkbox",
    text = addonTable.Locales.SORT_ON_OPEN,
    option = "auto_sort_on_open",
  },
  { type = "spacing" },
  { type = "spacing" },
  {
    type = "checkbox",
    text = addonTable.Locales.REVERSE_GROUPS_SORT_ORDER,
    option = "reverse_groups_sort_order",
  },
  {
    type = "dropdown",
    text = addonTable.Locales.ARRANGE_ITEMS,
    option = "sort_start_at_bottom",
    entries = {
      addonTable.Locales.FROM_THE_TOP,
      addonTable.Locales.FROM_THE_BOTTOM,
    },
    values = {
      false,
      true,
    }
  },
  { type = "spacing" },
  {
    type = "dropdown",
    text = addonTable.Locales.IGNORED_SLOTS,
    option = "sort_ignore_slots_at_end",
    entries = {
      addonTable.Locales.FROM_THE_TOP,
      addonTable.Locales.FROM_THE_BOTTOM,
    },
    values = {
      false,
      true,
    }
  },
  {
    type = "slider",
    min = 0,
    max = 240,
    lowText = "0",
    highText = "240",
    text = addonTable.Locales.IGNORED_BAG_SLOTS,
    option = "sort_ignore_slots_count_2",
  },
  {
    type = "slider",
    min = 0,
    max = 500,
    lowText = "0",
    highText = "500",
    text = addonTable.Locales.IGNORED_BANK_SLOTS,
    option = "sort_ignore_bank_slots_count",
  },
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
  self:SetScript("OnMouseWheel", function() end)

  self:SetTitle(addonTable.Locales.CUSTOMISE_BAGANATOR)

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

  addonTable.Skins.AddFrame("ButtonFrame", self, {"customise"})
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
  tab:SetText(addonTable.Locales.GENERAL)

  local frame = GetWrapperFrame(self)

  local infoInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")

  local options = CopyTable(GENERAL_OPTIONS)

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
    name:SetText(addonTable.Locales.BAGANATOR)
    name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, 0)

    local credit = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    credit:SetText(addonTable.Locales.BY_PLUSMOUSE)
    credit:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 5, 0)

    local discordButton = CreateFrame("Button", nil, infoInset, "UIPanelDynamicResizeButtonTemplate")
    discordButton:SetText(addonTable.Locales.JOIN_THE_DISCORD)
    DynamicResizeButton_Resize(discordButton)
    discordButton:SetPoint("BOTTOMLEFT", logo, "BOTTOMRIGHT", 8, 0)
    discordButton:SetScript("OnClick", function()
      addonTable.Dialogs.ShowCopy("https://discord.gg/TtSN6DxSky")
    end)
    addonTable.Skins.AddFrame("Button", discordButton)
    local discordText = infoInset:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    discordText:SetPoint("LEFT", discordButton, "RIGHT", 10, 0)
    discordText:SetText(addonTable.Locales.DISCORD_DESCRIPTION)
  end

  do
    local junkPlugins = {
      {label = addonTable.Locales.POOR_QUALITY, id = "poor_quality"},
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
      text = addonTable.Locales.JUNK_DETECTION_2,
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

    table.insert(options, dropdown)
  end

  do
    local upgradePlugins = {
      {label = addonTable.Locales.NONE, id = "none"},
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
      text = addonTable.Locales.UPGRADE_DETECTION,
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

    table.insert(options, dropdown)
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
        text = addonTable.Locales.TIPS_SEARCH,
      }, {
        header = addonTable.Locales.PLUGINS,
        text = addonTable.Locales.TIPS_PLUGINS,
      }),
      MakeTipsRow({
        header = CreateTextureMarkup("Interface\\AddOns\\Baganator\\Assets\\Transfer.png", 64, 64, 13, 13, 0, 1, 0, 1) .. " " .. addonTable.Locales.TRANSFER,
        text = addonTable.Locales.TIPS_TRANSFER,
      }, {
        header = addonTable.Locales.THEMES,
        text = addonTable.Locales.TIPS_THEMES,
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

  do
    local DONATE_OPTIONS = {{
      type = "header",
      text = addonTable.Locales.DEVELOPMENT_IS_TIME_CONSUMING,
      level = 2,
    }}
    local optionFrames = GenerateFrames(DONATE_OPTIONS, frame)
    optionFrames[1]:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, 0)
    tAppendAll(allFrames, optionFrames)

    local donateFrame = CreateFrame("Frame", nil, frame)
    donateFrame:SetPoint("LEFT")
    donateFrame:SetPoint("RIGHT")
    donateFrame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
    donateFrame:SetHeight(40)
    local text = donateFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("RIGHT", donateFrame, "CENTER", -50, 0)
    text:SetText(addonTable.Locales.DONATE)
    text:SetJustifyH("RIGHT")

    local button = CreateFrame("Button", nil, donateFrame, "UIPanelDynamicResizeButtonTemplate")
    button:SetText(addonTable.Locales.LINK)
    DynamicResizeButton_Resize(button)
    button:SetPoint("LEFT", donateFrame, "CENTER", -35, 0)
    button:SetScript("OnClick", function()
      addonTable.Dialogs.ShowCopy("https://linktr.ee/plusmouse")
    end)
    addonTable.Skins.AddFrame("Button", button)
    table.insert(allFrames, donateFrame)
  end

  local profileDropdown = addonTable.CustomiseDialog.GetBasicDropdown(frame)
  profileDropdown.Label:SetText(addonTable.Locales.PROFILES)
  do
    profileDropdown.SetValue = nil

    local clone = false
    local function ValidateAndCreate(profileName)
      if profileName ~= "" and BAGANATOR_CONFIG.Profiles[profileName] == nil then
        addonTable.Config.MakeProfile(profileName, clone)
        profileDropdown.DropDown:GenerateMenu()
        if not clone then
          addonTable.ShowWelcome()
        end
      end
    end
    profileDropdown:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)
    profileDropdown.DropDown:SetupMenu(function(menu, rootDescription)
      local profiles = addonTable.Config.GetProfileNames()
      table.sort(profiles, function(a, b) return a:lower() < b:lower() end)
      for _, name in ipairs(profiles) do
        local button = rootDescription:CreateRadio(name ~= "DEFAULT" and name or LIGHTBLUE_FONT_COLOR:WrapTextInColorCode(DEFAULT), function()
          return BAGANATOR_CURRENT_PROFILE == name
        end, function()
          addonTable.Config.ChangeProfile(name)
        end)
        if name ~= "DEFAULT" and name ~= BAGANATOR_CURRENT_PROFILE then
          button:AddInitializer(function(button, description, menu)
            local delete = MenuTemplates.AttachAutoHideButton(button, "transmog-icon-remove")
            delete:SetPoint("RIGHT")
            delete:SetSize(18, 18)
            delete.Texture:SetAtlas("transmog-icon-remove")
            delete:SetScript("OnClick", function()
              menu:Close()
              addonTable.Dialogs.ShowConfirm(addonTable.Locales.CONFIRM_DELETE_PROFILE_X:format(name), YES, NO, function()
                addonTable.Config.DeleteProfile(name)
              end)
            end)
            MenuUtil.HookTooltipScripts(delete, function(tooltip)
              GameTooltip_SetTitle(tooltip, DELETE);
            end);
          end)
        end
      end
      rootDescription:CreateButton(NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.NEW_PROFILE_CLONE), function()
        clone = true
        addonTable.Dialogs.ShowEditBox(addonTable.Locales.ENTER_PROFILE_NAME, ACCEPT, CANCEL, ValidateAndCreate)
      end)
      rootDescription:CreateButton(NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.NEW_PROFILE_BLANK), function()
        clone = false
        addonTable.Dialogs.ShowEditBox(addonTable.Locales.ENTER_PROFILE_NAME, ACCEPT, CANCEL, ValidateAndCreate)
      end)
    end)
  end
  table.insert(allFrames, profileDropdown)

  do
    local optionFrames = GenerateFrames(options, frame)
    optionFrames[1]:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -30)

    tAppendAll(allFrames, optionFrames)
  end

  local tooltipButtonFrame = CreateFrame("Frame", nil, frame)
  do
    tooltipButtonFrame:SetPoint("LEFT")
    tooltipButtonFrame:SetPoint("RIGHT")
    tooltipButtonFrame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM")
    tooltipButtonFrame:SetHeight(40)
    local text = tooltipButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("RIGHT", tooltipButtonFrame, "CENTER", -50, 0)
    text:SetText(addonTable.Locales.TOOLTIP_SETTINGS)
    text:SetJustifyH("RIGHT")
    local button = CreateFrame("Button", nil, tooltipButtonFrame, "UIPanelDynamicResizeButtonTemplate")
    button:SetText(addonTable.Locales.OPEN_SYNDICATOR)
    DynamicResizeButton_Resize(button)
    button:SetPoint("LEFT", tooltipButtonFrame, "CENTER", -35, 0)
    button:SetScript("OnClick", function()
      Settings.OpenToCategory(Syndicator.Locales.SYNDICATOR)
    end)
    addonTable.Skins.AddFrame("Button", button)
    table.insert(allFrames, tooltipButtonFrame)
  end

  frame:SetScript("OnShow", function()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  profileDropdown.DropDown:SetEnabled(not InCombatLockdown())
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", function(_, eventName)
    profileDropdown.DropDown:SetEnabled(eventName == "PLAYER_REGEN_ENABLED")
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupIcon()
  local tab = GetTab(self)
  tab:SetText(addonTable.Locales.ICONS)

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
  itemButton.SlotBackground = itemButton:CreateTexture(nil, "BACKGROUND")
  itemButton:SetPoint("CENTER", cornersEditor, 0, 0)
  addonTable.Skins.AddFrame("ItemButton", itemButton)

  frame:SetScript("OnShow", function()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupOpenClose()
  local tab = GetTab(self)
  tab:SetText(addonTable.Locales.AUTO_OPEN)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(OPEN_CLOSE_OPTIONS, frame)

  frame:SetScript("OnShow", function()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupSorting()
  local tab = GetTab(self)
  tab:SetText(addonTable.Locales.SORTING)

  local options = CopyTable(SORTING_OPTIONS)

  local frame = GetWrapperFrame(self)

  do
    local commonModes = {
      {"type", addonTable.Locales.ITEM_TYPE},
      {"name", addonTable.Locales.ITEM_NAME},
      {"quality", addonTable.Locales.ITEM_QUALITY},
      {"item-level", addonTable.Locales.ITEM_LEVEL},
      {"expansion", addonTable.Locales.EXPANSION},
    }

    local rawModes = {
      {"combine_stacks_only", addonTable.Locales.COMBINE_STACKS_ONLY},
    }

    for id, details in pairs(addonTable.API.ExternalContainerSorts) do
      table.insert(rawModes, {id, details.label})
    end
    tAppendAll(rawModes, commonModes)

    table.insert(commonModes, {"manual", addonTable.Locales.MANUAL})

    table.sort(commonModes, function(a, b) return a[2] < b[2] end)
    table.sort(rawModes, function(a, b) return a[2] < b[2] end)

    local category = {
      type = "dropdown",
      text = addonTable.Locales.CATEGORY_SORT_METHOD,
      option = "category_sort_method",
      entries = {},
      values = {},
    }

    local raw = {
      type = "dropdown",
      text = addonTable.Locales.SORT_METHOD_2,
      option = "sort_method",
      entries = {},
      values = {},
    }

    for _, details in ipairs(commonModes) do
      if addonTable.Sorting.IsModeAvailable(details[1]) then
        table.insert(category.values, details[1])
        table.insert(category.entries, details[2])
      end
    end

    for _, details in ipairs(rawModes) do
      if addonTable.Sorting.IsModeAvailable(details[1]) then
        table.insert(raw.values, details[1])
        table.insert(raw.entries, details[2])
      end
    end

    if not addonTable.Sorting.IsModeAvailable(addonTable.Config.Get("sort_method")) then
      addonTable.Config.ResetOne("sort_method")
    end

    if not addonTable.Sorting.IsModeAvailable(addonTable.Config.Get("category_sort_method")) then
      addonTable.Config.ResetOne("category_sort_method")
    end

    table.insert(options, 5, raw)
    table.insert(options, 6, category)
  end

  local allFrames = GenerateFrames(options, frame)

  frame:SetScript("OnShow", function()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupLayout()
  local tab = GetTab(self)
  tab:SetText(addonTable.Locales.LAYOUT)

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(LAYOUT_OPTIONS, frame)

  local function UpdateValues()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
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

  local _, resetAnchor = FindInTableIf(allFrames, function(f) return f.text == addonTable.Locales.LOCK_WINDOWS end)
  frame.ResetFramePositions = CreateFrame("Button", nil, frame, "UIPanelDynamicResizeButtonTemplate")
  frame.ResetFramePositions:SetPoint("LEFT", resetAnchor, "CENTER", 55, 0)
  frame.ResetFramePositions:SetText(addonTable.Locales.RESET_POSITIONS)
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
  tab:SetText(addonTable.Locales.THEME)

  local chooseSkinValues = {}
  for key in pairs(addonTable.Skins.availableSkins) do
    table.insert(chooseSkinValues, key)
  end
  table.sort(chooseSkinValues)
  local chooseSkinEntries = {}
  for _, key in ipairs(chooseSkinValues) do
    table.insert(chooseSkinEntries, addonTable.Skins.availableSkins[key].label)
  end

  local options = {}

  table.insert(options, {
    type = "dropdown",
    text = addonTable.Locales.THEME,
    option = "current_skin",
    entries = chooseSkinEntries,
    values = chooseSkinValues,
  })

  local currentSkinKey = addonTable.Config.Get(addonTable.Config.Options.CURRENT_SKIN)
  for _, opt in ipairs(addonTable.Skins.availableSkins[currentSkinKey].options) do
    local processedOpt = CopyTable(opt)
    if processedOpt.option then
       processedOpt.option = "skins." .. currentSkinKey .. "." ..  processedOpt.option
    end
    table.insert(options,  processedOpt)
  end

  local frame = GetWrapperFrame(self)

  local allFrames = GenerateFrames(options, frame)

  frame:SetScript("OnShow", function()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
  end)

  allFrames[1].DropDown:SetEnabled(not InCombatLockdown())
  frame:RegisterEvent("PLAYER_REGEN_DISABLED")
  frame:RegisterEvent("PLAYER_REGEN_ENABLED")
  frame:SetScript("OnEvent", function(_, eventName)
    allFrames[1].DropDown:SetEnabled(eventName == "PLAYER_REGEN_ENABLED")
  end)

  table.insert(self.lowestFrames, allFrames[#allFrames])
end

function BaganatorCustomiseDialogMixin:SetupCategoriesOptions()
  local tab = GetTab(self)
  tab:SetText(addonTable.Locales.CATEGORIES)

  local frame = GetWrapperFrame(self)

  local allFrames = {}

  local showAddButtons, editorHeader = unpack(GenerateFrames({{
    type = "dropdown",
    text = addonTable.Locales.SHOW_ADD_BUTTONS,
    option = "add_to_category_buttons_2",
    entries = {
      addonTable.Locales.DRAGGING,
      addonTable.Locales.DRAGGING_THEN_ALT,
      addonTable.Locales.NEVER,
    },
    values = {
      "drag",
      "drag+alt",
      "never",
    }
  }, {
    type = "header",
    text = addonTable.Locales.EDIT,
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
      if not self:IsVisible() then
        return
      end
      ShowEditor(event)
    end)
    editor.Return = function()
      categoriesEditor:Disable()
      ShowEditor("EditCategory")
      addonTable.CallbackRegistry:TriggerEvent("ResetCategoryEditor")
    end
  end

  local categoriesOrder = addonTable.CustomiseDialog.GetCategoriesOrganiser(frame)
  categoriesOrder:SetPoint("TOP")
  table.insert(allFrames, categoriesOrder)
  categoriesOrder:SetPoint("LEFT", frame, addonTable.Constants.ButtonFrameOffset + 20, 0)
  categoriesOrder:SetPoint("RIGHT", frame, "CENTER")

  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if frame:IsVisible() and tIndexOf(addonTable.CategoryViews.Constants.RedisplaySettings, settingName) ~= nil then
      if addonTable.Config.Get("bag_view_type") ~= "category" and addonTable.Config.Get("bank_view_type") ~= "category" then
        addonTable.Dialogs.ShowConfirm(addonTable.Locales.ENABLE_CATEGORY_MODE_WARNING, ENABLE, CANCEL, function()
          addonTable.Config.Set(addonTable.Config.Options.BAG_VIEW_TYPE, "category")
          addonTable.Config.Set(addonTable.Config.Options.BANK_VIEW_TYPE, "category")
        end)
      end
    end
  end)

  local prevTooltips = {}
  frame:SetScript("OnHide", function()
    addonTable.Config.Set(addonTable.Config.Options.DEBUG_KEYWORDS, prevTooltips.keywords)
    frame:UnregisterEvent("PLAYER_LOGOUT")
  end)
  -- Ensure the setting resets if the player does /reload  or /logout
  frame:SetScript("OnEvent", function()
    addonTable.Config.Set(addonTable.Config.Options.DEBUG_KEYWORDS, prevTooltips.keywords)
  end)
  frame:SetScript("OnShow", function()
    for _, frame in ipairs(allFrames) do
      if frame.SetValue then
        frame:SetValue(addonTable.Config.Get(frame.option))
      end
    end
    ShowEditor("EditCategory")

    prevTooltips = {
      keywords = addonTable.Config.Get(addonTable.Config.Options.DEBUG_KEYWORDS),
    }
    addonTable.Config.Set(addonTable.Config.Options.DEBUG_KEYWORDS, true)
    frame:RegisterEvent("PLAYER_LOGOUT")
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
