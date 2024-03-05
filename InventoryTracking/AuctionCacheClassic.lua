if not Baganator.Constants.IsClassic then
  return
end

BaganatorAuctionCacheMixin = {}

local AUCTIONS_UPDATED_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
  "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
}

function BaganatorAuctionCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
  self.currentCharacter = Baganator.Utilities.GetCharacterFullName()
end

function BaganatorAuctionCacheMixin:AddAuction(auctionInfo, itemLink)
  table.insert(
    BAGANATOR_DATA.Characters[self.currentCharacter].auctions,
    {
        itemID = auctionInfo[17],
        itemCount = auctionInfo[3],
        iconTexture = auctionInfo[2],
        itemLink = itemLink,
        quality = auctionInfo[4],
        isBound = false,
    }
  )
  Baganator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
end

function BaganatorAuctionCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.Auctioneer then
      GetOwnerAuctionItems()
    end
  elseif eventName == "AUCTION_OWNED_LIST_UPDATE" then
    BAGANATOR_DATA.Characters[self.currentCharacter].auctions = {}

    for index = 1, GetNumAuctionItems("owner") do
      local auctionInfo = { GetAuctionItemInfo("owner", index) }
      local itemID = auctionInfo[17]
      if C_Item.IsItemDataCachedByID(itemID) then
        self:AddAuction(auctionInfo, GetAuctionItemLink("owner", index))
      else
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function()
          auctionInfo = { GetAuctionItemInfo("owner", index) }
          self:AddAuction(auctionInfo, GetAuctionItemLink("owner", index))
        end)
      end
    end
  end
end
