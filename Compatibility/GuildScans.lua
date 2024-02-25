if QueryGuildBankTab then
  hooksecurefunc("QueryGuildBankTab", function(tabIndex)
    if IsAddOnLoaded("BagSync") then
      SetCurrentGuildBankTab(tabIndex)
    end
  end)
end
