local function AddToTooltip(tooltip, summaries, itemLink)
  if Baganator.Config.Get(Baganator.Config.Options.SHOW_INVENTORY_TOOLTIPS) and (not Baganator.Config.Get(Baganator.Config.Options.SHOW_TOOLTIPS_ON_SHIFT) or IsShiftKeyDown()) then
    Baganator.Tooltips.AddLines(tooltip, summaries, itemLink)
  end
end

local cache, summaries

local function SetupDataProcessing()
  cache = CreateFrame("Frame")
  Mixin(cache, BaganatorCacheMixin)
  cache:OnLoad()
  cache:SetScript("OnEvent", cache.OnEvent)
  cache:SetScript("OnUpdate", cache.OnUpdate)

  Baganator.Cache = cache
  Baganator.Summaries = cache

  summaries = CreateFrame("Frame")
  Mixin(summaries, BaganatorSummariesMixin)
  summaries:OnLoad()
end

function Baganator.InitializeInventoryTracking()
  SetupDataProcessing()

  if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        local itemName, itemLink = TooltipUtil.GetDisplayedItem(tooltip)
        AddToTooltip(tooltip, summaries, itemLink)
      end
    end)
  else
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToTooltip(tooltip, summaries, itemLink)
    end)
    ItemRefTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      local _, itemLink = tooltip:GetItem()
      AddToTooltip(tooltip, summaries, itemLink)
    end)
  end
end
