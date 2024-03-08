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
  "AUCTION_HOUSE_PURCHASE_COMPLETED",
  "COMMODITY_PURCHASE_SUCCEEDED",
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

  -- Used to detect item details for a purchase event
  self.purchased = nil
  self.purchasedItemID = nil
  self.purchasedAuctionInfo = nil

  hooksecurefunc(C_AuctionHouse, "PlaceBid", function(auctionID, amount)
    local auctionInfo = C_AuctionHouse.GetAuctionInfoByID(auctionID)
    auctionInfo.auctionID = auctionID
    self.purchased {
      auctionInfo = auctionInfo,
      itemCount = 1,
    }
    -- Ensure we have a perfect item link
    if not C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
      local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
      item:ContinueOnItemLoad(function()
        local auctionInfo = C_AuctionHouse.GetAuctionInfoByID(auctionID)
        if not auctionInfo then
          if self.posted.auctionInfo.itemLink then
            self.posted.auctionInfo.itemLink = select(2, GetItemInfo(self.posted.auctionInfo.itemLink))
          end
        else
          auctionInfo.auctionID = auctionID
          self.purchased.auctionInfo = auctionInfo
        end
      end)
    end
  end)
  hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(itemID, itemCount)
    self.purchased = {
      itemID = itemID,
      itemCount = itemCount,
    }
  end)
end

local function ConvertAuctionInfoToItem(auctionInfo, itemCount)
  local itemInfo = {GetItemInfo(auctionInfo.itemLink or auctionInfo.itemKey.itemID)}
  local itemLink = auctionInfo.itemLink or itemInfo[2]
  local iconTexture = itemInfo[10]
  local quality = itemInfo[3] 

  if auctionInfo.itemKey.itemID == Baganator.Constants.BattlePetCageID then
    local speciesIDText, qualityText = itemLink:match("battlepet:(%d+):%d+:(%d+)")
    iconTexture = select(2, C_PetJournal.GetPetInfoBySpeciesID(tonumber(speciesIDText)))
    quality = tonumber(qualityText)
  end

  return {
    itemID = auctionInfo.itemKey.itemID,
    itemCount = itemCount,
    iconTexture = iconTexture,
    itemLink = itemLink,
    quality = quality,
    isBound = false,
  }
end

function BaganatorAuctionCacheMixin:AddToMail(item)
  table.insert(BAGANATOR_DATA.Characters[self.currentCharacter].mail, item)
  Baganator.CallbackRegistry:TriggerEvent("MailCacheUpdate", self.currentCharacter)
end

function BaganatorAuctionCacheMixin:AddAuction(auctionInfo, itemCount)
  local item = ConvertAuctionInfoToItem(auctionInfo, itemCount)
  item.auctionID = auctionInfo.auctionID
  table.insert(
    BAGANATOR_DATA.Characters[self.currentCharacter].auctions,
    item
  )
  Baganator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
end

function BaganatorAuctionCacheMixin:RemoveAuctionByID(auctionID, addToMail)
  for index, item in ipairs(BAGANATOR_DATA.Characters[self.currentCharacter].auctions) do
    if item.auctionID == auctionID then
      table.remove(BAGANATOR_DATA.Characters[self.currentCharacter].auctions, index)
      Baganator.CallbackRegistry:TriggerEvent("AuctionsCacheUpdate", self.currentCharacter)
      item.auctionID = nil
      if addToMail then
        self:AddToMail(item)
      end
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
    self:RemoveAuctionByID(auctionID, true)

  elseif eventName == "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION" then
    local notification, text, auctionID = ...
    if notification == Enum.AuctionHouseNotification.AuctionSold or notification == Enum.AuctionHouseNotification.AuctionExpired then
      self:RemoveAuctionByID(auctionID, notification ~= Enum.AuctionHouseNotification.AuctionSold)
    end

  elseif eventName == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
    local auctionID = ...

    if not self.purchased or not self.purchased.auctionInfo or self.purchased.auctionInfo.auctionID ~= auctionInfo.auctionID then
      return
    end

    local itemCount = self.purchased.itemCount

    if C_Item.IsItemDataCachedByID(auctionInfo.itemKey.itemID) then
      local item = ConvertAuctionInfoToItem(auctionInfo, itemCount)
      self:AddToMail(item)
    else
      local item = Item:CreateFromItemID(auctionInfo.itemKey.itemID)
      item:ContinueOnItemLoad(function()
        local item = ConvertAuctionInfoToItem(auctionInfo, itemCount)
        self:AddToMail(item)
      end)
    end

    self.purchased = nil
  elseif eventName == "COMMODITY_PURCHASE_SUCCEEDED" then
    if not self.purchased and not self.purchased.itemID then
      return
    end

    local itemID = self.purchased.itemID
    local itemCount = self.purchased.itemCount

    local function GetItem()
      local itemInfo = {GetItemInfo(self.purchased.itemID)}
      return {
        itemID = itemID,
        itemCount = itemCount,
        iconTexture = itemInfo[10],
        itemLink = itemInfo[2],
        quality = itemInfo[3],
        isBound = false,
      }
    end

    if C_Item.IsItemDataCachedByID(itemID) then
      local item = GetItem()
      self:AddToMail(item)
    else
      local item = Item:CreateFromItemID(itemID)
      item:ContinueOnItemLoad(function()
        local item = GetItem()
        self:AddToMail(item)
      end)
    end

    self.purchased = nil
  end
end
