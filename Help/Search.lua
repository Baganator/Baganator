local _, addonTable = ...
function addonTable.Help.GetKeywordGroups()
  local searchTerms = Syndicator.API.GetSearchKeywords()
  local groupsList = {}
  local groups = {}
  local seenInGroup = {}
  for _, term in ipairs(searchTerms) do
    groups[term.group] = groups[term.group] or {}
    seenInGroup[term.group] = seenInGroup[term.group] or {}

    if not seenInGroup[term.group][term.keyword] then
      table.insert(groups[term.group], term.keyword)
      seenInGroup[term.group][term.keyword] = true
    end
  end

  return groups
end

function addonTable.Help.ShowSearchDialog()
  if Baganator_SearchHelpFrame then
    Baganator_SearchHelpFrame:SetShown(not Baganator_SearchHelpFrame:IsShown())
    Baganator_SearchHelpFrame:Raise()
    return
  end

  local groups = addonTable.Help.GetKeywordGroups()
  local text = ""
  for _, key in ipairs(addonTable.Constants.KeywordGroupOrder) do
    if groups[key] then
      table.sort(groups[key])
      text = text .. "==" .. key .. "\n" .. table.concat(groups[key], ", ") .. "\n"
    end
  end

  local frame = CreateFrame("Frame", "Baganator_SearchHelpFrame", UIParent, "ButtonFrameTemplate")
  ButtonFrameTemplate_HidePortrait(frame)
  ButtonFrameTemplate_HideButtonBar(frame)
  frame.Inset:Hide()
  addonTable.Skins.AddFrame("ButtonFrame", frame)
  frame:EnableMouse(true)
  frame:SetPoint("CENTER")
  frame:SetToplevel(true)
  table.insert(UISpecialFrames, frame:GetName())

  if TSM_API then
    frame:SetFrameStrata("HIGH")
  end

  frame:RegisterForDrag("LeftButton")
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:SetScript("OnDragStart", function()
    frame:StartMoving()
    frame:SetUserPlaced(false)
  end)
  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    frame:SetUserPlaced(false)
  end)

  frame:SetTitle(BAGANATOR_L_HELP_COLON_SEARCH)
  frame:SetSize(430, 500)

  frame.ScrollBox = CreateFrame("Frame", nil, frame, "WowScrollBox")
  frame.ScrollBox:SetPoint("TOP", 0, -25)
  frame.ScrollBox:SetPoint("LEFT", addonTable.Constants.ButtonFrameOffset + 20, 0)
  frame.ScrollBox.Content = CreateFrame("Frame", nil, frame.ScrollBox, "ResizeLayoutFrame")
  frame.ScrollBox.Content.scrollable = true
  frame.ScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
  frame.ScrollBar:SetPoint("TOPRIGHT", -10, -30)
  frame.ScrollBar:SetPoint("BOTTOMRIGHT", -10, 10)
  frame.ScrollBox:SetPoint("RIGHT", frame.ScrollBar, "LEFT", -10, 0)
  frame.ScrollBox:SetPoint("BOTTOM", 0, 5)

  local lines = {
    { type = "header", text = BAGANATOR_L_HELP_SEARCH_OPERATORS},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_OPERATORS_LINE_1},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_OPERATORS_LINE_2},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_OPERATORS_LINE_3},
    { type = "header", text = BAGANATOR_L_HELP_SEARCH_ITEM_LEVEL},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_ITEM_LEVEL_LINE_1},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_ITEM_LEVEL_LINE_2},
    { type = "header", text = BAGANATOR_L_HELP_SEARCH_KEYWORDS},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_KEYWORDS_LINE_1},
    { type = "content", text = BAGANATOR_L_HELP_SEARCH_KEYWORDS_LINE_2},
  }
  for _, key in ipairs(addonTable.Constants.KeywordGroupOrder) do
    if groups[key] then
      table.insert(lines, {type = "header_2", text = key})
      table.insert(lines, {type = "content", text = table.concat(groups[key], ", ")})
    end
  end

  local lastRegion
  for _, l in ipairs(lines) do
    local font, offsetY = "GameFontHighlight", -8
    if l.type == "header" then
      offsetY = - 18
      font = "GameFontNormalLarge"
    elseif l.type == "header_2" then
      offsetY = - 15
      font = "GameFontNormalMed1"
    end
    local fontString = frame.ScrollBox.Content:CreateFontString(nil, "ARTWORK", font)
    fontString:SetText(l.text)
    fontString:SetJustifyH("LEFT")
    fontString:SetPoint("LEFT")
    fontString:SetPoint("RIGHT")
    if l.type == "content" then
      fontString:SetSpacing(3)
    end
    if lastRegion then
      fontString:SetPoint("TOP", lastRegion, "BOTTOM", 0, offsetY)
    else
      fontString:SetPoint("TOP", 0, -10)
    end
    lastRegion = fontString
  end
  frame.ScrollBox.Content.OnCleaned = function()
    frame.ScrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately);
  end
  frame.ScrollBox.Content:MarkDirty()


  ScrollUtil.InitScrollBoxWithScrollBar(frame.ScrollBox, frame.ScrollBar, CreateScrollBoxLinearView(0, 20, 0, 0))
  frame.ScrollBox:SetPanExtent(50)
  frame:Raise()
end
