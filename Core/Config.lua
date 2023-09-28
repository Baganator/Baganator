Baganator.Config = {}

Baganator.Config.Options = {
  BAG_VIEW_WIDTH = "bag_view_width",
  BANK_VIEW_WIDTH = "bank_view_width",
  BAG_ICON_SIZE = "bag_icon_size",
  VIEW_ALPHA = "view_alpha",
  LOCK_FRAMES = "lock_frames",
  NO_FRAME_BORDERS = "no_frame_borders",
  EMPTY_SLOT_BACKGROUND = "empty_slot_background",
  SHOW_REAGENTS = "show_reagents",
  SHOW_SORT_BUTTON = "show_sort_button",
  SHOW_RECENTS_TABS = "show_recents_tabs_main_view",

  RECENT_CHARACTERS_MAIN_VIEW = "recent_characters_main_view",

  INVERTED_BAG_SHORTCUTS = "inverted_bag_shortcuts",
  SHOW_INVENTORY_TOOLTIPS = "show_inventory_tooltips",
  SHOW_TOOLTIPS_ON_SHIFT = "show_tooltips_on_shift",

  SHOW_ITEM_LEVEL = "show_item_level",
  SHOW_BOE_STATUS = "show_boe_status",
  SHOW_BOA_STATUS = "show_boa_status",
  ICON_TEXT_QUALITY_COLORS = "icon_text_quality_colors",
  ICON_TEXT_FONT_SIZE = "icon_text_font_size",
  SHOW_PAWN_ARROW = "show_pawn_arrow",
  SHOW_CIMI_ICON = "show_cimi_icon",
  ICON_TOP_LEFT_CORNER = "icon_top_left_corner",
  ICON_TOP_RIGHT_CORNER = "icon_top_right_corner",
  ICON_BOTTOM_LEFT_CORNER = "icon_bottom_left_corner",
  ICON_BOTTOM_RIGHT_CORNER = "icon_bottom_right_corner",

  SHOW_PAWN_ARROW = "show_pawn_arrow",
  SHOW_CIMI_ICON = "show_cimi_icon",

  MAIN_VIEW_POSITION = "main_view_position",
  BANK_ONLY_VIEW_POSITION = "bank_only_view_position",

  DEBUG = "debug",
  DEBUG_TIMERS = "debug_timers",
}

Baganator.Config.Defaults = {
  [Baganator.Config.Options.BAG_VIEW_WIDTH] = 12,
  [Baganator.Config.Options.BANK_VIEW_WIDTH] = Baganator.Constants.IsRetail and 24 or 18,
  [Baganator.Config.Options.BAG_ICON_SIZE] = 42,
  [Baganator.Config.Options.VIEW_ALPHA] = 1,
  [Baganator.Config.Options.LOCK_FRAMES] = true,
  [Baganator.Config.Options.NO_FRAME_BORDERS] = false,
  [Baganator.Config.Options.EMPTY_SLOT_BACKGROUND] = true,
  [Baganator.Config.Options.SHOW_REAGENTS] = true,
  [Baganator.Config.Options.SHOW_SORT_BUTTON] = false,
  [Baganator.Config.Options.INVERTED_BAG_SHORTCUTS] = false,
  [Baganator.Config.Options.RECENT_CHARACTERS_MAIN_VIEW] = {},
  [Baganator.Config.Options.SHOW_ITEM_LEVEL] = true,
  [Baganator.Config.Options.SHOW_BOE_STATUS] = false,
  [Baganator.Config.Options.SHOW_BOA_STATUS] = false,
  [Baganator.Config.Options.SHOW_RECENTS_TABS] = true,
  [Baganator.Config.Options.SHOW_INVENTORY_TOOLTIPS] = true,
  [Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS] = false,
  [Baganator.Config.Options.SHOW_PAWN_ARROW] = true,
  [Baganator.Config.Options.SHOW_CIMI_ICON] = false,
  [Baganator.Config.Options.MAIN_VIEW_POSITION] = {"RIGHT", -20, 0},
  [Baganator.Config.Options.BANK_ONLY_VIEW_POSITION] = {"LEFT", 20, 0},
  [Baganator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT] = false,
  [Baganator.Config.Options.ICON_TEXT_FONT_SIZE] = 14,
  [Baganator.Config.Options.ICON_TOP_LEFT_CORNER] = "item_level",
  [Baganator.Config.Options.ICON_TOP_RIGHT_CORNER] = "none",
  [Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER] = "none",
  [Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER] = "quantity",

  [Baganator.Config.Options.DEBUG] = false,
  [Baganator.Config.Options.DEBUG_TIMERS] = false,
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
  Baganator.Config.Options.SHOW_REAGENTS,
  Baganator.Config.Options.SHOW_SORT_BUTTON,
  Baganator.Config.Options.SHOW_ITEM_LEVEL,
  Baganator.Config.Options.SHOW_BOE_STATUS,
  Baganator.Config.Options.SHOW_BOA_STATUS,
  Baganator.Config.Options.SHOW_PAWN_ARROW,
  Baganator.Config.Options.SHOW_CIMI_ICON,
  Baganator.Config.Options.ICON_TEXT_QUALITY_COLORS,
  Baganator.Config.Options.ICON_TEXT_FONT_SIZE,
  Baganator.Config.Options.ICON_TOP_LEFT_CORNER,
  Baganator.Config.Options.ICON_TOP_RIGHT_CORNER,
  Baganator.Config.Options.ICON_BOTTOM_LEFT_CORNER,
  Baganator.Config.Options.ICON_BOTTOM_RIGHT_CORNER,
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
    local oldValue = BAGANATOR_CONFIG[name]
    BAGANATOR_CONFIG[name] = value
    if value ~= oldValue then
      Baganator.CallbackRegistry:TriggerEvent("SettingChangedEarly", name)
      Baganator.CallbackRegistry:TriggerEvent("SettingChanged", name)
    end
  end
end

function Baganator.Config.ResetOne(name)
  Baganator.Config.Set(name, CopyTable(Baganator.Config.Defaults[name]))
end

function Baganator.Config.Reset()
  BAGANATOR_CONFIG = {}
  for option, value in pairs(Baganator.Config.Defaults) do
    BAGANATOR_CONFIG[option] = value
  end
end

function Baganator.Config.InitializeData()
  if BAGANATOR_CONFIG == nil then
    Baganator.Config.Reset()
  else
    for option, value in pairs(Baganator.Config.Defaults) do
      if BAGANATOR_CONFIG[option] == nil then
        BAGANATOR_CONFIG[option] = value
      end
    end
  end
end

function Baganator.Config.Get(name)
  -- This is ONLY if a config is asked for before variables are loaded
  if BAGANATOR_CONFIG == nil then
    return Baganator.Config.Defaults[name]
  else
    return BAGANATOR_CONFIG[name]
  end
end
