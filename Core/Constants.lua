-- Retail bag indexes. Will need changing for classic.
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
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  MaxRecents = 4,
  BattlePetCageID = 82800,
}

-- Not currently included as the keyring bag presents as quite large in the bag
-- view
--[[if Baganator.Constants.IsClassic then
  table.insert(Baganator.Constants.AllBagIndexes, Enum.BagIndex.Keyring)
end]]
if Baganator.Constants.IsRetail then
  table.insert(Baganator.Constants.AllBagIndexes, Enum.BagIndex.ReagentBag)
  table.insert(Baganator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)
end

Baganator.Constants.Events = {
  "SettingChangedEarly",
  "SettingChanged",

  "CharacterDeleted",

  "BagCacheUpdate",
  "MailCacheUpdate",

  "SearchTextChanged",
  "BagShow",
  "BagHide",
  "CharacterSelect",

  "ShowCustomise",
  "ResetFramePositions",

  "ReagentOnEnter",
  "ReagentOnLeave",
}
