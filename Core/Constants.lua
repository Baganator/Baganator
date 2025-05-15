---@class addonTableBaganator
local addonTable = select(2, ...)
addonTable.Constants = {
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsMists = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC,
  IsCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC,
  IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC,
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  MaxRecents = 20,
  MaxRecentsTabs = 5,
  BattlePetCageID = 82800,

  MaxPinnedCurrencies = 100,
}

Baganator.Constants = {
  IsRetail = addonTable.Constants.IsRetail,
  IsClassic = addonTable.Constants.IsClassic,
}

addonTable.Constants.Events = {
  "SettingChangedEarly",
  "SettingChanged",

  -- Common view events
  "SearchTextChanged",
  "BagShow",
  "BagHide",
  "QuickSearch",
  "CharacterSelectToggle",
  "CharacterSelect",
  "BankToggle",
  "BankShow",
  "BankHide",
  "GuildToggle",
  "GuildShow",
  "GuildHide",
  "CurrencyPanelToggle",
  "RefreshStateChange",

  "ViewComplete",
  "BagCacheAfterNewItemsUpdate",
  "SearchMonitorComplete",

  "NewItemsAcquired",

  -- Single view only events
  "SpecialBagToggled",

  -- Category view only events
  "CategoryItemDropped",
  "CategoryAddItemStart",
  "CategoryAddItemEnd",

  "ForceClearedNewItems",

  "BackpackFrameChanged",

  "ShowCustomise",
  "ResetFramePositions",
  "EditCategory",
  "EditCategorySection",
  "EditCategoryRecent",
  "EditCategoryEmpty",
  "EditCategoryDivider",
  "ResetCategoryEditor",
  "SetSelectedCategory",

  "HighlightSimilarItems",
  "HighlightIdenticalItems",

  "HighlightBagItems",
  "ClearHighlightBag",

  "HighlightGuildTabItems",
  "ClearHighlightGuildTab",

  "PluginsUpdated",

  "TransferCancel",

  "PropagateAlt",
  "SetButtonsShown",

  "FrameGroupSwapped",

  "BankViewChanged",

  "ItemContextChanged", -- Baganator specific context highlighting
}

addonTable.Constants.SortStatus = {
  Complete = 0,
  WaitingMove = 1,
  WaitingUnlock = 2,
  WaitingItemData = 3,
}

if Syndicator then
  addonTable.Constants.KeywordGroupOrder = Syndicator.Search.Constants.KeywordGroupOrder or {
  -- Stored here temporarily, true list is in Syndicator now
    Syndicator.Locales.GROUP_ITEM_TYPE,
    Syndicator.Locales.GROUP_ITEM_DETAIL,
    Syndicator.Locales.GROUP_QUALITY,

    Syndicator.Locales.GROUP_SLOT,
    Syndicator.Locales.GROUP_WEAPON_TYPE,
    Syndicator.Locales.GROUP_ARMOR_TYPE,
    Syndicator.Locales.GROUP_STAT,
    Syndicator.Locales.GROUP_SOCKET,

    Syndicator.Locales.GROUP_TRADE_GOODS,
    Syndicator.Locales.GROUP_RECIPE,
    Syndicator.Locales.GROUP_GLYPH,
    Syndicator.Locales.GROUP_CONSUMABLE,

    Syndicator.Locales.GROUP_EXPANSION,
    Syndicator.Locales.GROUP_BATTLE_PET,
  }

  if Syndicator.Constants.WarbandBankActive then
    -- Note constant values are taken from Blizzard code
    addonTable.Constants.BlizzardBankTabConstants = {
      Character = 1,
      Warband = 3,
    }
  end

  addonTable.Constants.SampleSearchTerms = {
    "<400",
    Syndicator.Locales.KEYWORD_BOE,
    INVTYPE_SHOULDER:lower(),
    INVTYPE_TRINKET:lower(),
    Syndicator.Locales.KEYWORD_FOOD .. "|" ..  Syndicator.Locales.KEYWORD_POTION,
    Syndicator.Locales.KEYWORD_EQUIPMENT,
    Syndicator.Locales.KEYWORD_USE,
    Syndicator.Locales.KEYWORD_OPEN,
    Syndicator.Locales.KEYWORD_GEAR,
    Syndicator.Locales.KEYWORD_SOULBOUND,
    "~" .. Syndicator.Locales.KEYWORD_EQUIPMENT,
    "200-300",
    Syndicator.Locales.KEYWORD_GEAR .. "&" .. Syndicator.Locales.KEYWORD_SOULBOUND .. "&" .. Syndicator.Locales.KEYWORD_JUNK,
    ITEM_QUALITY3_DESC:lower(),
    ITEM_QUALITY2_DESC:lower(),
    Syndicator.Locales.KEYWORD_BOA,
    Syndicator.Locales.KEYWORD_AXE,
    Syndicator.Locales.KEYWORD_SWORD,
    MOUNT:lower(),
    Syndicator.Locales.KEYWORD_TRADEABLE_LOOT,
    Syndicator.Locales.KEYWORD_SET,
    "~" .. Syndicator.Locales.KEYWORD_SET .. "&" .. Syndicator.Locales.KEYWORD_GEAR,
  }
  if not addonTable.Constants.IsEra then
    local socketSearchTerms = {
      Syndicator.Locales.KEYWORD_SOCKET,
      EMPTY_SOCKET_BLUE:lower(),
    }
    tAppendAll(addonTable.Constants.SampleSearchTerms, socketSearchTerms)
  end
  if addonTable.Constants.IsRetail then
    local retailSearchTerms = {
      "dragonflight",
      Syndicator.Locales.KEYWORD_BOE .. "&" .. "dragonflight",
      Syndicator.Locales.KEYWORD_PET,
      Syndicator.Locales.KEYWORD_EQUIPMENT .. "&" .. "classic",
      Syndicator.Locales.KEYWORD_COSMETIC,
      Syndicator.Locales.KEYWORD_REAGENT,
      Syndicator.Locales.KEYWORD_MANUSCRIPT,
      TOY:lower(),
    }
    tAppendAll(addonTable.Constants.SampleSearchTerms, retailSearchTerms)
  end
