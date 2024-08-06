local _, addonTable = ...
local Locales = {
  enUS = {},
  frFR = {},
  deDE = {},
  ruRU = {},
  ptBR = {},
  esES = {},
  esMX = {},
  zhTW = {},
  zhCN = {},
  koKR = {},
  itIT = {},
}

BAGANATOR_LOCALES = Locales

local L = Locales.enUS

L["BAGANATOR"] = "Baganator"
L["TO_OPEN_OPTIONS_X"] = "Access options with /bgr"
L["VERSION_COLON_X"] = "Version: %s"
L["OPEN_OPTIONS"] = "Open Options"

L["BANK"] = "Bank"
L["REAGENTS"] = "Reagents"
L["KEYS"] = "Keys"
L["XS_BANK_AND_BAGS"] = "%s's Bank and Bags"
L["XS_BAGS"] = "%s's Bags"
L["XS_BANK"] = "%s's Bank"
L["XS_GUILD_BANK"] = "%s's Guild Bank"
L["ALL_CHARACTERS"] = "All Characters"
L["BAG_SLOTS"] = "Bag Slots"
L["GUILD_BANK"] = "Guild Bank"
L["BANK_DATA_MISSING_HINT"] = "Bank data missing. Visit a banker with %s to populate this view."
L["WARBAND_BANK_DATA_MISSING_HINT"] = "Warband Bank data missing. Visit a banker with any character to populate this view."
L["WARBAND_BANK_TEMPORARILY_DISABLED_HINT"] = "Warband Bank temporarily disabled by Blizzard."
L["WARBAND_BANK_NOT_PURCHASED_HINT"] = "Warband Bank space not purchased. Use the new tab button on the right to purchase"
L["GUILD_BANK_DATA_MISSING_HINT"] = "This guild bank hasn't been visited yet."
L["GUILD_BANK_NO_TABS"] = "There are no tabs in this guild bank."
L["CHARACTER"] = "Character"
L["WARBAND"] = "Warband"

L["CUSTOMISE_BAGANATOR"] = "Customise Baganator"
L["VIEW_TYPE"] = "View type"
L["SINGLE_BAG"] = "Single bag"
L["CATEGORY_GROUPS"] = "Category groups"
L["BRACKETS_RELOAD_REQUIRED"] = "(reload required)"
L["RESET_POSITIONS"] = "Reset Positions"
L["LOCK_WINDOWS"] = "Lock windows"
L["CHANGE_WINDOW_ANCHORS"] = "Change window anchors"
L["REMOVE_BORDERS"] = "Remove borders"
L["SHOW_SORT_BUTTON"] = "Show sort button"
L["ITEM_QUALITY"] = "Item Quality"
L["ITEM_TYPE"] = "Item Type"
L["BLIZZARD"] = "Blizzard"
L["SORTBAGS"] = "SortBags"
L["COMBINE_STACKS_ONLY"] = "Combine Stacks Only"
L["SORT_METHOD_2"] = "Sort method"
L["HIDE_ICON_BACKGROUNDS"] = "Hide icon backgrounds"
L["TRANSPARENCY"] = "Transparency"
L["BAG_COLUMNS"] = "Bag columns"
L["BANK_COLUMNS"] = "Bank columns"
L["WARBAND_BANK_COLUMNS"] = "Warband bank columns"
L["GUILD_BANK_COLUMNS"] = "Guild bank columns"
L["ICON_SIZE"] = "Icon size"
L["PIXEL_PATTERN"] = "%spx"
L["PERCENTAGE_PATTERN"] = "%s%%"
L["HIDE_BOE_STATUS_ON_COMMON_2"] = "Hide BoE status on junk/common"
L["RECENT_CHARACTER_TABS"] = "Recent character tabs"
L["ITEM_QUALITY_TEXT_COLORS"] = "Item quality text colors"
L["ICON_TEXT_FONT_SIZE"] = "Icon font size"
L["ITEM_LEVEL"] = "Item Level"
L["QUANTITY"] = "Quantity"
L["EXPANSION"] = "Expansion"
L["ICON_CORNERS"] = "Icon Corners"
L["PAWN"] = "Pawn"
L["CAN_I_MOG_IT"] = "Can I Mog It"
L["PEDDLER"] = "Peddler"
L["SELLJUNK"] = "SellJunk"
L["SCRAP"] = "Scrap"
L["POOR_QUALITY"] = "Poor quality"
L["EQUIPMENT_SET"] = "Equipment Set"
L["BLANK_SPACE"] = "Blank space"
L["AT_THE_BOTTOM"] = "At the bottom"
L["AT_THE_TOP"] = "At the top"
L["FLASH_DUPLICATE_ITEMS"] = "Flash duplicate items"
L["ALT_CLICK"] = "Alt+Click"
L["REDUCE_UI_SPACING"] = "Reduce UI spacing"
L["SHOW_BUTTONS"] = "Show buttons"
L["ALWAYS"] = "Always"
L["WHEN_HOLDING_ALT"] = "When holding Alt"
L["LAYOUT"] = "Layout"
L["THEME"] = "Theme"
L["CATEGORIES"] = "Categories"
L["FROM_THE_TOP"] = "From the top"
L["FROM_THE_BOTTOM"] = "From the bottom"
L["PLUGINS"] = "Plugins"
L["SKINS"] = "Skins"
L["TIPS_SEARCH"] = "Powerful, flexible, and fast. Use flexible query operators & (and), | (or), and ! (not) to find exactly what you need."
L["TIPS_PLUGINS"] = "Enhance Baganator with addtional features powered by integrations with popular addons like AllTheThings, CanIMogIt, Pawn, Dejunk, and more..."
L["TIPS_TRANSFER"] = "Search for items, then use the transfer button to easily move them to your bank, a mail message, the trade window, or a vendor."
L["TIPS_SKINS_2"] = "Make Baganator match your UI with themes for ElvUI, GW2, or a simple dark option. Installed separately."
L["SEARCH_HELP"] = "Search Help"
L["JOIN_THE_DISCORD"] = "Join the Discord"
L["DISCORD_DESCRIPTION"] = "Updates, feature suggestions and support"
L["BY_PLUSMOUSE"] = "by plusmouse"

