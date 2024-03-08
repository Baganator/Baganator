if not Baganator.Constants.IsRetail then
  return
end

BaganatorAuctionCacheMixin = {}

local AUCTIONS_UPDATED_EVENTS = {
  "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
  "OWNED_AUCTIONS_UPDATED",
  "AUCTION_HOUSE_AUCTION_CREATED",
  "AUCTION_HOUSE_AUCTIONS_EXPIRED",
  "AUCTION_CANCELED",
  "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION",
}

function BaganatorAuctionCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, AUCTIONS_UPDATED_EVENTS)
  self.currentCharacter = Baganator.Utilities.GetCharacterFullName()

  -- Used to detect how many of an item correspond to a particular
  -- auction created event.
  self.posted = nil
  hooksecurefunc(C_AuctionHouse, "PostItem", function(itemLocation)
    local itemLink = C_Item.GetItemLink(itemLocation)
    self.posted = {
      itemCount = 1,
      itemLink = C_Item.GetItemLink(itemLocation),
      itemID = C_Item.GetItemID(itemLocation),
    }
    if not C_Item.IsItemDataCached(itemLocation) then
      local item = Item:CreateFromItemLocation(itemLocation)
      item:ContinueOnItemLoad(function()
        if C_Item.DoesItemExist(itemLocation) then
          self.posted.itemLink = C_Item.GetItemLink(itemLocation)
        else
          self.posted.itemLink = select(2, GetItemInfo(self.posted.itemLink))
        end
      end)
    end
  end)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemLocation, _, itemCount)
    self.posted = {
      itemID = C_Item.GetItemID(itemLocation),
      itemCount = itemCount,
    }
  end)
end

function BaganatorAuctionCacheMixin:AddAuction(auctionInfo, itemCount)
  local itemInfo = {GetItemInfo(auctionInfo.itemLink or auctionInfo.itemKey.itemID)}
  local itemLink = auctionInfo.itemLink or itemInfo[2]
  local iconTexture = itemInfo[10]
  local quality = itemInfo[3] 
  if auctionInfo.itemKey.itemID == Baganator.Constants.BattlePetCageID then
    local speciesIDText, qualityText = itemLink:match("battlepet:(%d+):%d+:(%d+)")
    iconTexture = select(2, C_PetJournal.GetPetInfoBySpeciesID(tonumber(speciesIDText)))
    quality = tonumber(qualityText)
  end
  table.insert(
    BAGANATOR_DATA.Characters[self.currentCharacter].auctions,
    {
      itemID = auctionInfo.itemKey.itemID,
      itemCount = itemCount,
      iconTexture = iconTexture,
      itemLink = itemLink,
      quality = quality,
      isBound = false,
      auctionID = auctionInfo.auctionID,
    }
  )
  Baganator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
end

function BaganatorAuctionCacheMixin:RemoveAuctionByID(auctionID)
  for index, item in ipairs(BAGANATOR_DATA.Characters[self.currentCharacter].auctions) do
    if item.auctionID == auctionID then
      table.remove(BAGANATOR_DATA.Characters[self.currentCharacter].auctions, index)
      Baganator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
      table.insert(BAGANATOR_DATA.Characters[self.currentCharacter].mail, item)
      Baganator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.currentCharacter)
      break
    end
  end
end

function BaganatorAuctionCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
    local interactType = ...
    if interactType == Enum.PlayerInteractionType.Auctioneer then
      -- Register for the throttle event to only request the owned auctions
      -- after the default auction house queries have succeeded - the favourites
      -- list view.
      self:RegisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
    end
  elseif eventName == "AUCTION_HOUSE_THROTTLED_SYSTEM_READY" then
    C_AuctionHouse.QueryOwnedAuctions({})
    self:UnregisterEvent("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")

  elseif eventName == "OWNED_AUCTIONS_UPDATED" then
    -- All owned auctions, replace any existing auctions in the cache as this is
    -- the complete list
    BAGANATOR_DATA.Characters[self.currentCharacter].auctions = {}
    for index = 1, C_AuctionHouse.GetNumOwnedAuctions() do
      local auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(index)
      if auctionInfo.status == Enum.AuctionStatus.Active then
        if C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
          self:AddAuction(auctionInfo, auctionInfo.quantity)
        else
          local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
          item:ContinueOnItemLoad(function()
            local auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(index)
            if not auctionInfo then
              return
            end
            self:AddAuction(auctionInfo, auctionInfo.quantity)
          end)
        end
      end
    end

  elseif eventName == "AUCTION_HOUSE_AUCTION_CREATED" then
    if self.posted == nil then
      return
    end
    -- Auction created
    local auctionID = ...
    local itemCount = self.posted.itemCount
    local itemLink = self.posted.itemLink
    local itemID = self.posted.itemID

    local function DoItem()
      local itemInfo = {GetItemInfo(itemLink or itemID)}
      local item = {
        itemID = itemID,
        itemCount = itemCount,
        iconTexture = itemInfo[10],
        itemLink = itemLink or itemInfo[2],
        quality = itemInfo[3],
        isBound = false,
      }
      item.auctionID = auctionID
      table.insert(
        BAGANATOR_DATA.Characters[self.currentCharacter].auctions,
        item
      )
      Baganator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
    end

    if C_Item.IsItemDataCachedByID(itemID) then
      DoItem()
    else
      local item = Item:CreateFromItemID(itemID)
      item:ContinueOnItemLoad(function()
        DoItem()
      end)
    end

    self.posted = nil

  elseif eventName == "AUCTION_HOUSE_AUCTIONS_EXPIRED" or eventName == "AUCTION_CANCELED" then
    -- Expired and cancelled have the same behaviour, remove from the auctions
    -- list and add to the mail cache
    local auctionID = ...
    self:RemoveAuctionByID(auctionID)

  elseif eventName == "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION" then
    local notification, text, auctionID = ...
    if notification == Enum.AuctionHouseNotification.AuctionSold or notification == Enum.AuctionHouseNotification.AuctionExpired then
      self:RemoveAuctionByID(auctionID)
    end
  end
end
