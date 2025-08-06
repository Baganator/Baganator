---@class addonTableBaganator
local addonTable = select(2, ...)
addonTable.Config = {}

local Refresh = addonTable.Constants.RefreshReason
local Zone = addonTable.Constants.RefreshZone
local settings = {
  GLOBAL_VIEW_TYPE = {key = "view_type", default = "unset"},
  BAG_VIEW_TYPE = {key = "bag_view_type", default = "single"},
  BANK_VIEW_TYPE = {key = "bank_view_type", default = "single"},
  SEEN_WELCOME = {key = "seen_welcome", default = 0},
  BAG_VIEW_WIDTH = {key = "bag_view_width", default = 12, refresh = {Refresh.Layout}, zone = {Zone.Bags}},
  BANK_VIEW_WIDTH = {key = "bank_view_width", default = addonTable.Constants.IsRetail and 24 or 18, refresh = {Refresh.Layout}, zone = {Zone.CharacterBank}},
  CHARACTER_BANK_VIEW_WIDTH = {key = "character_bank_view_width", default = 14, refresh = {Refresh.Layout}, zone = {Zone.CharacterBank}},
  WARBAND_BANK_VIEW_WIDTH = {key = "warband_bank_view_width", default = 14, refresh = {Refresh.Layout}, zone = {Zone.WarbandBank}},
  GUILD_VIEW_WIDTH = {key = "guild_view_width", default = 14, refresh = {Refresh.Layout}, zone = {Zone.GuildBank}},
  BAG_ICON_SIZE = {key = "bag_icon_size", default = 37, refresh = {Refresh.Layout, Refresh.Flow}},
  LOCK_FRAMES = {key = "lock_frames", default = false},
  HIDE_SPECIAL_CONTAINER = {key = "hide_special_container", default = {}, refresh = {Refresh.Layout}, zone = {Zone.Bags, Zone.CharacterBank}},
  SHOW_SORT_BUTTON = {key = "show_sort_button_2", default = true, refresh = {Refresh.Buttons}},
  SORT_METHOD = {key = "sort_method", default = "type"},
  CATEGORY_SORT_METHOD = {key = "category_sort_method", default = "type", refresh = {Refresh.Sorts}},
  MIGRATED_SORT_METHOD = {key = "migrated_sort_method", default = false},
  REVERSE_GROUPS_SORT_ORDER = {key = "reverse_groups_sort_order", default = false, refresh = {Refresh.Sorts}},
  SORT_START_AT_BOTTOM = {key = "sort_start_at_bottom", default = false},
  SORT_IGNORE_SLOTS_AT_END = {key = "sort_ignore_slots_at_end", default = false},
  SORT_IGNORE_BAG_SLOTS_COUNT = {key = "sort_ignore_slots_count_2", default = 0},
  SORT_IGNORE_BANK_SLOTS_COUNT = {key = "sort_ignore_bank_slots_count", default = 0},
  SHOW_RECENTS_TABS = {key = "show_recents_tabs_main_view", default = false, refresh = {Refresh.Layout}},
  AUTO_SORT_ON_OPEN = {key = "auto_sort_on_open", default = false},
  BAG_EMPTY_SPACE_AT_TOP = {key = "bag_empty_space_at_top", default = false, refresh = {Refresh.Flow, Refresh.Layout}},
  REDUCE_SPACING = {key = "reduce_spacing", default = false, refresh = {Refresh.Layout, Refresh.Flow}},
  CURRENCY_HEADERS_COLLAPSED = {key = "currency_headers_collapsed", default = {}},
  CURRENCIES_TRACKED = {key = "currencies_tracked", default = {}},
  CURRENCIES_TRACKED_IMPORTED = {key = "currencies_tracked_imported", default = 0},
  SHOW_SEARCH_BOX = {key = "show_search_box", default = true, refresh = {Refresh.Layout}},

  BANK_CURRENT_TAB = {key = "bank_current_tab", default = 1},
  CHARACTER_BANK_CURRENT_TAB = {key = "character_bank_current_tab", default = 1},
  WARBAND_CURRENT_TAB = {key = "warband_current_tab", default = 1},
  GUILD_CURRENT_TAB = {key = "guild_current_tab", default = 1},

  RECENT_CHARACTERS_MAIN_VIEW = {key = "recent_characters_main_view", default = {}},

  HIDE_BOE_ON_COMMON = {key = "hide_boe_on_common", default = false, refresh = {Refresh.ItemWidgets}},
  ICON_TEXT_QUALITY_COLORS = {key = "icon_text_quality_colors", default = false, refresh = {Refresh.ItemWidgets}},
  ICON_MARK_UNUSABLE  = {key = "icon_mark_unusable", default = false, refresh = {Refresh.ItemWidgets}},
  ICON_TEXT_FONT_SIZE = {key = "icon_text_font_size", default = 14, refresh = {Refresh.ItemTextures}},
  ICON_TOP_LEFT_CORNER_ARRAY = {key = "icon_top_left_corner_array", default = {"junk", "item_level"}, refresh = {Refresh.ItemTextures, Refresh.ItemWidgets}},
  ICON_TOP_RIGHT_CORNER_ARRAY = {key = "icon_top_right_corner_array", default = {}, refresh = {Refresh.ItemTextures, Refresh.ItemWidgets}},
  ICON_BOTTOM_LEFT_CORNER_ARRAY = {key = "icon_bottom_left_corner_array", default = {"equipment_set"}, refresh = {Refresh.ItemTextures, Refresh.ItemWidgets}},
  ICON_BOTTOM_RIGHT_CORNER_ARRAY = {key = "icon_bottom_right_corner_array", default = {"quantity"}, refresh = {Refresh.ItemTextures, Refresh.ItemWidgets}},
  ICON_CORNERS_AUTO_INSERT_APPLIED = {key = "icon_corners_auto_insert_applied", default = {}},
  ICON_GREY_JUNK = {key = "icon_grey_junk", default = false, refresh = {Refresh.ItemWidgets}},
  ICON_EQUIPMENT_SET_BORDER = {key = "icon_equipment_set_border", default = true, refresh = {Refresh.ItemWidgets}},
  ICON_FLASH_SIMILAR_ALT = {key = "icon_flash_similar_alt", default = false},
  ICON_CONTEXT_FADING = {key = "icon_context_fading", default = true, refresh = {Refresh.ItemWidgets}},
  NEW_ITEMS_FLASHING = {key = "new_items_flashing", default = true},

  JUNK_PLUGIN = {key = "junk_plugin", default = "poor_quality", refresh = {Refresh.Searches, Refresh.ItemWidgets}},
  JUNK_PLUGINS_IGNORED = {key = "junk_plugin_ignored", default = {}},
  UPGRADE_PLUGIN = {key = "upgrade_plugin", default = "none", refresh = {Refresh.Searches, Refresh.ItemWidgets}},
  UPGRADE_PLUGINS_IGNORED = {key = "upgrade_plugin_ignored", default = {}},

  MAIN_VIEW_POSITION = {key = "bag_view_position", default = {"BOTTOMRIGHT", addonTable.Constants.IsRetail and -115 or -30, 85}},
  MAIN_VIEW_SHOW_BAG_SLOTS = {key = "bag_view_show_bag_slots", default = false, refresh = {Refresh.Buttons}, zone = {Zone.Bags}},
  BANK_ONLY_VIEW_POSITION = {key = "bank_view_position", default = {"BOTTOMLEFT", 30, addonTable.Constants.IsRetail and 75 or 85}},
  BANK_ONLY_VIEW_SHOW_BAG_SLOTS = {key = "bank_view_show_bag_slots", default = false, refresh = {Refresh.Buttons}, zone = {Zone.CharacterBank}},
  GUILD_VIEW_POSITION = {key = "guild_view_position_2", default = {"TOPLEFT", 30, -235}},
  GUILD_VIEW_DIALOG_POSITION = {key = "guild_view_dialog_position", default = {"BOTTOM", "Baganator_GuildViewFrame", "TOP", 0, 0}},
  SHOW_BUTTONS_ON_ALT = {key = "show_buttons_on_alt", default = false, refresh = {Refresh.Buttons}},
  CHARACTER_SELECT_POSITION = {key = "character_select_position", default = {"RIGHT", "Baganator_BackpackViewFrame", "LEFT", 0, 0}},
  CURRENCY_PANEL_POSITION = {key = "currency_panel_position", default = {"RIGHT", "Baganator_BackpackViewFrame", "LEFT", 0, 0}},
  SETTING_ANCHORS = {key = "setting_anchors", default = false},

  DEBUG_TIMERS = {key = "debug_timers", default = false},
  DEBUG_KEYWORDS = {key = "debug_keywords", default = false},
  DEBUG_CATEGORIES = {key = "debug_categories", default = false},
  DEBUG_CATEGORIES_SEARCH = {key = "debug_categories_search", default = false},

  AUTO_OPEN = {key = "auto_open", default = {}},

  CUSTOM_CATEGORIES = {key = "custom_categories", default = {}, refresh = {Refresh.Searches}},
  CATEGORY_MODIFICATIONS = {key = "category_modifications", default = {}, refresh = {Refresh.Searches}},
  CATEGORY_SECTIONS = {key = "category_sections", default = {}, refresh = {Refresh.Layout}},
  CATEGORY_MIGRATION = {key = "category_migration", default = 0},
  CATEGORY_DEFAULT_IMPORT = {key = "category_default_import", default = 0},
  AUTOMATIC_CATEGORIES_ADDED = {key = "automatic_categories_added", default = {}},
  CATEGORY_DISPLAY_ORDER = {key = "category_display_order", default = {}, refresh = {Refresh.Searches, Refresh.Layout}},
  CATEGORY_HIDDEN = {key = "category_hidden", default = {}, refresh = {Refresh.Layout, Refresh.Cosmetic}},
  CATEGORY_SECTION_TOGGLED = {key = "category_section_toggled", default = {}, refresh = {Refresh.Cosmetic, Refresh.Layout}},
  CATEGORY_HORIZONTAL_SPACING = {key = "category_horizontal_spacing_2", default = 0.30, refresh = {Refresh.Layout}},
  CATEGORY_ITEM_GROUPING = {key = "category_item_grouping", default = true, refresh = {Refresh.ItemData}},
  CATEGORY_GROUP_EMPTY_SLOTS = {key = "category_group_empty_slots", default = true, refresh = {Refresh.Searches}},
  RECENT_TIMEOUT = {key = "recent_timeout", default = 15},
  RECENT_INCLUDE_OWNED = {key = "recent_include_owned", default = false},
  ADD_TO_CATEGORY_BUTTONS = {key = "add_to_category_buttons_2", default = "drag"},

  SAVED_SEARCHES = {key = "saved_searches", default = {}},

  SKINS = {key = "skins", default = {}},
  DISABLED_SKINS = {key = "disabled_skins", default = {}},
  CURRENT_SKIN = {key = "current_skin", default = "blizzard"},

  CATEGORY_EDIT_SEARCH_MODE = {key = "category_edit_search_mode", default = "visual"},
}

