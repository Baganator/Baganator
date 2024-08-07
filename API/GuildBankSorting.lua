local _, addonTable = ...
addonTable.Utilities.OnAddonLoaded("SushiSort", function()
  Baganator.API.RegisterGuildBankSort("Sushi Sort", "sushisort", function()
    SUSHISORT_SlashCommand()
  end)
end)

addonTable.Utilities.OnAddonLoaded("BankStack", function()
  if BankStack.CommandDecorator then
    local sortBank = BankStack.CommandDecorator(BankStack.SortBags, "bank")
    Baganator.API.RegisterGuildBankSort("BankStack", "bankstack", function()
      sortBank()
    end)
  end
end)
