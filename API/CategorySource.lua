local _, addonTable = ...

addonTable.Utilities.OnAddonLoaded("AllTheThings", function()
  local completeDialog = "Baganator_ATT_Add_Items_Complete"
  StaticPopupDialogs[completeDialog] = {
    text = "",
    button1 = DONE,
    timeout = 0,
    hideOnEscape = 1,
  }

  Baganator.API.Categories.RegisterSourceOfIDs("allthethings", BAGANATOR_L_ALL_THE_THINGS_ADDON, BAGANATOR_L_ADD_FROM_ATT_MESSAGE, function()
    local items, pets = {}, {}

    local function GetItemsFromATTEntry(entry)
      if entry.itemID then
        table.insert(items, entry.itemID)
      end
      if entry.petID then
        table.insert(pets, entry.petID)
      end
      if entry.g then
        for _, val in pairs(entry.g) do
          GetItemsFromATTEntry(val)
        end
      end
    end


    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    function frame:GetItems()
      return items
    end

    function frame:GetPets()
      return pets
    end

    function frame:Clear()
      items, pets = {}, {}
    end

    frame:SetScript("OnShow", function()
      frame:Hide()
    end)

    frame:SetScript("OnHide", function()
      items, pets = {}, {}

      local activePaths = {}
      for key, frame in pairs(_G) do
        local path = key:match("^AllTheThings%-Window%-.*%|r(.*%>.*%d)$")
        if path and frame:IsVisible() then
          table.insert(activePaths, path)
        end
      end

      for _, path in ipairs(activePaths) do
        local hashes = {strsplit(">", path)}
        local entry = ATTC.SearchForSourcePath(ATTC:GetDataCache().g, hashes, 2, #hashes)

        local label, value = hashes[#hashes]:match("(%a+)(%-?%d+)")

        if not entry then
          local searchResults = ATTC.SearchForField(label, tonumber(value))
          for _, result in ipairs(searchResults) do
            if ATTC.GenerateSourceHash(result) == path then
              entry = result
            end
          end
        end

        if not entry then
          entry = ATTC.GetCachedSearchResults(ATTC.SearchForLink, label .. ":" .. value);
        end

        if not entry then
          local tmp = {}
          ATTC.BuildFlatSearchResponse(ATTC:GetDataCache().g, label, tonumber(value), tmp)
          if #tmp == 1 then
            entry = tmp[1]
          end
        end
        if entry then
          GetItemsFromATTEntry(entry)
        end
      end

      StaticPopupDialogs[completeDialog].text = BAGANATOR_L_ADD_FROM_ATT_POPUP_COMPLETE:format(#items + #pets, #activePaths)
      StaticPopup_Show(completeDialog)
    end)

    return frame
  end)
end)

local character = UnitName("player")
if C_AddOns.GetAddOnEnableState("LibPeriodicTable-3.1", character) == Enum.AddOnEnableState.All then
  local index = 0

  Baganator.API.Categories.RegisterSourceOfIDs("libperiodictable", "LibPeriodicTable", nil, function()
    C_AddOns.LoadAddOn("LibPeriodicTable-3.1")
    local LPT = LibStub("LibPeriodicTable-3.1")

    index = index + 1

    local items = {}

    local frame = CreateFrame("Frame", nil, UIParent)

    frame:Hide()

    function frame:Clear()
      items = {}
    end

    function frame:GetItems()
      return items
    end

    function frame:GetPets()
      return {}
    end

    local function Query(q)
      if q =="" or not LPT.sets[q] then
        return
      end
      for itemID in LPT:IterateSet(q) do
        table.insert(items, itemID)
      end
    end

    local completeDialog = "Baganator_LibPeriodicTableInsert" .. index
    StaticPopupDialogs[completeDialog] = {
      text = "Enter the LibPeriodicTable query",
      button1 = DONE,
      button2 = CANCEL,
      hasEditBox = 1,
      OnShow = function(self, data)
        self.editBox:SetText("")
      end,
      OnHide = function()
        frame:Hide()
      end,
      OnAccept = function(self)
        Query(self.editBox:GetText())
        frame:Hide()
      end,
      EditBoxOnEnterPressed = function(self)
        Query(self:GetText())
        frame:Hide()
        self:GetParent():Hide()
      end,
      EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
      editBoxWidth = 230,
      maxLetters = 0,
      timeout = 0,
      hideOnEscape = 1,
    }

    frame:SetScript("OnShow", function()
      items = {}
      StaticPopup_Show(completeDialog)
    end)

    return frame
  end)
end
