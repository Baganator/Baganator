function Baganator.Search.Initialize()
  Baganator.Search.InitializeSearchEngine()

  SlashCmdList["BaganatorSearch"] = Baganator.Search.RunMegaSearchAndPrintResults
  SLASH_BaganatorSearch1 = "/baganatorsearch"
  SLASH_BaganatorSearch2 = "/bgrs"
end