addonTable.Config.RefreshType = {}

addonTable.Config.Options = {}
addonTable.Config.Defaults = {}

for key, details in pairs(settings) do
  if details.refresh then
    local refreshType = {}
    for _, r in ipairs(details.refresh) do
      refreshType[r] = true
    end
    addonTable.Config.RefreshType[details.key] = refreshType
  end
  addonTable.Config.Options[key] = details.key
  addonTable.Config.Defaults[details.key] = details.default
end

addonTable.Config.IsCharacterSpecific = {
  [addonTable.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT] = true,
  [addonTable.Config.Options.SORT_IGNORE_BANK_SLOTS_COUNT] = true,
  [addonTable.Config.Options.CURRENCIES_TRACKED] = true,
  [addonTable.Config.Options.CURRENCIES_TRACKED_IMPORTED] = true,
}

function addonTable.Config.IsValidOption(name)
  for _, option in pairs(addonTable.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

local function RawSet(name, value)
  local tree = {strsplit(".", name)}
  if addonTable.Config.CurrentProfile == nil then
    error("BAGANATOR_CONFIG not initialized")
  elseif not addonTable.Config.IsValidOption(tree[1]) then
    error("Invalid option '" .. name .. "'")
  elseif #tree == 1 then
    local oldValue
    if addonTable.Config.IsCharacterSpecific[name] then
      local characterName = Syndicator.API.GetCurrentCharacter()
      oldValue = BAGANATOR_CONFIG.CharacterSpecific[name][characterName]
      BAGANATOR_CONFIG.CharacterSpecific[name][characterName] = value
    else
      oldValue = addonTable.Config.CurrentProfile[name]
      addonTable.Config.CurrentProfile[name] = value
    end
    if value ~= oldValue then
      return true
    end
  else
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree - 1 do
      root = root[tree[i]]
      if type(root) ~= "table" then
        error("Invalid option '" .. name .. "', broke at [" .. i .. "]")
      end
    end
    local tail = tree[#tree]
    if root[tail] == nil then
      error("Invalid option '" .. name .. "', broke at [tail]")
    end
    local oldValue = root[tail]
    root[tail] = value
    if value ~= oldValue then
      return true
    end
  end
  return false
end

function addonTable.Config.Set(name, value)
  if RawSet(name, value) then
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    if addonTable.Config.RefreshType[name] then
      addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", addonTable.Config.RefreshType[name])
    end
  end
end

-- Set multiple settings at once and after all are set fire the setting changed
-- events
function addonTable.Config.MultiSet(nameValueMap)
  local changed = {}
  for name, value in pairs(nameValueMap) do
    if RawSet(name, value) then
      table.insert(changed, name)
    end
  end

  local refreshState = {}
  for _, name in ipairs(changed) do
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
    if addonTable.Config.RefreshType[name] then
      refreshState = Mixin(refreshState, addonTable.Config.RefreshType[name])
    end
  end
  if next(refreshState) ~= nil then
    addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
  end
end

local addedInstalledNestedToList = {}
local installedNested = {}

function addonTable.Config.Install(name, defaultValue)
  if BAGANATOR_CONFIG == nil then
    error("BAGANATOR_CONFIG not initialized")
  elseif name:find("%.") == nil then
    if addonTable.Config.CurrentProfile[name] == nil then
      addonTable.Config.CurrentProfile[name] = defaultValue
    end
  else
    if not addedInstalledNestedToList[name] then
      addedInstalledNestedToList[name] = true
      table.insert(installedNested, name)
    end
    local tree = {strsplit(".", name)}
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree - 1 do
      if not root[tree[i]] then
        root[tree[i]] = {}
      end
      root = root[tree[i]]
    end
    if root[tree[#tree]] == nil then
      root[tree[#tree]] = defaultValue
    end
  end
end

function addonTable.Config.ResetOne(name)
  local newValue = addonTable.Config.Defaults[name]
  if newValue == nil then
    error("Can't reset that", name)
  else
    if type(newValue) == "table" then
      newValue = CopyTable(newValue)
    end
    addonTable.Config.Set(name, newValue)
  end
end

function addonTable.Config.Reset()
  BAGANATOR_CONFIG = {
    Profiles = {
      DEFAULT = {},
    },
    CharacterSpecific = {},
    Version = 1,
  }
  addonTable.Config.InitializeData()
end

local function ImportDefaultsToProfile()
  for option, value in pairs(addonTable.Config.Defaults) do
    if addonTable.Config.IsCharacterSpecific[option] and BAGANATOR_CONFIG.CharacterSpecific[option] == nil then
      BAGANATOR_CONFIG.CharacterSpecific[option] = {}
    elseif addonTable.Config.CurrentProfile[option] == nil then
      if type(value) == "table" then
        addonTable.Config.CurrentProfile[option] = CopyTable(value)
      else
        addonTable.Config.CurrentProfile[option] = value
      end
    end
  end
end

function addonTable.Config.InitializeData()
  if BAGANATOR_CONFIG == nil then
    addonTable.Config.Reset()
    return
  end

  if BAGANATOR_CONFIG.Profiles == nil then
    BAGANATOR_CONFIG = {
      Profiles = {
        DEFAULT = BAGANATOR_CONFIG,
      },
      CharacterSpecific = {},
      Version = 1,
    }
  end

  if BAGANATOR_CONFIG.Profiles.DEFAULT == nil then
    BAGANATOR_CONFIG.Profiles.DEFAULT = {}
  end
  if BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE] == nil then
    BAGANATOR_CURRENT_PROFILE = "DEFAULT"
  end

  addonTable.Config.CurrentProfile = BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE]
  ImportDefaultsToProfile()
end

function addonTable.Config.GetProfileNames()
  return GetKeysArray(BAGANATOR_CONFIG.Profiles)
end

function addonTable.Config.MakeProfile(newProfileName, clone)
  assert(tIndexOf(addonTable.Config.GetProfileNames(), newProfileName) == nil, "Existing Profile")
  if clone then
    BAGANATOR_CONFIG.Profiles[newProfileName] = CopyTable(addonTable.Config.CurrentProfile)
  else
    BAGANATOR_CONFIG.Profiles[newProfileName] = {}
  end
  addonTable.Config.ChangeProfile(newProfileName)
end

function addonTable.Config.DeleteProfile(profileName)
  assert(profileName ~= "DEFAULT" and profileName ~= BAGANATOR_CURRENT_PROFILE)

  BAGANATOR_CONFIG.Profiles[profileName] = nil
end

function addonTable.Config.ChangeProfile(newProfileName)
  assert(tIndexOf(addonTable.Config.GetProfileNames(), newProfileName) ~= nil, "Invalid Profile")

  local changedOptions = {}
  local refreshState = {}
  local newProfile = BAGANATOR_CONFIG.Profiles[newProfileName]

  for name, value in pairs(addonTable.Config.CurrentProfile) do
    if value ~= newProfile[name] then
      table.insert(changedOptions, name)
      Mixin(refreshState, addonTable.Config.RefreshType[name] or {})
    end
  end

  tAppendAll(changedOptions, installedNested)

  addonTable.Config.CurrentProfile = newProfile
  BAGANATOR_CURRENT_PROFILE = newProfileName

  ImportDefaultsToProfile()

  addonTable.Core.MigrateSettings()

  for _, name in ipairs(changedOptions) do
    addonTable.CallbackRegistry:TriggerEvent("SettingChanged", name)
  end
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", refreshState)
end

-- characterName is optional, only use if need a character specific setting for
-- a character other than the current one.
function addonTable.Config.Get(name, characterName)
  -- This is ONLY if a config is asked for before variables are loaded
  if addonTable.Config.CurrentProfile == nil then
    return addonTable.Config.Defaults[name]
  elseif name:find("%.") == nil then
    if addonTable.Config.IsCharacterSpecific[name] then
      local value = BAGANATOR_CONFIG.CharacterSpecific[name][characterName or Syndicator.API.GetCurrentCharacter()]
      if value == nil then
        return addonTable.Config.Defaults[name]
      else
        return value
      end
    else
      return addonTable.Config.CurrentProfile[name]
    end
  else
    local tree = {strsplit(".", name)}
    local root = addonTable.Config.CurrentProfile
    for i = 1, #tree do
      root = root[tree[i]]
      if root == nil then
        break
      end
    end
    return root
  end
end
