local _, addonTable = ...
addonTable.Config = {}

addonTable.Config.Options = {
  GLOBAL_VIEW_TYPE = "view_type",
  BAG_VIEW_TYPE = "bag_view_type",
  BANK_VIEW_TYPE = "bank_view_type",
  SEEN_WELCOME = "seen_welcome",
  BAG_VIEW_WIDTH = "bag_view_width",
  BANK_VIEW_WIDTH = "bank_view_width",
  WARBAND_BANK_VIEW_WIDTH = "warband_bank_view_width",
  GUILD_VIEW_WIDTH = "guild_view_width",
  BAG_ICON_SIZE = "bag_icon_size",
  VIEW_ALPHA = "view_alpha",
  LOCK_FRAMES = "lock_frames",
  NO_FRAME_BORDERS = "no_frame_borders",
  EMPTY_SLOT_BACKGROUND = "empty_slot_background",
  HIDE_SPECIAL_CONTAINER = "hide_special_container",
  SHOW_SORT_BUTTON = "show_sort_button_2",
  SORT_METHOD = "sort_method",
  REVERSE_GROUPS_SORT_ORDER = "reverse_groups_sort_order",
  SORT_START_AT_BOTTOM = "sort_start_at_bottom",
  SORT_IGNORE_SLOTS_AT_END = "sort_ignore_slots_at_end",
  SORT_IGNORE_BAG_SLOTS_COUNT = "sort_ignore_slots_count_2",
  SORT_IGNORE_BANK_SLOTS_COUNT = "sort_ignore_bank_slots_count",
  SHOW_RECENTS_TABS = "show_recents_tabs_main_view",
  AUTO_SORT_ON_OPEN = "auto_sort_on_open",
  BAG_EMPTY_SPACE_AT_TOP = "bag_empty_space_at_top",
  REDUCE_SPACING = "reduce_spacing",
  CURRENCY_HEADERS_COLLAPSED = "currency_headers_collapsed",
  CURRENCIES_TRACKED = "currencies_tracked",
  CURRENCIES_TRACKED_IMPORTED = "currencies_tracked_imported",

  WARBAND_CURRENT_TAB = "warband_current_tab",
  GUILD_CURRENT_TAB = "guild_current_tab",

  RECENT_CHARACTERS_MAIN_VIEW = "recent_characters_main_view",

  HIDE_BOE_ON_COMMON = "hide_boe_on_common",
  ICON_TEXT_QUALITY_COLORS = "icon_text_quality_colors",
  ICON_TEXT_FONT_SIZE = "icon_text_font_size",
  ICON_TOP_LEFT_CORNER_ARRAY = "icon_top_left_corner_array",
  ICON_TOP_RIGHT_CORNER_ARRAY = "icon_top_right_corner_array",
  ICON_BOTTOM_LEFT_CORNER_ARRAY = "icon_bottom_left_corner_array",
  ICON_BOTTOM_RIGHT_CORNER_ARRAY = "icon_bottom_right_corner_array",
  ICON_CORNERS_AUTO_INSERT_APPLIED = "icon_corners_auto_insert_applied",
  ICON_GREY_JUNK = "icon_grey_junk",
  ICON_EQUIPMENT_SET_BORDER = "icon_equipment_set_border",
  ICON_FLASH_SIMILAR_ALT = "icon_flash_similar_alt",

  JUNK_PLUGIN = "junk_plugin",
  JUNK_PLUGINS_IGNORED = "junk_plugin_ignored",
  UPGRADE_PLUGIN = "upgrade_plugin",
  UPGRADE_PLUGINS_IGNORED = "upgrade_plugin_ignored",

  MAIN_VIEW_POSITION = "main_view_position",
  MAIN_VIEW_SHOW_BAG_SLOTS = "main_view_show_bag_slots",
  BANK_ONLY_VIEW_POSITION = "bank_only_view_position",
  BANK_ONLY_VIEW_SHOW_BAG_SLOTS = "bank_only_view_show_bag_slots",
  GUILD_VIEW_POSITION = "guild_view_position",
  GUILD_VIEW_DIALOG_POSITION = "guild_view_dialog_position",
  SHOW_BUTTONS_ON_ALT = "show_buttons_on_alt",
  CHARACTER_SELECT_POSITION = "character_select_position",
  CURRENCY_PANEL_POSITION = "currency_panel_position",
  SETTING_ANCHORS = "setting_anchors",

  DEBUG_TIMERS = "debug_timers",
  DEBUG_KEYWORDS = "debug_keywords",
  DEBUG_CATEGORIES = "debug_categories",
  DEBUG_CATEGORIES_SEARCH = "debug_categories_search",

  AUTO_OPEN = "auto_open",

  GUILD_BANK_SORT_METHOD = "guild_bank_sort_method",

  CUSTOM_CATEGORIES = "custom_categories",
  CATEGORY_MODIFICATIONS = "category_modifications",
  CATEGORY_MIGRATION = "category_migration",
  CATEGORY_DEFAULT_IMPORT = "category_default_import",
  AUTOMATIC_CATEGORIES_ADDED = "automatic_categories_added",
  CATEGORY_DISPLAY_ORDER = "category_display_order",
  CATEGORY_HIDDEN = "category_hidden",
  CATEGORY_SECTION_TOGGLED = "category_section_toggled",
  CATEGORY_HORIZONTAL_SPACING = "category_horizontal_spacing_2",
  CATEGORY_ITEM_GROUPING = "category_item_grouping",
  CATEGORY_GROUP_EMPTY_SLOTS = "category_group_empty_slots",
  RECENT_TIMEOUT = "recent_timeout",
  ADD_TO_CATEGORY_BUTTONS = "add_to_category_buttons_2",
}

