local _, addonTable = ...

addonTable.BagTransfers = {}
local activationCallbacks = {}
function addonTable.AddBagTransferActivationCallback(callback)
  table.insert(activationCallbacks, callback)
end
local function CallActivationCallbacks()
  for _, callback in ipairs(activationCallbacks) do
    callback()
  end
end

local function RegisterBagTransfer(condition, action, confirmOnAll, tooltipText)
  table.insert(addonTable.BagTransfers, { condition = condition, action = action, confirmOnAll = confirmOnAll, tooltipText = tooltipText})
end

local playerInteractionManagerChecking = CreateFrame("Frame")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
playerInteractionManagerChecking:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
playerInteractionManagerChecking:SetScript("OnEvent", function()
  CallActivationCallbacks()
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
    CallActivationCallbacks()
  end)
end

local TransferToBank
if Syndicator and Syndicator.Constants.WarbandBankActive then
  TransferToBank = function(matches, characterName, callback)
    local emptyBankSlots
    if BankFrame:GetActiveBankType() == Enum.BankType.Character then
      emptyBankSlots = addonTable.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(characterName).bank, Syndicator.Constants.AllBankIndexes)
    elseif BankFrame:GetActiveBankType() == Enum.BankType.Account then
      matches = tFilter(matches, function(m)
        local location = ItemLocation:CreateFromBagAndSlot(m.bagID, m.slotID)
        return C_Item.DoesItemExist(location) and C_Bank.IsItemAllowedInBankType(Enum.BankType.Account, location)
      end, true)
      local bagData, indexes
      local tabIndex = addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB)
      if tabIndex > 0 then
        bagsData = {Syndicator.API.GetWarband(1).bank[tabIndex].slots}
        indexes = {Syndicator.Constants.AllWarbandIndexes[tabIndex]}
      else
        bagsData = {}
        for _, tab in ipairs(Syndicator.API.GetWarband(1).bank) do
          table.insert(bagsData, tab.slots)
        end
        indexes = Syndicator.Constants.AllWarbandIndexes
      end
      emptyBankSlots = addonTable.Transfers.GetEmptyBagsSlots(bagsData, indexes)
    else
      error("unrecognised bank type")
    end

    local status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBankIndexes, emptyBankSlots)
    callback(status)
  end
else
  TransferToBank = function(matches, characterName, callback)
    local emptyBankSlots = addonTable.Transfers.GetEmptyBagsSlots(Syndicator.API.GetCharacter(characterName).bank, Syndicator.Constants.AllBankIndexes)
    local status = addonTable.Transfers.FromBagsToBags(matches, Syndicator.Constants.AllBankIndexes, emptyBankSlots)
    callback(status)
  end
end

RegisterBagTransfer(
  function(button) return isBankOpen end,
  TransferToBank,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT
)

local function TransferToMail(matches, characterName, callback)
  local status = addonTable.Transfers.AddToMail(matches)
  callback(status)
end

local sendMailShowing = false
hooksecurefunc("SetSendMailShowing", function(state)
  sendMailShowing = state
  CallActivationCallbacks()
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
          callback(addonTable.Constants.SortStatus.Complete)
        end
      end)
    else
      waiting = waiting - 1
    end
  end
  loopFinished = true
  if waiting == 0 then
    callback(addonTable.Constants.SortStatus.Complete)
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
    local status = addonTable.Transfers.VendorItems(matches)
    callback(status)
  end,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_MERCHANT_TOOLTIP_TEXT_2
)

RegisterBagTransfer(
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.TradePartner) end,
  function(matches, characterName, callback)
    local status = addonTable.Transfers.AddToTrade(matches)
    callback(status)
  end,
  false, BAGANATOR_L_TRANSFER_MAIN_VIEW_TRADE_TOOLTIP_TEXT
)

RegisterBagTransfer(
  -- At a guild bank and allowed to deposit items
  function() return C_PlayerInteractionManager.IsInteractingWithNpcOfType(Enum.PlayerInteractionType.GuildBanker) and (select(4, GetGuildBankTabInfo(GetCurrentGuildBankTab()))) end,
  function(matches, characterName, callback)
    local guildTab = GetCurrentGuildBankTab()
    local emptyGuildSlots = addonTable.Transfers.GetEmptyGuildSlots(Syndicator.API.GetGuild(Syndicator.API.GetCurrentGuild()).bank[guildTab], guildTab)
    local status, modes = addonTable.Transfers.FromBagsToGuild(matches, emptyGuildSlots)
    callback(status, modes)
  end,
  true, BAGANATOR_L_TRANSFER_MAIN_VIEW_GUILD_TOOLTIP_TEXT
)

if Syndicator then
  Syndicator.CallbackRegistry:RegisterCallback("GuildCacheUpdate", function()
    CallActivationCallbacks()
  end)
end
