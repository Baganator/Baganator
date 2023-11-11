local function AddToItemTooltip(tooltip, summaries, itemLink)
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_INVENTORY_TOOLTIPS) and (not Baganator.Config.Get(Baganator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT) or IsShiftKeyDown()) then
    Baganator.Tooltips.AddItemLines(tooltip, summaries, itemLink)
  end
end

local function AddToCurrencyTooltip(tooltip, summaries, itemLink)
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_CURRENCY_TOOLTIPS) and (not Baganator.Config.Get(Baganator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT) or IsShiftKeyDown()) then
    Baganator.Tooltips.AddCurrencyLines(tooltip, summaries, itemLink)
  end
end

local function InitializeSavedVariables()
  if BAGANATOR_DATA == nil then
    BAGANATOR_DATA = {
      Version = 1,
      Characters = {},
      Guilds = {},
    }
  end
end

local currentCharacter
local function InitCurrentCharacter()
  local characterName, realm = UnitFullName("player")
  currentCharacter = characterName .. "-" .. realm

  if BAGANATOR_DATA.Characters[currentCharacter] == nil then
    BAGANATOR_DATA.Characters[currentCharacter] = {
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

  local characterData = BAGANATOR_DATA.Characters[currentCharacter]
  characterData.details.className, characterData.details.class = select(2, UnitClass("player"))
  characterData.details.faction = UnitFactionGroup("player")
  characterData.mail = characterData.mail or {}
  characterData.currencies = characterData.currencies or {}
end

local function SetupDataProcessing()
  local bagCache = CreateFrame("Frame")
  Mixin(bagCache, BaganatorBagCacheMixin)
  bagCache:OnLoad()
  bagCache:SetScript("OnEvent", bagCache.OnEvent)

  Baganator.BagCache = bagCache

  local mailCache = CreateFrame("Frame")
  Mixin(mailCache, BaganatorMailCacheMixin)
  mailCache:OnLoad()
  mailCache:SetScript("OnEvent", mailCache.OnEvent)

  Baganator.MailCache = mailCache

  local currencyCache = CreateFrame("Frame")
  Mixin(currencyCache, BaganatorCurrencyCacheMixin)
  currencyCache:OnLoad()
  currencyCache:SetScript("OnEvent", currencyCache.OnEvent)

  Baganator.CurrencyCache = currencyCache
end

local function SetupItemSummaries()
  local summaries = CreateFrame("Frame")
  Mixin(summaries, BaganatorItemSummariesMixin)
  summaries:OnLoad()
  Baganator.ItemSummaries = summaries
end

function Baganator.InventoryTracking.Initialize()
  InitializeSavedVariables()

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    InitCurrentCharacter()
    SetupDataProcessing()
  end)
  SetupItemSummaries()

  Baganator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, name)
    if name == currentCharacter then
      InitCurrentCharacter()
    end
  end)

  if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        local itemName, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
        AddToItemTooltip(tooltip, Baganator.ItemSummaries, itemLink)
      end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        local data = tooltip:GetPrimaryTooltipData()
        AddToCurrencyTooltip(tooltip, data.id)
      end
    end)
  else
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToItemTooltip(tooltip, Baganator.ItemSummaries, itemLink)
    end)
    ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToItemTooltip(tooltip, Baganator.ItemSummaries, itemLink)
    end)
    local function CurrencyTooltipHandler(tooltip, index)
      local link = C_CurrencyInfo.GetCurrencyListLink(index)
      if link ~= nil then
        local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
        if currencyID ~= nil then
          AddToCurrencyTooltip(tooltip, currencyID)
        end
      end
    end
    hooksecurefunc(GameTooltip, "SetCurrencyToken", CurrencyTooltipHandler)
    hooksecurefunc(ItemRefTooltip, "SetCurrencyToken", CurrencyTooltipHandler)
  end
end
