local _, addonTable = ...

local possibleVisuals = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder", "TitleBg", "Bg",
  "TopTileStreaks",
}
local function RemoveFrameTextures(frame)
  for _, key in ipairs(possibleVisuals) do
    if frame[key] then
      frame[key]:Hide()
      frame[key]:SetTexture()
      frame[key] = nil -- Necessary as classic NineSlice pieces have names which clash
    end
  end
end

local function GenerateButton(parent)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(20, 20)
  button:SetHighlightAtlas("bags-glow-blue")
  button.tex = button:CreateTexture(nil, "BACKGROUND")
  button.tex:SetAllPoints()
  button.border = button:CreateTexture(nil, "BORDER")
  button.border:SetTexture("Interface/SpellBook/guildspellbooktabiconframe")
  button.border:SetAllPoints()

  button:SetScript("OnEnter", function()
    if button.tooltipText then
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(button.tooltipText)
      GameTooltip:Show()
    end
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return button
end

local allButtonFrames = {}

local hidden = CreateFrame("Frame")
hidden:Hide()
local skinners = {
  ItemButton = function(frame, tags)
  end,
  IconButton = function(button)
  end,
  Button = function(button)
  end,
  ButtonFrame = function(frame, tags)
    table.insert(allButtonFrames, frame)
    RemoveFrameTextures(frame)
    NineSliceUtil.ApplyLayoutByName(frame.NineSlice or frame, "TooltipDefaultDarkLayout")
    frame.NineSlice:SetFrameLevel(frame:GetFrameLevel() - 1)
    frame.NineSlice.Center:SetAlpha(1 - addonTable.Config.Get("skins.legacystyle.view_transparency"))

    if tags.backpack then
      hooksecurefunc(frame, "OnFinished", function(self)
        local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()
        self.ScrollBox:ClearAllPoints()
        self.ScrollBox:SetPoint("TOPLEFT", sideSpacing + addonTable.Constants.ButtonFrameOffset - 2 - 2, -28 - topSpacing / 4 + 2)
        self:SetHeight(self:GetHeight() - 28)
      end)

      for _, b in ipairs(frame.AllFixedButtons) do
        b:SetParent(hidden)
      end
      frame.AllFixedButtons = {}
      for _, b in ipairs(frame.TopButtons) do
        b:SetParent(hidden)
      end
      frame.TopButtons = {}

      do
        local button = GenerateButton(frame)
        button:SetPoint("TOPLEFT", 4, -4)
        button:SetScript("OnShow", function()
          SetPortraitTexture(button.tex, "player", true)
        end)
        table.insert(frame.TopButtons, button)
        button:SetScript("OnClick", function()
          MenuUtil.CreateContextMenu(button, function(menu, rootDescription)
            if frame.TransferButton:IsShown() then
              rootDescription:CreateButton(BAGANATOR_L_TRANSFER, function()
                frame.TransferButton:SetParent(frame)
                frame.TransferButton:Click()
                frame.TransferButton:SetParent(hidden)
              end)
            end
            rootDescription:CreateButton(BAGANATOR_L_BANK, function()
              frame.ToggleBankButton:SetParent(frame)
              frame.ToggleBankButton:Click()
              frame.ToggleBankButton:SetParent(hidden)
            end)
            rootDescription:CreateButton(BAGANATOR_L_GUILD_BANK, function()
              frame.ToggleGuildBankButton:SetParent(frame)
              frame.ToggleGuildBankButton:Click()
              frame.ToggleGuildBankButton:SetParent(hidden)
            end)
            rootDescription:CreateButton(BAGANATOR_L_ALL_CHARACTERS, function()
              frame.ToggleAllCharacters:Click()
            end)
          end)
        end)
      end
      do
        local button = GenerateButton(frame)
        button.tooltipText = BAGANATOR_L_BAG_SLOTS
        button:SetPoint("TOPLEFT", frame.TopButtons[#frame.TopButtons], "TOPRIGHT", 3, 0)
        button.tex:SetAtlas("hud-backpack")
        button:SetScript("OnClick", function()
          frame.ToggleBagSlotsButton:SetParent(frame)
          frame.ToggleBagSlotsButton:Click()
          frame.ToggleBagSlotsButton:SetParent(hidden)
        end)
        table.insert(frame.TopButtons, button)
      end
      do
        local button = GenerateButton(frame)
        button.tooltipText = BAGANATOR_L_SORT
        button:SetPoint("TOPLEFT", frame.TopButtons[#frame.TopButtons], "TOPRIGHT", 3, 0)
        button.tex:SetAtlas("bags-button-autosort-up")
        button:SetScript("OnClick", function(_, leftOrRightButton)
          frame.SortButton:SetParent(frame)
          frame.SortButton:Click(leftOrRightButton)
          frame.SortButton:SetParent(hidden)
        end)
        button.tex:ClearAllPoints()
        button.tex:SetPoint("CENTER")
        button.tex:SetSize(27, 27)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        table.insert(frame.TopButtons, button)
      end
      do
        local button = GenerateButton(frame)
        button.tooltipText = SEARCH
        button:SetPoint("TOPLEFT", frame.TopButtons[#frame.TopButtons], "TOPRIGHT", 3, 0)
        button.tex:SetTexture("interface/icons/inv_misc_spyglass_03")
        button:SetScript("OnClick", function()
          frame.SearchWidget:SetShown(not frame.SearchWidget:IsShown())
          frame:GetTitleText():SetShown(not frame.SearchWidget:IsShown())
          frame:OnFinished()
        end)
        frame.SearchWidget:Hide()
        table.insert(frame.TopButtons, button)
        hooksecurefunc(frame.SearchWidget, "SetSpacing", function(self, sideSpacing)
          self.SearchBox:ClearAllPoints()
          self.SearchBox:SetPoint("TOPLEFT", button, "TOPRIGHT", sideSpacing, 1)
          self.SearchBox:SetPoint("RIGHT", self:GetParent(), "RIGHT", -sideSpacing - 150, 0)
        end)
      end
      do
        local button = GenerateButton(frame)
        button.tooltipText = BAGANATOR_L_CUSTOMISE_BAGANATOR
        button:SetPoint("RIGHT", frame.CloseButton, "LEFT", -3, 0)
        button:SetPoint("TOP", frame, 0, -4)
        button.tex:SetTexture("interface/icons/trade_engineering.blp")
        button:SetScript("OnClick", function()
          frame.CustomiseButton:Click()
        end)
        table.insert(frame.AllFixedButtons, button)
      end
      do
        local text = frame:GetTitleText()
        text:SetHeight(16)
        text:SetJustifyH("LEFT")
        text:SetPoint("LEFT", frame.TopButtons[#frame.TopButtons], "RIGHT", 10, 0)
        text:SetPoint("RIGHT", frame.AllFixedButtons[#frame.AllFixedButtons], "LEFT", -10, 0)
      end
    end
  end,
  SearchBox = function(frame)
  end,
  EditBox = function(frame)
  end,
  TabButton = function(frame)
  end,
  TopTabButton = function(frame)
  end,
  SideTabButton = function(frame)
  end,
  TrimScrollBar = function(frame)
  end,
  CheckBox = function(frame)
  end,
  Slider = function(frame)
  end,
  InsetFrame = function(frame)
  end,
  CornerWidget = function(frame, tags)
  end,
  Dropdown = function(button)
  end,
}

local function ConvertTags(tags)
  local res = {}
  for _, tag in ipairs(tags) do
    res[tag] = true
  end
  return res
end

local function SkinFrame(details)
  local func = skinners[details.regionType]
  if func then
    func(details.region, details.tags and ConvertTags(details.tags) or {})
  end
end

local function SetConstants()
  addonTable.Constants.ButtonFrameOffset = 0
end

local function LoadSkin()
  addonTable.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == "skins.legacystyle.view_transparency" then
      for _, frame in ipairs(allButtonFrames) do
        frame.NineSlice.Center:SetAlpha(1 - addonTable.Config.Get("skins.legacystyle.view_transparency"))
      end
    end
  end)
end

addonTable.Skins.RegisterSkin(BAGANATOR_L_LEGACY_STYLE, "legacystyle", LoadSkin, SkinFrame, SetConstants, {
  {
    type = "slider",
    min = 0,
    max = 100,
    lowText = "0%",
    highText = "100%",
    scale = 100,
    text = BAGANATOR_L_TRANSPARENCY,
    valuePattern = BAGANATOR_L_PERCENTAGE_PATTERN,
    option = "view_transparency",
    default = 0.4,
  },
})