L["DEPOSIT_REAGENTS"] = "Deposit Reagents"
L["BUY_REAGENT_BANK"] = "Buy Reagent Bank"

L["MANAGE_CHARACTERS"] = "Manage Characters"

L["BOE"] = "BoE"
L["BIND_ON_EQUIP"] = "Bind on Equip"
L["BOA"] = "BoA"
L["BIND_ON_ACCOUNT"] = "Bind on Account"
L["BOU"] = "BoU"
L["BIND_ON_USE"] = "Bind on Use"
L["TL"] = "TL"
L["TRADEABLE_LOOT"] = "Tradeable Loot"
L["BATTLE_PET_BREEDID"] = "Battle Pet BreedID"
L["BATTLE_PET_LEVEL"] = "Battle Pet Level"
L["JUNK"] = "Junk"
L["ENGRAVED_RUNE"] = "Engraved Rune"
L["KEYSTONE_LEVEL"] = "Keystone Level"
L["ADD_ITEM"] = "Add item"

L["SORT"] = "Sort"
L["USING_X"] = "Using %s"
L["SORTING"] = "Sorting"
L["REVERSE_GROUPS_SORT_ORDER"] = "Reverse groups sort order"
L["ARRANGE_ITEMS"] = "Arrange items"
L["IGNORED_SLOTS"] = "Ignored slots"
L["IGNORED_BAG_SLOTS"] = "Ignored bag slots (character specific)"
L["IGNORED_BANK_SLOTS"] = "Ignored bank slots (character specific)"
L["SORT_ON_OPEN"] = "Sort on open"
L["GUILD_BANK_SORT_METHOD"] = "Guild Bank Sort Method"

L["SEARCH_TRY_X"] = "Search, try %s"

L["GENERAL"] = "General"
L["ICONS"] = "Icons"
L["TOOLTIP_SETTINGS"] = "Tooltip settings"
L["OPEN_SYNDICATOR"] = "Open Syndicator"
L["GREY_JUNK_ITEMS"] = "Grey out junk items"
L["JUNK_DETECTION_2"] = "Junk detection"

L["REALM_WIDE_GOLD_X"] = "Realm-wide gold: %s"
L["ACCOUNT_GOLD_X"] = "Account gold: %s"
L["REALM_X_X_X"] = "%s (x%s)"
L["HOLD_SHIFT_TO_SHOW_ACCOUNT_TOTAL"] = "<Hold shift to show account total>"