addonTable.Config.Defaults = {
  [addonTable.Config.Options.GLOBAL_VIEW_TYPE] = "unset",
  [addonTable.Config.Options.BAG_VIEW_TYPE] = "single", -- "single" or "category"
  [addonTable.Config.Options.BANK_VIEW_TYPE] = "single",
  [addonTable.Config.Options.SEEN_WELCOME] = 0,

  [addonTable.Config.Options.BAG_VIEW_WIDTH] = 12,
  [addonTable.Config.Options.BANK_VIEW_WIDTH] = addonTable.Constants.IsRetail and 24 or 18,
  [addonTable.Config.Options.WARBAND_BANK_VIEW_WIDTH] = 14,
  [addonTable.Config.Options.GUILD_VIEW_WIDTH] = 14,
  [addonTable.Config.Options.BAG_ICON_SIZE] = 37,
  [addonTable.Config.Options.VIEW_ALPHA] = 1,
  [addonTable.Config.Options.LOCK_FRAMES] = false,
  [addonTable.Config.Options.NO_FRAME_BORDERS] = false,
  [addonTable.Config.Options.EMPTY_SLOT_BACKGROUND] = false,
  [addonTable.Config.Options.HIDE_SPECIAL_CONTAINER] = {},
  [addonTable.Config.Options.SHOW_SORT_BUTTON] = true,
  [addonTable.Config.Options.RECENT_CHARACTERS_MAIN_VIEW] = {},
  [addonTable.Config.Options.HIDE_BOE_ON_COMMON] = false,
  [addonTable.Config.Options.SHOW_RECENTS_TABS] = false,
  [addonTable.Config.Options.ICON_TEXT_QUALITY_COLORS] = false,
  [addonTable.Config.Options.MAIN_VIEW_POSITION] = {"RIGHT", -20, 0},
  [addonTable.Config.Options.BANK_ONLY_VIEW_POSITION] = {"LEFT", 20, 0},
  [addonTable.Config.Options.GUILD_VIEW_POSITION] = {"LEFT", 20, 0},
  [addonTable.Config.Options.GUILD_VIEW_DIALOG_POSITION] = {"BOTTOM", "Baganator_GuildViewFrame", "TOP", 0, 0},
  [addonTable.Config.Options.CHARACTER_SELECT_POSITION] = {"RIGHT", "Baganator_BackpackViewFrame", "LEFT", 0, 0},
  [addonTable.Config.Options.CURRENCY_PANEL_POSITION] = {"RIGHT", "Baganator_BackpackViewFrame", "LEFT", 0, 0},
  [addonTable.Config.Options.ICON_TEXT_FONT_SIZE] = 14,
  [addonTable.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY] = {"junk", "item_level"},
  [addonTable.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY] = {},
  [addonTable.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY] = {"equipment_set"},
  [addonTable.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY] = {"quantity"},
  [addonTable.Config.Options.ICON_CORNERS_AUTO_INSERT_APPLIED] = {},
  [addonTable.Config.Options.ICON_GREY_JUNK] = false,
  [addonTable.Config.Options.ICON_EQUIPMENT_SET_BORDER] = true,
  [addonTable.Config.Options.AUTO_OPEN] = {},
  [addonTable.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS] = true,
  [addonTable.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS] = true,
  [addonTable.Config.Options.SHOW_BUTTONS_ON_ALT] = false,
  [addonTable.Config.Options.BAG_EMPTY_SPACE_AT_TOP] = false,
  [addonTable.Config.Options.REDUCE_SPACING] = false,
  [addonTable.Config.Options.SORT_METHOD] = "type",
  [addonTable.Config.Options.REVERSE_GROUPS_SORT_ORDER] = false,
  [addonTable.Config.Options.SORT_START_AT_BOTTOM] = false,
  [addonTable.Config.Options.ICON_FLASH_SIMILAR_ALT] = false,
  [addonTable.Config.Options.SORT_IGNORE_SLOTS_AT_END] = false,
  [addonTable.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT] = 0,
  [addonTable.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT] = 0,
  [addonTable.Config.Options.AUTO_SORT_ON_OPEN] = false,
  [addonTable.Config.Options.JUNK_PLUGIN] = "poor_quality",
  [addonTable.Config.Options.JUNK_PLUGINS_IGNORED] = {},
  [addonTable.Config.Options.UPGRADE_PLUGIN] = "none",
  [addonTable.Config.Options.UPGRADE_PLUGINS_IGNORED] = {},
  [addonTable.Config.Options.SETTING_ANCHORS] = false,
  [addonTable.Config.Options.WARBAND_CURRENT_TAB] = 1,
  [addonTable.Config.Options.GUILD_CURRENT_TAB] = 1,
  [addonTable.Config.Options.CURRENCY_HEADERS_COLLAPSED] = {},
  [addonTable.Config.Options.CURRENCIES_TRACKED] = {},
  [addonTable.Config.Options.CURRENCIES_TRACKED_IMPORTED] = 0,

  [addonTable.Config.Options.DEBUG_TIMERS] = false,
  [addonTable.Config.Options.DEBUG_KEYWORDS] = false,
  [addonTable.Config.Options.DEBUG_CATEGORIES] = false,
  [addonTable.Config.Options.DEBUG_CATEGORIES_SEARCH] = false,

  [addonTable.Config.Options.GUILD_BANK_SORT_METHOD] = "unset",

  [addonTable.Config.Options.CUSTOM_CATEGORIES] = {
    --[[
    ["Tinker Gems"] = { -- Search group
      name = "Tinker Gems",
      search = "gem&tinker",
      searchPriority = 250,
    },
    ["Special Gems"] = { -- Group with specific items in it
      name = "Special Gems",
      search = nil,
      searchPriority = 350,
    },
    ]]
  },
  [addonTable.Config.Options.CATEGORY_MODIFICATIONS] = {
    --[[
    ["default_gem"] = {
      addedItems = {["i:154128] = true, ["p:2959] = true}, --stored by item id or pet id
    },
    ]]
  },
  [addonTable.Config.Options.CATEGORY_MIGRATION] = 0,
  [addonTable.Config.Options.CATEGORY_DEFAULT_IMPORT] = 0,
  [addonTable.Config.Options.AUTOMATIC_CATEGORIES_ADDED] = {},
  [addonTable.Config.Options.CATEGORY_DISPLAY_ORDER] = {},
  [addonTable.Config.Options.CATEGORY_HIDDEN] = {},
  [addonTable.Config.Options.CATEGORY_SECTION_TOGGLED] = {},
  [addonTable.Config.Options.CATEGORY_HORIZONTAL_SPACING] = 0.30,
  [addonTable.Config.Options.CATEGORY_ITEM_GROUPING] = true,
  [addonTable.Config.Options.CATEGORY_GROUP_EMPTY_SLOTS] = true,
  [addonTable.Config.Options.ADD_TO_CATEGORY_BUTTONS] = "drag",
  [addonTable.Config.Options.RECENT_TIMEOUT] = 15,
}

