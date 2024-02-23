if QueryGuildBankTab then
  hooksecurefunc("QueryGuildBankTab", function(tabIndex)
    SetCurrentGuildBankTab(tabIndex)
  end)
end
