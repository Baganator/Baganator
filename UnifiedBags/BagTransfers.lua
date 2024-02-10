local addonName, addonTable = ...

addonTable.BagTransfers = {}
addonTable.BagTransferActivationCallback = function() end

local function RegisterBagTransfer(condition, action, confirmOnAll, tooltipText)
  table.insert(addonTable.BagTransfers, { condition = condition, action = action, confirmOnAll = confirmOnAll, tooltipText = tooltipText})
end

local playerInteractionManagerChecking = CreateFrame("Frame")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
playerInteractionManagerChecking:SetScript("OnEvent", function()
  addonTable.BagTransferActivationCallback()
end)

local isBankOpen = false
do
  local BankCheck = CreateFrame("Frame")
  FrameUtil.RegisterFrameForEvents(BankCheck, {
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
  })
  BankCheck:SetScript("OnEvent", function(_, event)
    isBankOpen = event == "BANKFRAME_OPENED"
    addonTable.BagTransferActivationCallback()
  end)
end

local function TransferToBank(matches, characterName, callback)
  local emptyBankSlots = Baganator.Transfers.GetEmptySlots(BAGANATOR_DATA.Characters[characterName].bank, Baganator.Constants.AllBankIndexes)
  local combinedIDs = CopyTable(Baganator.Constants.AllBagIndexes)
  tAppendAll(combinedIDs, Baganator.Constants.AllBankIndexes)

  local status = Baganator.Transfers.MoveBetweenBags(combinedIDs, matches, emptyBankSlots)
  callback(status)
end

RegisterBagTransfer(
  function(button) return isBankOpen end,
  TransferToBank,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT
)

local function TransferToMail(matches, characterName, callback)
  local status = Baganator.Transfers.AddToMail(matches)
  callback(status)
end

local sendMailShowing = false
hooksecurefunc("SetSendMailShowing", function(state)
  sendMailShowing = state
  addonTable.BagTransferActivationCallback()
end)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.MailInfo) and sendMailShowing end,
  TransferToMail,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_MAIL_TOOLTIP_TEXT
)

local function AddToScrapper(matches, characterName, callback)
  for _, item in ipairs(matches) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) and C_Item.CanScrapItem(location) then
      C_Container.UseContainerItem(item.bagID, item.slotID)
    end
  end
  callback(Baganator.Constants.SortStatus.Complete)
end

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine) end,
  AddToScrapper,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_SCRAPPER_TOOLTIP_TEXT
)

local function VendorItems(matches, characterName, callback)
  local sold = 0
  for _, item in ipairs(matches) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) and not item.hasNoValue then
      C_Container.UseContainerItem(item.bagID, item.slotID)
      sold = sold + 1
      -- Limit sold to the most that can be bought back from the merchant if
      -- clicked by mistaked
      if sold >= 12 then
        return
      end
    end
  end
  if sold == 0 then
    UIErrorsFrame:AddMessage(BAGANATOR_L_THE_MERCHANT_DOESNT_WANT_ANY_OF_THOSE_ITEMS, 1.0, 0.1, 0.1, 1.0)
  end
  callback(Baganator.Constants.SortStatus.Complete)
end

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.Merchant) end,
  VendorItems,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_MERCHANT_TOOLTIP_TEXT
)
