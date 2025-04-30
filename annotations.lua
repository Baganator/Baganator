---@meta

C_Engraving = {}

-- API
  --  EquipmentSets
  ItemRackUser = {}
  ItemRack = {}
  ---@return table
  Outfitter_GetCategoryOrder = function() end
  ---@return table
  Outfitter_GetOutfitsByCategoryID = function(c) end
  ---@return boolean
  Outfitter_IsInitialized = function() end
  Outfitter_RegisterOutfitEvent = function(event, func) end
  ---@return table
  Outfitter_GetItemInfoFromLink = function(itemLink) end
  ---@return table
  Outfitter_FindOutfitByName = function(name) end

  --  Junk
  PeddlerAPI = {}
  SellJunk = {}
  Scrap = {}
  Vendor = {}
  DejunkApi = {}

  -- ItemButton
  CanIMogIt = {}
  ---@return boolean
  CIMI_CheckOverlayIconEnabled = function(tbl) end
  CIMI_SetIcon = function(tbl, func, text) end
  CIMI_AddToFrame = function(itemButton, func) end

  BPBID_Internal = {}

  -- Pawn
  ---@return boolean?
  PawnShouldItemLinkHaveUpgradeArrowUnbudgeted = function(itemLink) end

  -- Sorting
  SetSortBagsRightToLeft = function(isForward) end
  SortBags = function() end
  SortBankBags = function() end
  BankStack = {}

  -- Upgrades
  SimpleItemLevel = {}

--Categories
ATTC = {}
TSM_API = {}

-- Core
WagoAnalytics = {}
---@return boolean
IsAddOnLoaded = function(name) end

--ItemViewCommon
CloseBankFrame = function() end
CUSTOM_CLASS_COLORS = {}
---@return boolean
IsUsingLegacyAuctionClient = function() end
FramePool_HideAndClearAnchors = function(frame) end

SetItemButtonCount = function(itemButton, count) end
SetItemButtonTexture = function(itemButton, tex) end
---@param itemRef string|number?
SetItemButtonQuality = function(itemButton, quality, itemRef) end
SetItemButtonDesaturated = function(itemButton, isDesaturated) end
ClearItemButtonOverlay = function(itemButton) end
---@param itemLocation ItemLocationMixin?
HandleModifiedItemClick = function(itemLink, itemLocation) end

GetBackpackCurrencyInfo = function(index) end
---@return number
GetCurrencyListSize = function() end
ManageBackpackTokenFrame = {}
---@param index number
---@return string, boolean, boolean, boolean, number, string, number, number, number, nil, number
GetCurrencyListInfo = function(index) end
---@param index number
---@param state 0|1
ExpandCurrencyList = function(index, state) end
---@param index number
---@param state 0|1
SetCurrencyBackpack = function(index, state) end

---@param currencyID number
---@return string
GetCurrencyLink = function(currencyID) end

---@param slot "Bag1"
GetInventorySlotInfo = function(slot) end

---@param tabIndex number
---@param slotIndex number
---@return string
GetGuildBankItemLink = function(tabIndex, slotIndex) end
---@param tabIndex number
---@param slotIndex number
---@return number?, number?, boolean?, boolean?, number?
GetGuildBankItemInfo = function(tabIndex, slotIndex) end
LE_ITEM_QUALITY_UNCOMMON = 2
ContainerFrameItemButton_OnLeave = function(frame) end
---@param state boolean
ContainerFrameItemButton_SetForceExtended = function(frame, state) end
---@param count number
OpenStackSplitFrame = function(count, frame, corner1, corner2) end

---@param bagID number
---@param slotID number
---@return ContainerItemInfo?
C_Container.GetContainerItemInfo = function(bagID, slotID) end

--ViewManagement
BlizzMoveAPI = {}
KeyRingButton = {}
LE_FRAME_TUTORIAL_HUD_REVAMP_BAG_CHANGES = 0
LE_FRAME_TUTORIAL_BAG_SLOTS_AUTHENTICATOR = 0
LE_FRAME_TUTORIAL_MOUNT_EQUIPMENT_SLOT_FRAME = 0
LE_FRAME_TUTORIAL_UPGRADEABLE_ITEM_IN_SLOT = 0
LE_FRAME_TUTORIAL_EQUIP_REAGENT_BAG = 0
LE_FRAME_TUTORIAL_REAGENT_BANK_UNLOCK = 0
BackpackTokenFrame = {}

--SingleViews
NORMAL_FONT_COLOR_CODE = {}
---@return number
GetCurrentGuildBankTab = function() end
---@param tab number
---@param index number
GetGuildBankTransaction = function(tab, index) end

-- Skins
ElvUI = {}
NDui = {}
GW2_ADDON = {}
UNIT_NAME_FONT = {}

-- Sorting
ItemVersion = {}
