Baganator.Constants = {
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  MaxRecents = 20,
  MaxRecentsTabs = 5,
  BattlePetCageID = 82800,

  MaxPinnedCurrencies = 3,
}

if Baganator.Constants.IsRetail then
  Baganator.Constants.ButtonFrameOffset = 6
end
if Baganator.Constants.IsClassic then
  Baganator.Constants.ButtonFrameOffset = 0
end

Baganator.Constants.Events = {
  "SettingChangedEarly",
  "SettingChanged",

  "SearchTextChanged",
  "BagShow",
  "BagHide",
  "CharacterSelectToggle",
  "CharacterSelect",
  "SpecialBagToggled",
  "BankToggle",
  "BankShow",
  "BankHide",
  "GuildToggle",
  "GuildShow",
  "GuildHide",
  "GuildSetTab",

  "ShowCustomise",
  "ResetFramePositions",

  "HighlightSimilarItems",
  "HighlightIdenticalItems",

  "HighlightBagItems",
  "ClearHighlightBag",

  "ContentRefreshRequired",
  "PluginsUpdated",

  "TransferCancel",
}

Baganator.Constants.SortStatus = {
  Complete = 0,
  WaitingMove = 1,
  WaitingUnlock = 2,
  WaitingItemData = 3,
}

if not Syndicator then
  return
end

Baganator.Constants.SampleSearchTerms = {
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
if not Baganator.Constants.IsEra then
  local socketSearchTerms = {
    SYNDICATOR_L_KEYWORD_SOCKET,
    EMPTY_SOCKET_BLUE:lower(),
  }
  tAppendAll(Baganator.Constants.SampleSearchTerms, socketSearchTerms)
end
if Baganator.Constants.IsRetail then
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
  tAppendAll(Baganator.Constants.SampleSearchTerms, retailSearchTerms)
end
Baganator.Constants.KeyItemFamily = 256