L["CRAFTING_WINDOW"] = "Crafting Window"
L["AUCTION_HOUSE"] = "Auction House"
L["VOID_STORAGE"] = "Void Storage"
L["MAIL"] = "Mail"
L["VENDOR"] = "Vendor"
L["AUTO_OPEN"] = "Auto Open"
L["TRADE"] = "Trade"
L["GUILD_BANK"] = "Guild Bank"
L["SOCKET_INTERFACE"] = "Socket Interface"
L["SCRAPPING_MACHINE"] = "Scrapping Machine"
L["FORGE_OF_BONDS"] = "Forge of Bonds"
L["CHARACTER_PANEL"] = "Character Panel"

L["TRANSFER"] = "Transfer"
L["TRANSFER_BANK_VIEW_TOOLTIP_TEXT"] = "Move searched for items out from the bank into the bags."
L["TRANSFER_MAIN_VIEW_BANK_TOOLTIP_TEXT"] = "Move searched for items out from the bags into the bank."
L["TRANSFER_MAIN_VIEW_MAIL_TOOLTIP_TEXT"] = "Attach the searched for items to a mail for sending."
L["TRANSFER_MAIN_VIEW_SCRAPPER_TOOLTIP_TEXT"] = "Place scrappable items into the scrapping machine."
L["TRANSFER_MAIN_VIEW_MERCHANT_TOOLTIP_TEXT_2"] = "Sell searched for items to the merchant (max 6)."
L["TRANSFER_MAIN_VIEW_TRADE_TOOLTIP_TEXT"] = "Add searched for items to the trade window (up to 6 items)."
L["TRANSFER_MAIN_VIEW_GUILD_TOOLTIP_TEXT"] = "Move searched for items out from the bags into the guild bank.\n\nTransfers are slow due to the underlying guild bank being slow."
L["TRANSFER_GUILD_VIEW_TOOLTIP_TEXT"] = "Move searched for items out from the guild bank into the bags.\n\nTransfers are slow due to the underlying guild bank being slow."

L["CONFIRM_TRANSFER_ALL_ITEMS_FROM_BAG"] = "Do you want to transfer ALL items in your bags?"
L["CONFIRM_TRANSFER_ALL_ITEMS_FROM_BANK"] = "Do you want to transfer ALL items from the bank?"
L["CONFIRM_TRANSFER_ALL_ITEMS_FROM_GUILD_BANK"] = "Do you want to transfer ALL items from the guild bank?"
L["THE_MERCHANT_DOESNT_WANT_ANY_OF_THOSE_ITEMS"] = "The merchant doesn't want any of those items"
L["CANNOT_ADD_ANY_MORE_ITEMS_TO_THIS_TRADE"] = "Cannot add any more items to this trade"
L["CANNOT_WITHDRAW_ANY_MORE_ITEMS_FROM_THE_GUILD_BANK"] = "Cannot withdrawl any more items from the guild bank"

L["UNLIMITED"] = "Unlimited"
L["GUILD_WITHDRAW_DEPOSIT_X_X"] = "Items - Withdraw: %s | Deposit: %s"
L["GUILD_MONEY_X_X"] = "Gold - Withdraw: %s | Total: %s"
L["GUILD_MONEY_X"] = "Gold - Total: %s"
L["TAB_INFO"] = "Tab Information"
L["GUILD_TAB_INFO_TOOLTIP_TEXT"] = "See any stored information about this tab"
L["TAB_LOGS"] = "Tab Logs"
L["GUILD_TAB_LOGS_TOOLTIP_TEXT"] = "See withdrawals and deposits of items for this tab"
L["MONEY_LOGS"] = "Money Logs"
L["GUILD_MONEY_LOGS_TOOLTIP_TEXT"] = "See withdrawals and deposits of money for the guild bank"
L["X_LOGS"] = "%s Logs"
L["X_INFORMATION"] = "%s Information"
L["MONEY_LOGS"] = "Money Logs"
L["NO_TRANSACTIONS_AVAILABLE"] = "No Transactions Available"
L["CANNOT_EDIT_GUILD_BANK_TAB_ERROR"] = "You do not have permissions to edit this tab"
L["GUILD_NO_TABS_PURCHASED"] = "No guild bank tabs purchased"

L["BUY_WARBAND_BANK_TAB"] = "Buy Warband Bank Tab?"
L["DEPOSIT_WARBOUND"] = "Deposit Warbound Items"
L["INCLUDE_REAGENTS"] = "Include Reagents"
L["EVERYTHING"] = "Everything"

