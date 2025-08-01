---@class addonTableBaganator
local addonTable = select(2, ...)
if not Syndicator then
  return
end

local CONTAINER_TYPE_TO_MESSAGE = {
  equipped = addonTable.Locales.THAT_ITEM_IS_EQUIPPED,
  auctions = addonTable.Locales.THAT_ITEM_IS_LISTED_ON_THE_AUCTION_HOUSE,
  mail = addonTable.Locales.THAT_ITEM_IS_IN_A_MAILBOX,
  void = addonTable.Locales.THAT_ITEM_IS_IN_VOID_STORAGE,
}

Syndicator.API.RegisterShowItemLocation(function(mode, entity, container, itemLink, searchText)
  local self = {}

  addonTable.CallbackRegistry:RegisterCallback("ViewComplete", function()
    addonTable.CallbackRegistry:UnregisterCallback("ViewComplete", self)
    addonTable.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  end, self)

  if mode == "character" then
    if container == "bag" then
      addonTable.CallbackRegistry:TriggerEvent("GuildHide")
      addonTable.CallbackRegistry:TriggerEvent("BankHide")
      addonTable.CallbackRegistry:TriggerEvent("BagShow", entity)
      addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    elseif container == "bank" then
      addonTable.CallbackRegistry:TriggerEvent("GuildHide")
      addonTable.CallbackRegistry:TriggerEvent("BagHide")
      addonTable.CallbackRegistry:TriggerEvent("BankShow", entity)
      addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    else
      addonTable.Dialogs.ShowAcknowledge(CONTAINER_TYPE_TO_MESSAGE[container])
      addonTable.CallbackRegistry:UnregisterCallback("ViewComplete", self)
      return
    end
  elseif mode == "guild" then
    addonTable.CallbackRegistry:TriggerEvent("BagHide")
    addonTable.CallbackRegistry:TriggerEvent("BankHide")
    addonTable.CallbackRegistry:TriggerEvent("GuildShow", entity, tonumber(container))
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
    addonTable.CallbackRegistry:TriggerEvent("HighlightIdenticalItems", itemLink)
  elseif mode == "warband" then
    addonTable.CallbackRegistry:TriggerEvent("GuildHide")
    addonTable.CallbackRegistry:TriggerEvent("BagHide")
    if addonTable.Config.Get(addonTable.Config.Options.WARBAND_CURRENT_TAB) == 0 then
      addonTable.CallbackRegistry:TriggerEvent("BankShow", tonumber(entity), 0)
    else
      addonTable.CallbackRegistry:TriggerEvent("BankShow", tonumber(entity), tonumber(container))
    end
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", searchText)
  else
    addonTable.CallbackRegistry:UnregisterCallback("ViewComplete", self)
    return
  end
end)

BaganatorSearchWidgetMixin = {}

function BaganatorSearchWidgetMixin:OnLoad()
  self:SetShown(addonTable.Config.Get(addonTable.Config.Options.SHOW_SEARCH_BOX))
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged",  function(_, settingName)
    if settingName == addonTable.Config.Options.SHOW_SEARCH_BOX then
      self:SetShown(addonTable.Config.Get(addonTable.Config.Options.SHOW_SEARCH_BOX))
    end
  end)

  self.SearchBox.Instructions:SetWordWrap(false)
  self.SearchBox:HookScript("OnTextChanged", function(_, isUserInput)
    if isUserInput and not self.SearchBox:IsInIMECompositionMode() then
      local text = self.SearchBox:GetText()
      addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", text:lower())
    end
    if self.SearchBox:GetText() == "" then
      self.SearchBox.Instructions:SetText(addonTable.Utilities.GetRandomSearchesText())
    end
  end)
  self.SearchBox:HookScript("OnKeyDown", function(_, key)
    if key == "LALT" or key == "RALT" or key == "ALT" then
      addonTable.CallbackRegistry:TriggerEvent("PropagateAlt")
    end
  end)
  self.SearchBox:HookScript("OnKeyUp", function(_, key)
    if key == "LALT" or key == "RALT" or key == "ALT" then
      addonTable.CallbackRegistry:TriggerEvent("PropagateAlt")
    end
  end)
  self.SearchBox.clearButton:SetScript("OnClick", function()
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end)

  self.GlobalSearchButton:Disable()
  self.GlobalSearchButton.Icon:SetDesaturated(true)

  addonTable.CallbackRegistry:RegisterCallback("SearchTextChanged",  function(_, text)
    self.SearchBox:SetText(text)
    self.GlobalSearchButton:SetEnabled(text ~= "")
    self.GlobalSearchButton.Icon:SetDesaturated(not self.GlobalSearchButton:IsEnabled())
  end)

  self.HelpButton:SetScript("OnClick", function()
    addonTable.Help.ShowSearchDialog()
  end)

  addonTable.Skins.AddFrame("SearchBox", self.SearchBox)

  addonTable.CallbackRegistry:RegisterCallback("SetButtonsShown", function(_, shown)
    self.showButtons = shown
    if self:IsVisible() and self.sideSpacing then
      self:SetSpacing(self.sideSpacing)
    end
  end, self)
  self.showButtons = true