addonTable.Config.IsCharacterSpecific = {
  [addonTable.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT] = true,
  [addonTable.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT] = true,
  [addonTable.Config.Options.CURRENCIES_TRACKED] = true,
  [addonTable.Config.Options.CURRENCIES_TRACKED_IMPORTED] = true,
}

addonTable.Config.VisualsFrameOnlySettings = {
  addonTable.Config.Options.VIEW_ALPHA,
  addonTable.Config.Options.NO_FRAME_BORDERS,
}

addonTable.Config.ItemButtonsRelayoutSettings = {
  addonTable.Config.Options.BAG_ICON_SIZE,
  addonTable.Config.Options.EMPTY_SLOT_BACKGROUND,
  addonTable.Config.Options.BAG_VIEW_WIDTH,
  addonTable.Config.Options.BANK_VIEW_WIDTH,
  addonTable.Config.Options.WARBAND_BANK_VIEW_WIDTH,
  addonTable.Config.Options.GUILD_VIEW_WIDTH,
  addonTable.Config.Options.SHOW_SORT_BUTTON,
  addonTable.Config.Options.HIDE_BOE_ON_COMMON,
  addonTable.Config.Options.ICON_TEXT_QUALITY_COLORS,
  addonTable.Config.Options.ICON_TEXT_FONT_SIZE,
  addonTable.Config.Options.BAG_EMPTY_SPACE_AT_TOP,
  addonTable.Config.Options.ICON_GREY_JUNK,
  addonTable.Config.Options.REDUCE_SPACING,
  addonTable.Config.Options.JUNK_PLUGIN,
  addonTable.Config.Options.UPGRADE_PLUGIN,
  addonTable.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY,
  addonTable.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY,
  addonTable.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY,
  addonTable.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY,
}

