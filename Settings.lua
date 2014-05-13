local Log = LOG_FACTORY:GetLog("Backpack")

local BACKPACK_SETTINGS_PANEL = "BACKPACK_SETTINGS_PANEL"
local BACKPACK_HEADER_DISPLAY_OPTIONS = "BP_MENU_HEADER_DISPLAY_OPTIONS"


local BACKPACK_DEFAULT_SETTINGS = {
	version = 3,
	name = "BackpackSettings",
	logLevel = "Warn",
	firstRun = true,
	ui = {
		hideEmptyGroups = true,
		emptyBorderColor = { 0.33, 0.33, 0.33, 1.0 },
		iconSize = 64,
		scale = 0.9,
		group = {
			font = "ZoFontWinH1",
			minColumnCount = 3,
			maxColumnCount = 10,
			clampToScreen = true,
			padding = 4,
			insets 	= { top = 10,  left=10, bottom=10, right=10},
			backdrop = {
				centerTexture = nil,
				centerColor = { 0, 0, 0, 0.3},
				edgeTexture = nil,
				edgeColor = { 0.1, 0.1, 0.1, 0.8},
				edgeWidth = 1,
				edgeHeight = 1,
			},
		},
		windows = {
			['*'] = {
				top 	= 0,
				left  	= 0,
				width 	= 100,
				height 	= 100,
				insets 	= { top = 10,  left=10, bottom=10, right=10},
			}
		},

		groups = {
			['*'] = {
				['*'] = {
					top = 50,
					left = 50,
					columns =  6,
					rows =  2
				},
				hidden = false
			},
			
		}
	},

	scenes = {
		store = {
			name = "store",
			visible = true
		},
		bank = {
			name = "bank",
			visible = true
		},
		trade = {
			name = "trade",
			visible = true
		},
		tradinghouse = {
			name = "tradinghouse",
			visible = true
		},
	},

	groups = {
		empty = true,
		default = true,
		weapons = true,
		apparel = true,
		consumable = true,
		crafting = true,
		misc = true,
		quest = true,
		junk = true
	}
}

BackpackSettings = ZO_Object:Subclass()
BackpackSettings.savedVars = nil

function BackpackSettings:New()
	local obj = ZO_Object.New(self)

	obj.uiWidth = math.floor(GuiRoot:GetWidth() + 0.5)
	obj.uiHeight = math.floor(GuiRoot:GetHeight() + 0.5)

	obj.widthFactor = obj.uiWidth / 1920
	obj.heightFactor = obj.uiHeight / 1080

	return obj
end

function BackpackSettings:GetResIndependentPos(x, y)
	local rX, rY = nil, nil
	if x then rX = x*self.widthFactor end
	if y then rY = y*self.heightFactor end

	return rX, rY
end

function BackpackSettings:OnAddOnLoaded()
	BACKPACK.settings = ZO_SavedVars:NewAccountWide("Backpack_Settings", BACKPACK_DEFAULT_SETTINGS.version, nil, BACKPACK_DEFAULT_SETTINGS);
	LOG_FACTORY:SetStrLevel(BACKPACK.settings.logLevel)
end

function BackpackSettings:CreateSettingsMenu()
	local LAM = LibStub("LibAddonMenu-1.0");
	assert(LAM)

	local menu = LAM:CreateControlPanel(BACKPACK_SETTINGS_PANEL, "Backpack")

	LAM:AddHeader(menu, BACKPACK_HEADER_DISPLAY_OPTIONS, "Display Options")
	LAM:AddSlider(menu, "BP_ICON_SIZE", "Icon Size", "", 16, 256, 1,
	function() return BACKPACK.settings.ui.iconSize end,
	function(value)
		BACKPACK.settings.ui.iconSize = value
		BACKPACK:UpdateGroups()
	end
	)
	LAM:AddSlider(menu, "BP_UI_SCALE", "Scale", "", 25, 250, 1,
	function() return BACKPACK.settings.ui.scale*100 end,
	function(value)
		BACKPACK.settings.ui.scale = value/100
		BACKPACK:UpdateGroups()
	end
	)


	LAM:AddHeader(menu, "BP_MENU_HEADER_GROUPS", "Groups")

	local groupInfos = {
		{
			name = "weapons",
			desc = "Show Weapons",
			tooltip = "",
			idx = 1
		},
		{
			name = "apparel",
			desc = "Show Apparel",
			tooltip = "",
			idx = 2
		},
		{
			name = "consumable",
			desc = "Show Consumable",
			tooltip = "",
			idx = 3
		},
		{
			name = "crafting",
			desc = "Show Crafting",
			tooltip = "",
			idx = 4
		},

		{
			name = "misc",
			desc = "Show Miscallaneous",
			tooltip = "",
			idx = 5
		},

		--		{
		--			name = "quest",
		--			desc = "Show Quest",
		--			tooltip = "",
		--			idx = 6
		--		},


		{
			name = "junk",
			desc = "Show Junk",
			tooltip = "",
			idx = 7
		},

		{
			name = "empty",
			desc = "Show Empty Slots",
			tooltip = "",
			idx = 8
		},

		{
			name = "default",
			desc = "Show Lost and Found",
			tooltip = "",
			idx = 8
		},

	}
	local addGroups = function(infos)
		for _, info in pairs(groupInfos) do
			LAM:AddCheckbox(menu, "BP_HIDE_GROUP_"..zo_strupper(info.name), info.desc, tooltip,
			function()
				local g = BACKPACK.groups[info.idx];
				return not BACKPACK.settings.ui.groups[g.name].hidden 
			end,
			function(val)
				--changing group indices in Backpack.lua will break settings :(
				local g = BACKPACK.groups[info.idx];
				BACKPACK.settings.ui.groups[g.name].hidden = not val
				g.fragment.forceHidden = not val
			end
			)
		end
	end
	addGroups(groupInfos);
	LAM:AddHeader(menu, "BP_MENU_HEADER_INTERACTION", "Interaction")
	LAM:AddCheckbox(menu, "BP_SHOW_AT_STORE", "Show at Store", "",
	function() return BACKPACK.settings.scenes.store.visible end,
	function(val)
		BACKPACK.settings.scenes.store.visible = val
		BACKPACK:UpdateScene("store")
	end
	)

	LAM:AddCheckbox(menu, "BP_SHOW_AT_BANK", "Show at Bank", "",
	function() return BACKPACK.settings.scenes.bank.visible end,
	function(val)
		BACKPACK.settings.scenes.bank.visible = val
		BACKPACK:UpdateScene("bank")
	end
	)

	LAM:AddCheckbox(menu, "BP_SHOW_AT_TRADEHOUSE", "Show at Tradinghouse", "",
	function() return BACKPACK.settings.scenes.tradinghouse.visible end,
	function(val)
		BACKPACK.settings.scenes.tradinghouse.visible = visible
		BACKPACK:UpdateScene("tradinghouse")
	end
	)

	LAM:AddCheckbox(menu, "BP_SHOW_IN_TRADES", "Show in Trades", "",
	function() return BACKPACK.settings.scenes.trade.visible end,
	function(val)
		BACKPACK.settings.scenes.trade.visible = val
		BACKPACK:UpdateScene("trade")
	end
	)

	LAM:AddHeader(menu, "BP_MENU_HEADER_LOGGING", "Logging")
	LAM:AddDropdown(menu, "BP_LOG_LEVEL", "Log Level", "", LOG_PREFIXES,
	function()
		return BACKPACK.settings.logLevel
	end,
	function(val)
		BACKPACK.settings.logLevel = val
		LOG_FACTORY:SetStrLevel(val)
	end
	)
end