end

addonTable.Constants.KeyItemFamily = 256

addonTable.Constants.ContainerKeyToInfo = {
  ["?"] = {type = "atlas", value="QuestTurnin", tooltipHeader=AMMOSLOT},
  quiver = {type = "atlas", value="Ammunition", tooltipHeader=AMMOSLOT},
  reagentBag = {type = "atlas", value="Professions_Tracking_Herb", tooltipHeader = addonTable.Locales.REAGENTS},
  keyring = {type = "file", value="interface\\addons\\baganator\\assets\\bag_keys", tooltipHeader = addonTable.Locales.KEYS},
  [0] = nil, -- regular bag
  [1] = {type = "file", value="interface\\addons\\baganator\\assets\\bag_soul_shard", tooltipHeader=addonTable.Locales.SOUL}, -- soulbag
  [2] = {type = "atlas", value="Mobile-Herbalism", tooltipHeader=addonTable.Locales.HERBALISM, size=50}, --herb
  [3] = {type = "atlas", value="Mobile-Enchanting", tooltipHeader=addonTable.Locales.ENCHANTING, size=50}, --enchant
  [4] = {type = "atlas", value="Mobile-Enginnering", tooltipHeader=addonTable.Locales.ENGINEERING, size=50}, --engineering (not not a typo for the atlas, its really misspelled)
  [5] = {type = "atlas", value="Mobile-Jewelcrafting", tooltipHeader=addonTable.Locales.GEMS, size=50}, -- gem
  [6] = {type = "atlas", value="Mobile-Mining", tooltipHeader=addonTable.Locales.MINING, size=50}, -- mining
  [7] = {type = "atlas", value="Mobile-Leatherworking", tooltipHeader=addonTable.Locales.LEATHERWORKING, size=50}, -- leatherworking
  [8] = {type = "atlas", value="Mobile-Inscription", tooltipHeader=addonTable.Locales.INSCRIPTION, size=50}, -- inscription
  [9] = {type = "atlas", value="Mobile-Fishing", tooltipHeader=addonTable.Locales.FISHING, size=50}, -- fishing
  [10] = {type = "atlas", value="Mobile-Cooking", tooltipHeader=addonTable.Locales.COOKING, size=50}, -- cooking
}
addonTable.Constants.ContainerTypes = 13

addonTable.Constants.BankTabType = {
  Character = 1,
  Warband = 2,
}

addonTable.Constants.RefreshReason = {
  ItemData = 2,
  ItemWidgets = 4,
  ItemTextures = 8,
  Searches = 16,
  Layout = 32,
  Buttons = 64,
  Sorts = 128,
  Flow = 256,
  Cosmetic = 512,
  Character = 1024,
}

Baganator.Constants.RefreshReason = {
  ItemWidgets = addonTable.Constants.RefreshReason.ItemWidgets,
  Searches = addonTable.Constants.RefreshReason.Searches,
}

addonTable.Constants.RefreshZone = {
  Bags = 2,
  CharacterBank = 4,
  WarbandBank = 8,
  GuildBank = 16,
}