function addonTable.Config.IsValidOption(name)
  for _, option in pairs(addonTable.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

function addonTable.Config.Create(constant, name, defaultValue)
  addonTable.Config.Options[constant] = name

  addonTable.Config.Defaults[addonTable.Config.Options[constant]] = defaultValue

  if BAGANATOR_CONFIG ~= nil and BAGANATOR_CONFIG[name] == nil then
    BAGANATOR_CONFIG[name] = defaultValue
  end
end

function addonTable.Config.Set(name, value)
  if BAGANATOR_CONFIG == nil then
    error("JOURNALATOR_CONFIG not initialized")
  elseif not addonTable.Config.IsValidOption(name) then
    error("Invalid option '" .. name .. "'")
  else
    local oldValue
    if addonTable.Config.IsCharacterSpecific[name] then
      local characterName = Syndicator.API.GetCurrentCharacter()
      oldValue = BAGANATOR_CONFIG[name][characterName]
      BAGANATOR_CONFIG[name][characterName] = value
    else
      oldValue = BAGANATOR_CONFIG[name]
      BAGANATOR_CONFIG[name] = value
    end
    if value ~= oldValue then
      addonTable.CallbackRegistry:TriggerEvent("SettingChangedEarly", name)
      addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    end
  end
end

function addonTable.Config.ResetOne(name)
  local newValue = addonTable.Config.Defaults[name]
  if type(newValue) == "table" then
    newValue = CopyTable(newValue)
  end
  addonTable.Config.Set(name, newValue)
end

function addonTable.Config.Reset()
  BAGANATOR_CONFIG = {}
  for option, value in pairs(addonTable.Config.Defaults) do
    if addonTable.Config.IsCharacterSpecific[option] then
      BAGANATOR_CONFIG[option] = {}
    else
      BAGANATOR_CONFIG[option] = value
    end
  end
end

function addonTable.Config.InitializeData()
  if BAGANATOR_CONFIG == nil then
    addonTable.Config.Reset()
  else
    for option, value in pairs(addonTable.Config.Defaults) do
      if BAGANATOR_CONFIG[option] == nil then
        if addonTable.Config.IsCharacterSpecific[option] then
          BAGANATOR_CONFIG[option] = {}
        else
          BAGANATOR_CONFIG[option] = value
        end
      end
    end
  end
end

-- characterName is optional, only use if need a character specific setting for
-- a character other than the current one.
function addonTable.Config.Get(name, characterName)
  -- This is ONLY if a config is asked for before variables are loaded
  if BAGANATOR_CONFIG == nil then
    return addonTable.Config.Defaults[name]
  elseif addonTable.Config.IsCharacterSpecific[name] then
    local value = BAGANATOR_CONFIG[name][characterName or Syndicator.API.GetCurrentCharacter()]
    if value == nil then
      return addonTable.Config.Defaults[name]
    else
      return value
    end
  else
    return BAGANATOR_CONFIG[name]
  end
end
