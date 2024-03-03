function Baganator.Search.Initialize()
  Baganator.Search.InitializeSearchEngine()

  SlashCmdList["BaganatorSearch"] = function(term)
    Baganator.Search.RequestMegaSearchResults(term, function(results)
      print(GREEN_FONT_COLOR:WrapTextInColorCode(BAGANATOR_L_SEARCH_MATCHES_COLON) .. " " .. YELLOW_FONT_COLOR:WrapTextInColorCode(term))
      for _, r in ipairs(results) do
        local item = r.itemLink .. BLUE_FONT_COLOR:WrapTextInColorCode("x" .. r.itemCount)
        if r.source.character then
          local character = r.source.character
          local characterData = BAGANATOR_DATA.Characters[r.source.character]
          if not characterData.details.hidden then
            local className = characterData.details.className
            if className then
              character = RAID_CLASS_COLORS[className]:WrapTextInColorCode(character)
            end
            print("   ", item, PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(r.source.container), character)
          end
        elseif r.source.guild then
          print("   ", r.itemLink .. BLUE_FONT_COLOR:WrapTextInColorCode("x" .. r.itemCount), TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(r.source.guild))
        end
      end
    end)
  end
  SLASH_BaganatorSearch1 = "/baganatorsearch"
  SLASH_BaganatorSearch2 = "/bgrs"
end
