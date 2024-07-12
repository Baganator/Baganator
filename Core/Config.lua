Baganator.Config = {}

Baganator.Config.Options = {
  VIEW_TYPE = "view_type",
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

  MAIN_VIEW_POSITION = "main_view_position",
  MAIN_VIEW_SHOW_BAG_SLOTS = "main_view_show_bag_slots",
  BANK_ONLY_VIEW_POSITION = "bank_only_view_position",
  BANK_ONLY_VIEW_SHOW_BAG_SLOTS = "bank_only_view_show_bag_slots",
  GUILD_VIEW_POSITION = "guild_view_position",
  GUILD_VIEW_DIALOG_POSITION = "guild_view_dialog_position",
  SHOW_BUTTONS_ON_ALT = "show_buttons_on_alt",
  CHARACTER_SELECT_POSITION = "character_select_position",

  DEBUG = "debug",
  DEBUG_TIMERS = "debug_timers",
  DEBUG_KEYWORDS = "debug_keywords",

  AUTO_OPEN = "auto_open",

  GUILD_BANK_SORT_METHOD = "guild_bank_sort_method",

  CUSTOM_CATEGORIES = "custom_categories",
  CATEGORY_MODIFICATIONS = "category_modifications",
  CATEGORY_MIGRATION = "category_migration",
  AUTOMATIC_CATEGORIES_ADDED = "automatic_categories_added",
  CATEGORY_DISPLAY_ORDER = "category_display_order",
  CATEGORY_HIDDEN = "category_hidden",
  CATEGORY_SECTION_TOGGLED = "category_section_toggled",
  CATEGORY_HORIZONTAL_SPACING = "category_horizontal_spacing",
  CATEGORY_ITEM_GROUPING = "category_item_grouping",
}