end

function BaganatorSearchWidgetMixin:OnShow()
  self.SearchBox.Instructions:SetText(addonTable.Utilities.GetRandomSearchesText())
end

function BaganatorSearchWidgetMixin:OnHide()
  if self.SearchBox:GetText() ~= "" then
    addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", "")
  end
  Syndicator.Search.ClearCache()
end

function BaganatorSearchWidgetMixin:SetSpacing(sideSpacing)
  self.sideSpacing = sideSpacing

  if self.showButtons then
    self.SearchBox:ClearAllPoints()
    self.SearchBox:SetPoint("RIGHT", self:GetParent(), -sideSpacing - 106, 0)
    self.SearchBox:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset + 5, - 28)
    self.SavedSearchesButton:ClearAllPoints()
    self.SavedSearchesButton:SetPoint("LEFT", self.SearchBox, "RIGHT", 3, 0)
    self.GlobalSearchButton:ClearAllPoints()
    self.GlobalSearchButton:SetPoint("LEFT", self.SavedSearchesButton, "RIGHT", 3, 0)
    self.HelpButton:ClearAllPoints()
    self.HelpButton:SetPoint("LEFT", self.GlobalSearchButton, "RIGHT", 3, 0)

    self.SavedSearchesButton:Show()
    self.GlobalSearchButton:Show()
    self.HelpButton:Show()
  else
    self.SearchBox:ClearAllPoints()
    self.SearchBox:SetPoint("RIGHT", self:GetParent(), -sideSpacing, 0)
    self.SearchBox:SetPoint("TOPLEFT", self:GetParent(), "TOPLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset + 5, - 28)

    self.SavedSearchesButton:Hide()
    self.GlobalSearchButton:Hide()
    self.HelpButton:Hide()
  end
end

local function SaveSearch(label, search)
  local list = addonTable.Config.Get(addonTable.Config.Options.SAVED_SEARCHES)
  local oldIndex = FindInTableIf(list, function(a) return a.label == label end)
  if oldIndex then
    list[oldIndex].search = search
  else
    table.insert(list, {label = label, search = search})
    table.sort(list, function(a, b)
      if a.label == b.label then
        return a.search < b.search
      else
        return a.label < b.label
      end
    end)
  end
end

function BaganatorSearchWidgetMixin:OpenSavedSearches()
  MenuUtil.CreateContextMenu(self.SavedSearchesButton, function(menu, rootDescription)
    local list = addonTable.Config.Get(addonTable.Config.Options.SAVED_SEARCHES)
    for _, details in ipairs(list) do
      local button = rootDescription:CreateButton(details.label, function()
        addonTable.CallbackRegistry:TriggerEvent("SearchTextChanged", details.search)
      end)
      button:AddInitializer(function(button, description, menu)
        local delete = MenuTemplates.AttachAutoHideButton(button, "transmog-icon-remove")
        delete:SetPoint("RIGHT")
        delete:SetSize(16, 16)
        delete.Texture:SetAtlas("transmog-icon-remove")
        delete:SetScript("OnClick", function()
          local list = addonTable.Config.Get(addonTable.Config.Options.SAVED_SEARCHES)
          local oldIndex = FindInTableIf(list, function(a) return a.label == details.label end)
          if oldIndex then
            table.remove(list, oldIndex)
          end
          menu:Close()
        end)
        MenuUtil.HookTooltipScripts(delete, function(tooltip)
          GameTooltip_SetTitle(tooltip, DELETE);
        end);
      end)
    end
    if #list > 0 then
      rootDescription:CreateDivider()
    end
    if self.SearchBox:GetText() == "" then
      local text = rootDescription:CreateTitle(GRAY_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.SAVE_SEARCH))
      text:SetTooltip(function(tooltip)
        tooltip:AddLine(addonTable.Locales.NOTHING_TO_SAVE)
      end)
    else
      local button = rootDescription:CreateButton(NORMAL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.SAVE_SEARCH), function()
        addonTable.Dialogs.ShowEditBox(addonTable.Locales.CHOOSE_A_LABEL_FOR_THIS_SEARCH, ACCEPT, CANCEL, function(name)
          SaveSearch(name, self.SearchBox:GetText())
        end)
      end)
    end
  end)
end
