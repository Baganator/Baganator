if not Baganator.Constants.IsClassic then
  return
end

BaganatorAuctionCacheMixin = {}

local AUCTIONS_UPDATED_EVENTS = {
  "AUCTION_OWNED_LIST_UPDATE",
}

function BaganatorAuctionCacheMixin:OnLoad()
    FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
    self.currentCharacter = Baganator.Utilities.GetCharacterFullName()
  end

function BaganatorAuctionCacheMixin:OnEvent(eventName, ...)
  if eventName == "AUCTION_OWNED_LIST_UPDATE" then
    -- TODO
  end
end
