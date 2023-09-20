local Locales = {
  enUS = {},
  frFR = {},
  deDE = {},
  ruRU = {},
  ptBR = {},
  esES = {},
  esMX = {},
  zhTW = {},
  zhCN = {},
  koKR = {},
  itIT = {},
}

local L = Locales.enUS

L["BANK"] = "Bank"
L["REAGENTS"] = "Reagents"
L["XS_BANK_AND_BAGS"] = "%s's Bank and Bags"
L["XS_BAGS"] = "%s's Bags"
L["XS_BANK"] = "%s's Bank"

L["CUSTOMISE_BAGANATOR"] = "Customise Baganator"
L["RESET_POSITIONS"] = "Reset Positions"
L["LOCK_BAGS_BANKS_FRAMES"] = "Lock Bags/Bank frames"
L["CUSTOMISE_REMOVE_BORDERS"] = "Remove borders from Bags/Bank frames"
L["CUSTOMISE_EMPTY_SLOTS"] = "Hide empty slots background"
L["X_TRANSPARENCY"] = "%s%% Transparency"
L["X_BAG_COLUMNS"] = "%s Bag Columns"
L["X_BANK_COLUMNS"] = "%s Bank Columns"

L["INVENTORY_TOTALS_COLON"] = "Inventory Totals:"
L["BAGS_X_BANKS_X"] = "Bags: %s, Banks: %s"
L["BAGS_X_BANK_X"] = "Bags: %s, Bank: %s"

local L = Locales.frFR
--@localization(locale="frFR", format="lua_additive_table")@

local L = Locales.deDE
--@localization(locale="deDE", format="lua_additive_table")@

local L = Locales.ruRU
--@localization(locale="ruRU", format="lua_additive_table")@

local L = Locales.esES
--@localization(locale="esES", format="lua_additive_table")@

local L = Locales.esMX
--@localization(locale="esMX", format="lua_additive_table")@

local L = Locales.zhTW
--@localization(locale="zhTW", format="lua_additive_table")@

local L = Locales.zhCN
--@localization(locale="zhCN", format="lua_additive_table")@

local L = Locales.koKR
--@localization(locale="koKR", format="lua_additive_table")@

local L = Locales.itIT
--@localization(locale="itIT", format="lua_additive_table")@

Baganator.Locales = CopyTable(Locales.enUS)
for key, translation in pairs(Locales[GetLocale()]) do
  Baganator.Locales[key] = translation
end
for key, translation in pairs(Baganator.Locales) do
  _G["BAGANATOR_L_" .. key] = translation
end
