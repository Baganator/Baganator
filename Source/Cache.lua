BaganatorCacheMixin = {}

local bankBags = {}
local bagBags = {}
for index, key in ipairs(Baganator.Constants.AllBagIndexes) do
  bagBags[key] = index
end
for index, key in ipairs(Baganator.Constants.AllBankIndexes) do
  bankBags[key] = index
end

function BaganatorCacheMixin:OnLoad()
  FrameUtil.RegisterFrameForEvents(self, {
    -- Normalized realm name ready
    "PLAYER_LOGIN",

    -- Regular bag items updating
    "BAG_UPDATE",
    -- Bag replaced
    "BAG_CONTAINER_UPDATE",

    -- Bank open/close (used to determine whether to cache or not)
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    -- Reagent bank
    "PLAYERBANKSLOTS_CHANGED",

    -- Gold tracking
    "PLAYER_MONEY",

  })
  if not Baganator.Constants.IsClassic then
    -- Bank items reagent bank updating
    self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
  end

  self:SetupCache()
  self:SetupPending()

  Baganator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, name)
    if name == self.currentCharacter then
      self:InitCurrentPlayer()
    end
  end)
end

function BaganatorCacheMixin:SetupCache()
  if BAGANATOR_DATA == nil then
    BAGANATOR_DATA = {
      Version = 1,
      Characters = {},
      Guilds = {},
    }
  end
end

function BaganatorCacheMixin:QueueCaching()
  if InCombatLockdown() then
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
  else
    self:SetScript("OnUpdate", self.OnUpdate)
  end
end

function BaganatorCacheMixin:InitCurrentPlayer()
  local characterName, realm = UnitFullName("player")
  self.currentCharacter = characterName .. "-" .. realm

  if BAGANATOR_DATA.Characters[self.currentCharacter] == nil then
    BAGANATOR_DATA.Characters[self.currentCharacter] = {
      bags = {},
      bank = {},
      money = 0,
      details = {
        realmNormalized = realm,
        realm = GetRealmName(),
        character = characterName,
      }
    }
  end

  BAGANATOR_DATA.Characters[self.currentCharacter].money = GetMoney()
  BAGANATOR_DATA.Characters[self.currentCharacter].details.class = select(3, UnitClass("player"))

  for bagID in pairs(bagBags) do
    self.pending.bags[bagID] = true
  end
  self:QueueCaching()
end

function BaganatorCacheMixin:OnEvent(eventName, ...)
  if eventName == "PLAYER_LOGIN" then
    self:InitCurrentPlayer()

  elseif eventName == "BAG_UPDATE" then
    local bagID = ...
    if bagBags[bagID] then
      self.pending.bags[bagID] = true
    elseif bankBags[bagID] and self.bankOpen then
      self.pending.bank[bagID] = true
    end
    self:QueueCaching()

  elseif eventName == "PLAYERBANKSLOTS_CHANGED" then
    self.pending.bank[Enum.BagIndex.Bank] = true
    self:QueueCaching()

  elseif eventName == "PLAYERREAGENTBANKSLOTS_CHANGED" then
    self.pending.bank[Enum.BagIndex.Reagentbank] = true
    self:QueueCaching()

  elseif eventName == "BANKFRAME_OPENED" then
    self.bankOpen = true
    for bagID in pairs(bankBags) do
      self.pending.bank[bagID] = true
    end
    self:QueueCaching()
  elseif eventName == "BANKFRAME_CLOSED" then
    self.bankOpen = false
  elseif eventName == "PLAYER_MONEY" then
    BAGANATOR_DATA.Characters[self.currentCharacter].money = GetMoney()
  elseif eventName == "PLAYER_REGEN_ENABLED" then
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:QueueCaching()
  end
end

function BaganatorCacheMixin:SetupPending()
  self.pending = {
    any = false,
    bags = {},
    bank = {},
  }
end

function BaganatorCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)
  if self.currentCharacter == nil then
    return
  end

  local start = debugprofilestop()

  local pendingCopy = CopyTable(self.pending)

  local function FireBagChange()
    Baganator.CallbackRegistry:TriggerEvent("CacheUpdate", self.currentCharacter, pendingCopy)
  end

  local waiting = 0
  local loopsFinished = false

  local function GetInfo(slotInfo)
    return {
      itemID = slotInfo.itemID,
      itemCount = slotInfo.stackCount,
      iconTexture = slotInfo.iconFileID,
      itemLink = slotInfo.hyperlink,
      quality = slotInfo.quality,
    }
  end


  local function DoBag(bagID, bag)
    for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
      local location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
      local itemID = C_Item.DoesItemExist(location) and C_Item.GetItemID(location)
      bag[slotID] = {}
      if itemID then
        if C_Item.IsItemDataCachedByID(itemID) then
          local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)
          bag[slotID] = GetInfo(slotInfo)
        else
          waiting = waiting + 1
          local item = Item:CreateFromItemID(itemID)
          item:ContinueOnItemLoad(function()
            local slotInfo = C_Container.GetContainerItemInfo(bagID, slotID)
            if slotInfo and slotInfo.itemID == itemID then
              bag[slotID] = GetInfo(slotInfo)
            end
            waiting = waiting - 1
            if loopsFinished and waiting == 0 then
              FireBagChange()
            end
          end)
        end
      end
    end
  end

  local bags = BAGANATOR_DATA.Characters[self.currentCharacter].bags

  for bagID in pairs(self.pending.bags) do
    local bagIndex = bagBags[bagID]
    bags[bagIndex] = {}
    DoBag(bagID, bags[bagIndex])
  end

  local bank = BAGANATOR_DATA.Characters[self.currentCharacter].bank

  for bagID in pairs(self.pending.bank) do
    local bagIndex = bankBags[bagID]
    bank[bagIndex] = {}
    DoBag(bagID, bank[bagIndex])
  end

  loopsFinished = true

  self:SetupPending()

  if waiting == 0 then
    FireBagChange()
  end
end
