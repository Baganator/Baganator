local function AddToTooltip(tooltip, summaries, itemLink)
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_INVENTORY_TOOLTIPS) and (not Baganator.Config.Get(Baganator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT) or IsShiftKeyDown()) then
    Baganator.Tooltips.AddLines(tooltip, summaries, itemLink)
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
end

local function SetupSummaries()
  local summaries = CreateFrame("Frame")
  Mixin(summaries, BaganatorSummariesMixin)
  summaries:OnLoad()
  Baganator.Summaries = summaries
end

function Baganator.InitializeInventoryTracking()
  InitializeSavedVariables()

  local frame = CreateFrame("Frame")
  frame:RegisterEvent("PLAYER_LOGIN")
  frame:SetScript("OnEvent", function()
    InitCurrentCharacter()
    SetupDataProcessing()
  end)
  SetupSummaries()

  Baganator.CallbackRegistry:RegisterCallback("CharacterDeleted", function(_, name)
    if name == currentCharacter then
      InitCurrentCharacter()
    end
  end)

  if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        local itemName, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
        AddToTooltip(tooltip, Baganator.Summaries, itemLink)
      end
    end)
  else
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToTooltip(tooltip, Baganator.Summaries, itemLink)
    end)
    ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToTooltip(tooltip, Baganator.Summaries, itemLink)
    end)
  end
end