L["SEARCH_EVERYWHERE"] = "Search Everywhere"
L["SEARCH_EVERYWHERE_TOOLTIP_TEXT_2"] = "Will print the search results to your chat."
L["THAT_ITEM_IS_EQUIPPED"] = "That item is equipped"
L["THAT_ITEM_IS_LISTED_ON_THE_AUCTION_HOUSE"] = "That item is listed on the auction house"
L["THAT_ITEM_IS_IN_A_MAILBOX"] = "That item is in a mailbox"
L["THAT_ITEM_IS_IN_VOID_STORAGE"] = "That item is in void storage"

L["THAT_ITEM_IS_EQUIPPED"] = "That item is equipped"
L["THAT_ITEM_IS_LISTED_ON_THE_AUCTION_HOUSE"] = "That item is listed on the auction house"
L["THAT_ITEM_IS_IN_A_MAILBOX"] = "That item is in a mailbox"
L["THAT_ITEM_IS_IN_VOID_STORAGE"] = "That item is in void storage"

L["SOUL"] = "Soul"
L["HERBALISM"] = "Herbalism"
L["ENCHANTING"] = "Enchanting"
L["ENGINEERING"] = "Engineering"
L["GEMS"] = "Gems"
L["MINING"] = "Mining"
L["LEATHERWORKING"] = "Leatherworking"
L["INSCRIPTION"] = "Inscription"
L["FISHING"] = "Fishing"
L["COOKING"] = "Cooking"
L["JEWELCRAFTING"] = "Jewelcrafting"

L["CATEGORY_BAG"] = "Bag"
L["CATEGORY_HEARTHSTONE"] = "Hearthstone"
L["CATEGORY_OTHER"] = "Other"
L["CATEGORY_JUNK"] = "Junk"
L["CATEGORY_POTION"] = "Potion"
L["CATEGORY_FOOD"] = "Food"
L["CATEGORY_TOY"] = "Toy"
L["CATEGORY_AUTO_EQUIPMENT_SETS"] = "Auto: Equipment Sets"
L["CATEGORY_EQUIPMENT_SETS_AUTO"] = "Equipment Sets (Auto)"
L["CATEGORY_EQUIPMENT_SET"] = "Equipment Set"
L["CATEGORY_INVENTORY_SLOTS_AUTO"] = "Inventory Slots (Auto)"
L["CATEGORY_RECENT"] = "Recent"
L["CATEGORY_RECENT_AUTO"] = "Recent (Auto)"
L["CATEGORY_DIVIDER"] = "———Divider———"
L["CATEGORY_TRADESKILLMASTER_AUTO"] = "TradeSkillMaster (Auto)"

L["CATEGORY_SPACING"] = "Category spacing"
L["EDIT"] = "Edit"
L["CTRL_C_TO_COPY"] = "Ctrl+C to copy"
L["PASTE_YOUR_IMPORT_STRING_HERE"] = "Paste your import string here"
L["EXPORT"] = "Export"
L["IMPORT"] = "Import"
L["USE_DEFAULT"] = "Use Default"
L["REVERT_CHANGES"] = "Revert Changes"
L["PRIORITY"] = "Priority"
L["INSERT_OR_CREATE"] = "Insert or create"
L["CREATE_NEW_CATEGORY"] = "Create new category..."
L["CREATE_NEW_SECTION"] = "Create new section..."
L["CREATE_NEW_DIVIDER"] = "Create new divider..."
L["REMOVE_FROM_CATEGORY"] = "Remove from category"
L["NEW_CATEGORY"] = "New Category"
L["NEW_SECTION"] = "New Section"
L["GROUP_IDENTICAL_ITEMS"] = "Group identical items"
L["BRACKETS_CATEGORY_VIEW_ONLY"] = "(category view only)"
L["LOW"] = "Low"
L["NORMAL"] = "Normal"
L["HIGH"] = "High"
L["HIGHER"] = "Higher"
L["HIGHEST"] = "Highest"
L["ADD_TO_CATEGORY"] = "Add to category"
L["REMOVE_FROM_CATEGORY"] = "Remove from category"
L["EMPTY"] = "Empty"
L["SORT_METHOD_RESET_FOR_CATEGORIES"] = "Sort method reset to be used with categories"
L["MOVE"] = "Move"
L["INVALID_CATEGORY_IMPORT_FORMAT"] = "Invalid category import format"
L["HIDDEN"] = "Hidden"
L["SLOT"] = "Slot"
L["TYPE"] = "Type"
L["QUALITY"] = "Quality"
L["NONE"] = "None"
L["GROUP_BY"] = "Group by"
L["SHOW_ADD_BUTTONS"] = "Show add buttons"
L["BRACKETS_WHILE_DRAGGING"] = "(while dragging)"
L["RECENT_TIMER"] = "Recent timer"
L["IMMEDIATE"] = "Immediate"
L["FOREVER"] = "Forever"
L["RECENT_HEADER_CLICK_MESSAGE"] = "Click heading to clear immediately."
L["GROUP_EMPTY_SLOTS"] = "Group empty slots"
L["ITEMS"] = "Items"
L["ADD"] = "Add"
L["ADD_ITEM_IDS_MESSAGE"] = "Add a list of items by item ID"

