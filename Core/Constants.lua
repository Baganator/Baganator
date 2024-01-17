Baganator.Constants = {
  AllBagIndexes = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
  },
  AllBankIndexes = {
    Enum.BagIndex.Bank,
    Enum.BagIndex.BankBag_1,
    Enum.BagIndex.BankBag_2,
    Enum.BagIndex.BankBag_3,
    Enum.BagIndex.BankBag_4,
    Enum.BagIndex.BankBag_5,
    Enum.BagIndex.BankBag_6,
    Enum.BagIndex.BankBag_7,
  },
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC,
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  MaxRecents = 20,
  MaxRecentsTabs = 5,
  BattlePetCageID = 82800,

  BankBagSlotsCount = 7,

  MaxGuildBankTabItemSlots = 98,
  GuildBankFullAccessWithdrawalsLimit = 25000,

  EquippedInventorySlotOffset = 1,

  MaxPinnedCurrencies = 3,
}

if Baganator.Constants.IsWrath then
  table.insert(Baganator.Constants.AllBagIndexes, Enum.BagIndex.Keyring)
end
if Baganator.Constants.IsRetail then
  table.insert(Baganator.Constants.AllBagIndexes, Enum.BagIndex.ReagentBag)
  table.insert(Baganator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)
  Baganator.Constants.BagSlotsCount = 5
  Baganator.Constants.MaxBagSize = 42
  Baganator.Constants.ButtonFrameOffset = 6
end
if Baganator.Constants.IsClassic then
  -- Workaround for the enum containing the wrong values for the bank bag slots
  for i = 1, Baganator.Constants.BankBagSlotsCount do
    Baganator.Constants.AllBankIndexes[i + 1] = NUM_BAG_SLOTS + i
  end
  Baganator.Constants.BagSlotsCount = 4
  Baganator.Constants.MaxBagSize = 36
  Baganator.Constants.ButtonFrameOffset = 0
end

Baganator.Constants.Events = {
  "SettingChangedEarly",
  "SettingChanged",

  "CharacterDeleted",

  "BagCacheUpdate",
  "MailCacheUpdate",
  "CurrencyCacheUpdate",
  "GuildCacheUpdate",
  "EquippedCacheUpdate",

  "SearchTextChanged",
  "BagShow",
  "BagHide",
  "CharacterSelect",

  "ShowCustomise",
  "ResetFramePositions",

  "HighlightSimilarItems",

  "HighlightBagItems",
  "ClearHighlightBag",

  "ContentRefreshRequired",
  "PluginsUpdated",
}

-- Hidden currencies for all characters tooltips as they are shared between characters
Baganator.Constants.SharedCurrencies = {
  2032, -- Trader's Tender
}

Baganator.Constants.SortStatus = {
  Complete = 0,
  WaitingMove = 1,
  WaitingUnlock = 2,
  WaitingItemData = 3,
}

Baganator.Constants.SampleSearchTerms = {
  "<400",
  BAGANATOR_L_KEYWORD_BOE,
  INVTYPE_SHOULDER:lower(),
  INVTYPE_TRINKET:lower(),
  BAGANATOR_L_KEYWORD_FOOD .. "|" ..  BAGANATOR_L_KEYWORD_POTION,
  BAGANATOR_L_KEYWORD_SOCKET,
  BAGANATOR_L_KEYWORD_EQUIPMENT,
  BAGANATOR_L_KEYWORD_GEAR,
  BAGANATOR_L_KEYWORD_SOULBOUND,
  "~" .. BAGANATOR_L_KEYWORD_EQUIPMENT,
  "200-300",
  BAGANATOR_L_KEYWORD_GEAR .. "&" .. BAGANATOR_L_KEYWORD_SOULBOUND .. "&" .. BAGANATOR_L_KEYWORD_JUNK,
  EMPTY_SOCKET_BLUE:lower(),
  ITEM_QUALITY3_DESC:lower(),
  ITEM_QUALITY2_DESC:lower(),
  BAGANATOR_L_KEYWORD_BOA,
  BAGANATOR_L_KEYWORD_REPUTATION,
  BAGANATOR_L_KEYWORD_AXE,
  BAGANATOR_L_KEYWORD_SWORD,
}
if Baganator.Constants.IsRetail then
  local retailSearchTerms = {
    "dragonflight",
    BAGANATOR_L_KEYWORD_BOE .. "&" .. "dragonflight",
    BAGANATOR_L_KEYWORD_PET,
    BAGANATOR_L_KEYWORD_EQUIPMENT .. "&" .. "classic",
    BAGANATOR_L_KEYWORD_COSMETIC,
    BAGANATOR_L_KEYWORD_REAGENT,
  }
  tAppendAll(Baganator.Constants.SampleSearchTerms, retailSearchTerms)
end
if Baganator.Constants.IsRetail or not IsMacClient() then
  local setTerms = {
    BAGANATOR_L_KEYWORD_SET,
    "~" .. BAGANATOR_L_KEYWORD_SET .. "&" .. BAGANATOR_L_KEYWORD_GEAR,
  }
  tAppendAll(Baganator.Constants.SampleSearchTerms, setTerms)
end
Baganator.Constants.KeyItemFamily = 256
Baganator.Constants.AccountBoundTooltipLines = {
  ITEM_BIND_TO_BNETACCOUNT,
  ITEM_BNETACCOUNTBOUND,
  ITEM_BIND_TO_ACCOUNT,
  ITEM_ACCOUNTBOUND,
}