Baganator.Config.Defaults = {
  [Baganator.Config.Options.VIEW_TYPE] = "single", -- "single" or "category"
  [Baganator.Config.Options.SEEN_WELCOME] = 0,

  [Baganator.Config.Options.BAG_VIEW_WIDTH] = 12,
  [Baganator.Config.Options.BANK_VIEW_WIDTH] = Baganator.Constants.IsRetail and 24 or 18,
  [Baganator.Config.Options.WARBAND_BANK_VIEW_WIDTH] = 14,
  [Baganator.Config.Options.GUILD_VIEW_WIDTH] = 14,
  [Baganator.Config.Options.BAG_ICON_SIZE] = 37,
  [Baganator.Config.Options.VIEW_ALPHA] = 1,
  [Baganator.Config.Options.LOCK_FRAMES] = false,
  [Baganator.Config.Options.NO_FRAME_BORDERS] = false,
  [Baganator.Config.Options.EMPTY_SLOT_BACKGROUND] = false,
  [Baganator.Config.Options.HIDE_SPECIAL_CONTAINER] = {},
  [Baganator.Config.Options.SHOW_SORT_BUTTON] = true,
  [Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW] = {},
  [Baganator.Config.Options.HIDE_BOE_ON_COMMON] = false,
  [Baganator.Config.Options.SHOW_RECENTS_TABS] = false,
  [Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS] = false,
  [Baganator.Config.Options.MAIN_VIEW_POSITION] = {"RIGHT", -20, 0},
  [Baganator.Config.Options.BANK_ONLY_VIEW_POSITION] = {"LEFT", 20, 0},
  [Baganator.Config.Options.GUILD_VIEW_POSITION] = {"LEFT", 20, 0},
  [Baganator.Config.Options.GUILD_VIEW_DIALOG_POSITION] = {"BOTTOM", "Baganator_GuildViewFrame", "TOP", 0, 0},
  [Baganator.Config.Options.CHARACTER_SELECT_POSITION] = {"RIGHT", "Baganator_BackpackViewFrame", "LEFT", 0, 0},
  [Baganator.Config.Options.ICON_TEXT_FONT_SIZE] = 14,
  [Baganator.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY] = {"junk", "item_level"},
  [Baganator.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY] = {},
  [Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY] = {"equipment_set"},
  [Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY] = {"quantity"},
  [Baganator.Config.Options.ICON_CORNERS_AUTO_INSERT_APPLIED] = {},
  [Baganator.Config.Options.ICON_GREY_JUNK] = false,
  [Baganator.Config.Options.ICON_EQUIPMENT_SET_BORDER] = true,
  [Baganator.Config.Options.AUTO_OPEN] = {},
  [Baganator.Config.Options.MAIN_VIEW_SHOW_BAG_SLOTS] = true,
  [Baganator.Config.Options.BANK_ONLY_VIEW_SHOW_BAG_SLOTS] = true,
  [Baganator.Config.Options.SHOW_BUTTONS_ON_ALT] = false,
  [Baganator.Config.Options.BAG_EMPTY_SPACE_AT_TOP] = false,
  [Baganator.Config.Options.REDUCE_SPACING] = false,
  [Baganator.Config.Options.SORT_METHOD] = "type",
  [Baganator.Config.Options.REVERSE_GROUPS_SORT_ORDER] = false,
  [Baganator.Config.Options.SORT_START_AT_BOTTOM] = false,
  [Baganator.Config.Options.ICON_FLASH_SIMILAR_ALT] = false,
  [Baganator.Config.Options.SORT_IGNORE_SLOTS_AT_END] = false,
  [Baganator.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT] = 0,
  [Baganator.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT] = 0,
  [Baganator.Config.Options.AUTO_SORT_ON_OPEN] = false,
  [Baganator.Config.Options.JUNK_PLUGIN] = "poor_quality",
  [Baganator.Config.Options.JUNK_PLUGINS_IGNORED] = {},

  [Baganator.Config.Options.DEBUG] = false,
  [Baganator.Config.Options.DEBUG_TIMERS] = false,
  [Baganator.Config.Options.DEBUG_KEYWORDS] = false,

  [Baganator.Config.Options.GUILD_BANK_SORT_METHOD] = "unset",

  [Baganator.Config.Options.CUSTOM_CATEGORIES] = {
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
  [Baganator.Config.Options.CATEGORY_MODIFICATIONS] = {
    --[[
    ["default_gem"] = {
      addedItems = {{itemID = 154128}, {petID = 2959}}, --stored by item id or pet id
    },
    ]]
  },
  [Baganator.Config.Options.CATEGORY_MIGRATION] = 0,
  [Baganator.Config.Options.AUTOMATIC_CATEGORIES_ADDED] = {},
  [Baganator.Config.Options.CATEGORY_DISPLAY_ORDER] = {},
  [Baganator.Config.Options.CATEGORY_HIDDEN] = {},
  [Baganator.Config.Options.CATEGORY_SECTION_TOGGLED] = {},
  [Baganator.Config.Options.CATEGORY_HORIZONTAL_SPACING] = 0.15,
  [Baganator.Config.Options.CATEGORY_ITEM_GROUPING] = true,
}

Baganator.Config.IsCharacterSpecific = {
  [Baganator.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT] = true,
  [Baganator.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT] = true,
}

Baganator.Config.VisualsFrameOnlySettings = {
  Baganator.Config.Options.VIEW_ALPHA,
  Baganator.Config.Options.NO_FRAME_BORDERS,
}

Baganator.Config.ItemButtonsRelayoutSettings = {
  Baganator.Config.Options.BAG_ICON_SIZE,
  Baganator.Config.Options.EMPTY_SLOT_BACKGROUND,
  Baganator.Config.Options.BAG_VIEW_WIDTH,
  Baganator.Config.Options.BANK_VIEW_WIDTH,
  Baganator.Config.Options.WARBAND_BANK_VIEW_WIDTH,
  Baganator.Config.Options.GUILD_VIEW_WIDTH,
  Baganator.Config.Options.SHOW_SORT_BUTTON,
  Baganator.Config.Options.HIDE_BOE_ON_COMMON,
  Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS,
  Baganator.Config.Options.ICON_TEXT_FONT_SIZE,
  Baganator.Config.Options.BAG_EMPTY_SPACE_AT_TOP,
  Baganator.Config.Options.ICON_GREY_JUNK,
  Baganator.Config.Options.REDUCE_SPACING,
  Baganator.Config.Options.JUNK_PLUGIN,
  Baganator.Config.Options.ICON_TOP_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_TOP_RIGHT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER_ARRAY,
  Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER_ARRAY,
}

function Baganator.Config.IsValidOption(name)
  for _, option in pairs(Baganator.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

function Baganator.Config.Create(constant, name, defaultValue)
  Baganator.Config.Options[constant] = name

  Baganator.Config.Defaults[Baganator.Config.Options[constant]] = defaultValue

  if BAGANATOR_CONFIG ~= nil and BAGANATOR_CONFIG[name] == nil then
    BAGANATOR_CONFIG[name] = defaultValue
  end
end

function Baganator.Config.Set(name, value)
  if BAGANATOR_CONFIG == nil then
    error("JOURNALATOR_CONFIG not initialized")
  elseif not Baganator.Config.IsValidOption(name) then
    error("Invalid option '" .. name .. "'")
  else
    local oldValue
    if Baganator.Config.IsCharacterSpecific[name] then
      local characterName = Baganator.Utilities.GetCharacterFullName()
      oldValue = BAGANATOR_CONFIG[name][characterName]
      BAGANATOR_CONFIG[name][characterName] = value
    else
      oldValue = BAGANATOR_CONFIG[name]
      BAGANATOR_CONFIG[name] = value
    end
    if value ~= oldValue then
      Baganator.CallbackRegistry:TriggerEvent("SettingChangedEarly", name)
      Baganator.CallbackRegistry:TriggerEvent("SettingChanged", name)
    end
  end
end

function Baganator.Config.ResetOne(name)
  local newValue = Baganator.Config.Defaults[name]
  if type(newValue) == "table" then
    newValue = CopyTable(newValue)
  end
  Baganator.Config.Set(name, newValue)
end

function Baganator.Config.Reset()
  BAGANATOR_CONFIG = {}
  for option, value in pairs(Baganator.Config.Defaults) do
    if Baganator.Config.IsCharacterSpecific[option] then
      BAGANATOR_CONFIG[option] = {}
    else
      BAGANATOR_CONFIG[option] = value
    end
  end
end

function Baganator.Config.InitializeData()
  if BAGANATOR_CONFIG == nil then
    Baganator.Config.Reset()
  else
    for option, value in pairs(Baganator.Config.Defaults) do
      if BAGANATOR_CONFIG[option] == nil then
        if Baganator.Config.IsCharacterSpecific[option] then
          BAGANATOR_CONFIG[option] = {}
        else
          BAGANATOR_CONFIG[option] = value
        end
      end
    end
  end
end

function Baganator.Config.Get(name)
  -- This is ONLY if a config is asked for before variables are loaded
  if BAGANATOR_CONFIG == nil then
    return Baganator.Config.Defaults[name]
  elseif Baganator.Config.IsCharacterSpecific[name] then
    local value = BAGANATOR_CONFIG[name][Baganator.Utilities.GetCharacterFullName()]
    if value == nil then
      return Baganator.Config.Defaults[name]
    else
      return value
    end
  else
    return BAGANATOR_CONFIG[name]
  end
end