L["HELP_COLON_SEARCH"] = "Help: Search"
L["HELP"] = "Help"
L["HELP_SEARCH_OPERATORS"] = "Operators"
L["HELP_SEARCH_OPERATORS_LINE_1"] = "& (and), | (or), ! (not), # (exact keyword)"
L["HELP_SEARCH_OPERATORS_LINE_2"] = "The operators are evaluated in the following order of precedence: ! (not), & (and), and | (or)."
L["HELP_SEARCH_OPERATORS_LINE_3"] = "Example: !A & B | C is evaluated as ((!A) & B) | C."
L["HELP_SEARCH_ITEM_LEVEL"] = "Item Level"
L["HELP_SEARCH_ITEM_LEVEL_LINE_1"] = "123 (exact level), <123 (levels lower), >123 (levels higher), 123-234 (levels between)"
L["HELP_SEARCH_ITEM_LEVEL_LINE_2"] = "Example: #gear&>242"
L["HELP_SEARCH_KEYWORDS"] = "Keywords"
L["HELP_SEARCH_KEYWORDS_LINE_1"] = "Your search will look for matches in two places: within a set of specified keywords and within the item name and tooltip descriptions. To search for an exact keyword only, use a hashtag (#) before the keyword."
L["HELP_SEARCH_KEYWORDS_LINE_2"] = "Example: #gear&explorer"

L["WELCOME_TO_BAGANATOR"] = "Welcome to Baganator"
L["WELCOME_DESCRIPTION"] = "Decide which kind of bags you want. This can be changed later."
L["CHOOSE"] = "Choose"
L["SINGLE_BAG_DESCRIPTION"] = "The most common option. Keeps your items in one large container."
L["CATEGORY_GROUPS_DESCRIPTION"] = "Group items by type, with features to add new custom categories."

L["CATEGORIES_FAILED_WARNING"] = "Something went wrong when displaying the categories.\n\nFailed search was \"%s\". The following items failed:\n%s\n\nScreenshot this and visit the discord:"

L["BINDING_OPEN_BANK"] = "Open Bank"
L["BINDING_OPEN_WARBAND_BANK"] = "Open Warband Bank"
L["BINDING_OPEN_GUILD_BANK"] = "Open Guild Bank"
L["BINDING_QUICK_SEARCH"] = "Quick Search"

L["SYNDICATOR_ENABLE_MESSAGE"] = "|cffd1b219Syndicator|r is required to use Baganator."
L["SYNDICATOR_INSTALL_MESSAGE"] = "Use your addon website/client to install |cffd1b219Syndicator|r in order to use Baganator."

local L = Locales.frFR
--@localization(locale="frFR", format="lua_additive_table")@

local L = Locales.deDE
--@localization(locale="deDE", format="lua_additive_table")@

local L = Locales.ruRU
--@localization(locale="ruRU", format="lua_additive_table")@

local L = Locales.esES
--@localization(locale="esES", format="lua_additive_table")@

local L = Locales.esMX
--@localization(locale="esMX", format="lua_additive_table")@

local L = Locales.zhTW
--@localization(locale="zhTW", format="lua_additive_table")@

local L = Locales.zhCN
--@localization(locale="zhCN", format="lua_additive_table")@

local L = Locales.koKR
--@localization(locale="koKR", format="lua_additive_table")@

local L = Locales.itIT
--@localization(locale="itIT", format="lua_additive_table")@
