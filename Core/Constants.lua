local _, addonTable = ...
addonTable.Constants = {
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
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

if addonTable.Constants.IsRetail then
  addonTable.Constants.ButtonFrameOffset = 6
end
if addonTable.Constants.IsClassic then
  addonTable.Constants.ButtonFrameOffset = 0
end

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

  "ViewComplete",
  "BagCacheAfterNewItemsUpdate",

  -- Single view only events
  "SpecialBagToggled",

  -- Category view only events
  "CategoryItemDropped",
  "ResetCategoryOrder",
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

  "HighlightSimilarItems",
  "HighlightIdenticalItems",

  "HighlightBagItems",
  "ClearHighlightBag",

  "ContentRefreshRequired",
  "PluginsUpdated",

  "TransferCancel",
}

addonTable.Constants.SortStatus = {
  Complete = 0,
  WaitingMove = 1,
  WaitingUnlock = 2,
  WaitingItemData = 3,
}

if not Syndicator then
  return
end

addonTable.Constants.KeywordGroupOrder = {
  SYNDICATOR_L_GROUP_ITEM_TYPE,
  SYNDICATOR_L_GROUP_ITEM_DETAIL,
  SYNDICATOR_L_GROUP_QUALITY,

  SYNDICATOR_L_GROUP_SLOT,
  SYNDICATOR_L_GROUP_WEAPON_TYPE,
  SYNDICATOR_L_GROUP_ARMOR_TYPE,
  SYNDICATOR_L_GROUP_STAT,
  SYNDICATOR_L_GROUP_SOCKET,

  SYNDICATOR_L_GROUP_TRADE_GOODS,
  SYNDICATOR_L_GROUP_RECIPE,
  SYNDICATOR_L_GROUP_GLYPH,
  SYNDICATOR_L_GROUP_CONSUMABLE,

  SYNDICATOR_L_GROUP_EXPANSION,
  SYNDICATOR_L_GROUP_BATTLE_PET,
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
  SYNDICATOR_L_KEYWORD_BOE,
  INVTYPE_SHOULDER:lower(),
  INVTYPE_TRINKET:lower(),
  SYNDICATOR_L_KEYWORD_FOOD .. "|" ..  SYNDICATOR_L_KEYWORD_POTION,
  SYNDICATOR_L_KEYWORD_EQUIPMENT,
  SYNDICATOR_L_KEYWORD_USE,
  SYNDICATOR_L_KEYWORD_OPEN,
  SYNDICATOR_L_KEYWORD_GEAR,
  SYNDICATOR_L_KEYWORD_SOULBOUND,
  "~" .. SYNDICATOR_L_KEYWORD_EQUIPMENT,
  "200-300",
  SYNDICATOR_L_KEYWORD_GEAR .. "&" .. SYNDICATOR_L_KEYWORD_SOULBOUND .. "&" .. SYNDICATOR_L_KEYWORD_JUNK,
  ITEM_QUALITY3_DESC:lower(),
  ITEM_QUALITY2_DESC:lower(),
  SYNDICATOR_L_KEYWORD_BOA,
  SYNDICATOR_L_KEYWORD_REPUTATION,
  SYNDICATOR_L_KEYWORD_AXE,
  SYNDICATOR_L_KEYWORD_SWORD,
  MOUNT:lower(),
  SYNDICATOR_L_KEYWORD_TRADEABLE_LOOT,
  SYNDICATOR_L_KEYWORD_SET,
  "~" .. SYNDICATOR_L_KEYWORD_SET .. "&" .. SYNDICATOR_L_KEYWORD_GEAR,
}
if not addonTable.Constants.IsEra then
  local socketSearchTerms = {
    SYNDICATOR_L_KEYWORD_SOCKET,
    EMPTY_SOCKET_BLUE:lower(),
  }
  tAppendAll(addonTable.Constants.SampleSearchTerms, socketSearchTerms)
end
if addonTable.Constants.IsRetail then
  local retailSearchTerms = {
    "dragonflight",
    SYNDICATOR_L_KEYWORD_BOE .. "&" .. "dragonflight",
    SYNDICATOR_L_KEYWORD_PET,
    SYNDICATOR_L_KEYWORD_EQUIPMENT .. "&" .. "classic",
    SYNDICATOR_L_KEYWORD_COSMETIC,
    SYNDICATOR_L_KEYWORD_REAGENT,
    SYNDICATOR_L_KEYWORD_MANUSCRIPT,
    TOY:lower(),
  }
  tAppendAll(addonTable.Constants.SampleSearchTerms, retailSearchTerms)
end

addonTable.Constants.KeyItemFamily = 256

addonTable.Constants.ContainerKeyToInfo = {
  quiver = {type = "atlas", value="Ammunition", tooltipHeader=AMMOSLOT},
  reagentBag = {type = "atlas", value="Professions_Tracking_Herb", tooltipHeader = BAGANATOR_L_REAGENTS},
  keyring = {type = "file", value="interface\\addons\\baganator\\assets\\bag_keys", tooltipHeader = BAGANATOR_L_KEYS},
  [0] = nil, -- regular bag
  [1] = {type = "file", value="interface\\addons\\baganator\\assets\\bag_soul_shard", tooltipHeader=BAGANATOR_L_SOUL}, -- soulbag
  [2] = {type = "atlas", value="worldquest-icon-herbalism", tooltipHeader=BAGANATOR_L_HERBALISM, size=50}, --herb
  [3] = {type = "atlas", value="worldquest-icon-enchanting", tooltipHeader=BAGANATOR_L_ENCHANTING, size=50}, --enchant
  [4] = {type = "atlas", value="worldquest-icon-engineering", tooltipHeader=BAGANATOR_L_ENGINEERING, size=50}, --engineering
  [5] = {type = "atlas", value="worldquest-icon-jewelcrafting", tooltipHeader=BAGANATOR_L_GEMS, size=50}, -- gem
  [6] = {type = "atlas", value="worldquest-icon-mining", tooltipHeader=BAGANATOR_L_MINING, size=50}, -- mining
  [7] = {type = "atlas", value="worldquest-icon-leatherworking", tooltipHeader=BAGANATOR_L_LEATHERWORKING, size=50}, -- leatherworking
  [8] = {type = "atlas", value="worldquest-icon-inscription", tooltipHeader=BAGANATOR_L_INSCRIPTION, size=50}, -- inscription
  [9] = {type = "atlas", value="worldquest-icon-fishing", tooltipHeader=BAGANATOR_L_FISHING, size=50}, -- fishing
  [10] = {type = "atlas", value="worldquest-icon-cooking", tooltipHeader=BAGANATOR_L_COOKING, size=60}, -- cooking
}
addonTable.Constants.ContainerTypes = 13
