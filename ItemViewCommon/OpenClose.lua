local _, addonTable = ...
local IT = Enum.PlayerInteractionType

local event_drivers = {
  BANKFRAME_OPENED = { option = "bank", isOpen = true, default = true },
  BANKFRAME_CLOSED = { option = "bank", isOpen = false, default = true },
  TRADE_SKILL_SHOW = { option = "tradeskill", isOpen = true, default = false },
  TRADE_SKILL_CLOSE = { option = "tradeskill", isOpen = false, default = false },
  SOCKET_INFO_UPDATE = { option = "sockets", isOpen = true, default = false },
  SOCKET_INFO_CLOSE = { option = "sockets", isOpen = false, default = false },
}
local interactions = {
  [IT.GuildBanker] = { option = "guild_bank", default = false },
  [IT.VoidStorageBanker] = {option = "void_storage", default = false },
  [IT.Auctioneer] = {option = "auction_house", default = addonTable.Constants.IsRetail },
  [IT.MailInfo] = {option = "mail", default = false },
  [IT.Merchant] = {option = "merchant", default = true },
  [IT.TradePartner] = {option = "trade_partner", default = false },
  [IT.ScrappingMachine] = {option = "scrapping_machine", default = true },
  [IT.Soulbind] = {option = "forge_of_bonds", default = false },
}

local frames = {
  ["CharacterFrame"] = { option = "character_panel", default = false },
}

local function CheckOption(option)
  return addonTable.Config.Get(addonTable.Config.Options.AUTO_OPEN)[option]
end

BaganatorOpenCloseMixin = {}

function BaganatorOpenCloseMixin:OnLoad()
  local data = addonTable.Config.Get(addonTable.Config.Options.AUTO_OPEN)

  for _, details in pairs(event_drivers) do
    if data[details.option] == nil then
      data[details.option] = details.default
    end
  end

  local wagoNotDefault = false
  for _, details in pairs(interactions) do
    if data[details.option] == nil then
      data[details.option] = details.default
    elseif addonTable.WagoAnalytics and data[details.option] ~= details.default then
      wagoNotDefault = true
    end
  end

  if addonTable.WagoAnalytics then
    addonTable.WagoAnalytics:Switch("AutoOpenChanged", wagoNotDefault)
  end

  self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
  self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

  for event in pairs(event_drivers) do
    if type(event) == "string" then
      self:RegisterEvent(event)
    end
  end

  hooksecurefunc("ToggleCharacter", function(view)
    local details = frames["CharacterFrame"]
    if not CheckOption(details.option) then
      return
    end
    if CharacterFrame:IsShown() then
      addonTable.CallbackRegistry:TriggerEvent("BagShow")
    else
      addonTable.CallbackRegistry:TriggerEvent("BagHide")
    end
  end)
end

function BaganatorOpenCloseMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or eventName == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
    local interactionType = ...
    local details = interactions[interactionType]
    if not details then
      return
    end
    if not CheckOption(details.option) then
      return
    end
    if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
      addonTable.CallbackRegistry:TriggerEvent("BagShow")
    else
      addonTable.CallbackRegistry:TriggerEvent("BagHide")
    end
  else
    local details = event_drivers[eventName]
    if not CheckOption(details.option) then
      return
    end
    if details.isOpen then
      addonTable.CallbackRegistry:TriggerEvent("BagShow")
    else
      addonTable.CallbackRegistry:TriggerEvent("BagHide")
    end
  end
end


function addonTable.InitializeOpenClose()
  local frame = CreateFrame("Frame")
  Mixin(frame, BaganatorOpenCloseMixin)
  frame:SetScript("OnEvent", frame.OnEvent)
  frame:OnLoad()
end
