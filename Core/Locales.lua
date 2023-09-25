Baganator.Locales = CopyTable(BAGANATOR_LOCALES.enUS)
for key, translation in pairs(BAGANATOR_LOCALES[GetLocale()]) do
  Baganator.Locales[key] = translation
end
for key, translation in pairs(Baganator.Locales) do
  _G["BAGANATOR_L_" .. key] = translation
end
