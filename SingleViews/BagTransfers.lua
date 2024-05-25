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

local TransferToBank
if Syndicator and Syndicator.Constants.WarbandBankActive then
  TransferToBank = function(matches, characterName, callback)
    local emptyBankSlots
    if BankFrame:GetActiveBankType() == Enum.BankType.Character then
      emptyBankSlots = Baganator.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(characterName).bank, Syndicator.Constants.AllBankIndexes)
    elseif BankFrame:GetActiveBankType() == Enum.BankType.Account then
      matches = tFilter(matches, function(m) return C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, ItemLocation:CreateFromBagAndSlot(m.bagID, m.slotID)) end, true)
      local bagID = AccountBankPanel:GetSelectedTabID()
      local tabIndex = tIndexOf(Syndicator.Constants.AllWarbandIndexes, bagID)
      local bagsData = {Syndicator.API.GetWarband(1).bank[tabIndex].slots}
      emptyBankSlots = Baganator.Transfers.GetEmptyBagsSlots(bagsData, {bagID})
    else
      error("unrecognised bank type")
    end

    local status = Baganator.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBankIndexes, emptyBankSlots)
    callback(status)
  end
else
  TransferToBank = function(matches, characterName, callback)
    local emptyBankSlots = Baganator.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(characterName).bank, Syndicator.Constants.AllBankIndexes)
    local status = Baganator.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBankIndexes, emptyBankSlots)
    callback(status)
  end
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
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_MAIL_TOOLTIP_TEXT
)

local function AddToScrapper(matches, characterName, callback)
  local waiting = #matches
  local loopOver = false

  for _, item in ipairs(matches) do
    local location = ItemLocation:CreateFromBagAndSlot(item.bagID, item.slotID)
    if C_Item.DoesItemExist(location) then
      Item:CreateFromItemLocation(location):ContinueOnItemLoad(function()
        waiting = waiting - 1
        if C_Item.CanScrapItem(location) then
          C_Container.UseContainerItem(item.bagID, item.slotID)
        end
        if loopFinished and waiting == 0 then
          callback(Baganator.Constants.SortStatus.Complete)
        end
      end)
    else
      waiting = waiting - 1
    end
  end
  loopFinished = true
  if waiting == 0 then
    callback(Baganator.Constants.SortStatus.Complete)
  end
end

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.ScrappingMachine) end,
  AddToScrapper,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_SCRAPPER_TOOLTIP_TEXT
)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.Merchant) end,
  function(matches, characterName, callback)
    local status = Baganator.Transfers.VendorItems(matches)
    callback(status)
  end,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_MERCHANT_TOOLTIP_TEXT
)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.TradePartner) end,
  function(matches, characterName, callback)
    local status = Baganator.Transfers.AddToTrade(matches)
    callback(status)
  end,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_TRADE_TOOLTIP_TEXT
)

RegisterBagTransfer(
  -- At a guild bank and allowed to deposit items
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker) and (select(4, GetGuildBankTabInfo(GetCurrentGuildBankTab()))) end,
  function(matches, characterName, callback)
    local guildTab = GetCurrentGuildBankTab()
    local emptyGuildSlots = Baganator.Transfers.GetEmptyGuildSlots(Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank[guildTab], guildTab)
    local status, modes = Baganator.Transfers.FromBagsToGuild(matches, emptyGuildSlots)
    callback(status, modes)
  end,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_GUILD_TOOLTIP_TEXT
)

if Syndicator then
  Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", function()
    addonTable.BagTransferActivationCallback()
  end)
end
