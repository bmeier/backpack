local Log = LOG_FACTORY:GetLog("Backpack");

local Backpack = ZO_Object:Subclass();
Backpack.ADDON_NAME = "Backpack";
Backpack.ADDON_VERSION = 1;
Backpack.DEFAULT_SETTINGS = { 
	version = 2,
	name = "BackpackSettings",
	logLevel = "Warn",
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
			insets = 40,
		},
		windows = {
			['*'] = {
				top 	= 0,
				left  	= 0, 
				width 	= 100,
				height 	= 100,
				insets 	= { top = 10,  left=10, bottom=10, right=10},
				backdrop = {
					centerTexture = nil,
					centerColor = { 0, 0, 0, 0.3},
					edgeTexture = nil,
					edgeColor = { 0.1, 0.1, 0.1, 0.8},
					edgeWidth = 1,
					edgeHeight = 1,
				},
			}
		},

		groups = {
			['*'] = {
				columns = 6,
				rows = 0
			}
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

Backpack.bags = {};
Backpack.filter = {};
Backpack.groups = {}
Backpack.ui = nil;
Backpack.settings = nil;

function Backpack:New()
	local r = ZO_Object.New( self );
	return r;
end

function Backpack:OnLoad() 
	ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_BACKPACK", "Toggle Backpack")
	--ZO_CreateStringId("SI_BINDING_NAME_SEARCH_BACKPACK", "Search Backpack")
	
	self:LoadSettings();
	self:CreateBags();
	self:CreateDefaultGroups();

	self:UpdateGroups();

	for i, group in pairs(self.groups) do	
		BACKPACK_SCENE:AddFragment(group.fragment)
		for name, scene in pairs(self.settings.scenes) do
			if scene.visible then
				SCENE_MANAGER:GetScene(name):AddFragment(group.fragment)
			end
		end
	end

	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnSlotUpdate( ... ); end);
	Log:D("Backpack loaded.");
end

function Backpack:UpdateScene( name )
	local settings = self.settings.scenes[name]
	local scene = SCENE_MANAGER:GetScene( settings.name )
	
	if( scene) then
		if ( settings.visible  ) then
			for i, group in pairs(self.groups) do
				if(not scene.fragments[group.fragment]) then
					scene:AddFragment(group.fragment)
				end
			end
		else
			for i, group in pairs(self.groups) do
				if(scene.fragments[group.fragment]) then
					scene.fragments[group.fragment] = nil --outch
				end
			end
			
		end
	else
		assert(false)
	end

end

function Backpack:OnSlotUpdate( eventid,  bagId, slotIdx, isNewItem, itemSoundCategory, updateReason )
	Log:T("OnSlotUpdate: bagid: ", bagId, ", slotIdx: ", slotIdx, ", reason: ", updateReason)
	if(updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT) then
		Log:D("Slot update dropped: Wrong reason: "..updateReason)
		return
	end
		
	if(bagId == 1 and updateReason == INVENTORY_UPDATE_REASON_DEFAULT) then
		if(slotIdx > 0) then
			local bag = self.bags[bagId];
			Log:D("Updating sot " ..slotIdx)
			bag:OnSlotUpdated(slotIdx, isNewItem)
			self:UpdateGroups();
		else
			Log:W("Slot update dropped, bagId: ", bagId, ", slotIdx: "..slotIdx)
		end
	end
end

function Backpack:CreateDefaultGroups() 
	-- 
	local filter = nil;
	
	local foodFilter = CreateFilter(FILTER_TYPES.ItemType, ITEMTYPE_DRINK);
	foodFilter.Name = "Food";
	table.insert(self.filter, foodFilter);

	local equipFilter = CreateFilter(FILTER_TYPES.ItemType, ITEMTYPE_ARMOR);
	equipFilter.Name = "Armor";
	table.insert(self.filter, equipFilter);

	local emptySlots =CreateFilter(FILTER_TYPES.EmptySlot);
	emptySlots.Name = "Empty";
	table.insert(self.filter, emptySlots);

	local defaultFilter =  Filter:New();
	defaultFilter.Name = "Default";
	table.insert(self.filter, defaultFilter);

	local group = nil;
	group = BackpackGroup:New("Weapons", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_WEAPONS));
	group.hidden = not self.settings.groups.weapons
	table.insert(self.groups, group)

	group =	BackpackGroup:New("Apparel", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_ARMOR))
	group.hidden = not self.settings.groups.apparel
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Consumable", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_CONSUMABLE))
	group.hidden = not self.settings.groups.consumable
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Crafting", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_CRAFTING))
	group.hidden = not self.settings.groups.crafting
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Misc", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_MISCELLANEOUS))
	group.hidden = not self.settings.groups.misc
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Quest", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_QUEST))
	group.hidden = not self.settings.groups.quest
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Junk", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_JUNK))
	group.hidden = not self.settings.groups.junk
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Empty", emptySlots)
	group.hidden = not self.settings.groups.empty
	table.insert(self.groups, group)	

	group = BackpackGroup:New("Lost and Found", defaultFilter)
	group.hidden = not self.settings.groups.default
	table.insert(self.groups, group)	
end


function Backpack:LoadSettings()
	self.settings = ZO_SavedVars:NewAccountWide("Backpack_Settings", self.DEFAULT_SETTINGS.version, nil, self.DEFAULT_SETTINGS);
	LOG_FACTORY:SetStrLevel(self.settings.logLevel)
	local LAM = LibStub("LibAddonMenu-1.0");
	local menu = LAM:CreateControlPanel("BACKPACK_SETTINGS_PANEL", "Backpack") --|cE73E01

	LAM:AddHeader(menu, "BP_MENU_HEADER_DISPLAY_OPTIONS", "Display Options")
	LAM:AddSlider(menu, "BP_ICON_SIZE", "Icon Size", "", 16, 256, 1,
		function() return self.settings.ui.iconSize end,
		function(value)
			self.settings.ui.iconSize = value
			BACKPACK:UpdateGroups()
		end
	)
	LAM:AddSlider(menu, "BP_UI_SCALE", "Scale", "", 25, 250, 1,
		function() return self.settings.ui.scale*100 end,
		function(value)
			self.settings.ui.scale = value/100
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
	 				return self.settings.groups[info.name] 
	 			end,
	 			function(val) 
	 				self.settings.groups[info.name]  = val  
	 				local g = self.groups[info.idx];
	 				if g then
	 					g.hidden = not (val == true)
	 				end
	 			end
	 		)
		end
	end
	addGroups(groupInfos);

	LAM:AddHeader(menu, "BP_MENU_HEADER_INTERACTION", "Interaction")
	LAM:AddCheckbox(menu, "BP_SHOW_AT_STORE", "Show at Store", "",
	 	function() return self.settings.scenes.store.visible end,
	 	function(val) 
	 		self.settings.scenes.store.visible = val
	  		self:UpdateScene("store")
	 	end
	)

	LAM:AddCheckbox(menu, "BP_SHOW_AT_BANK", "Show at Bank", "",
	 	function() return self.settings.scenes.bank.visible end,
	 	function(val) 
	 		self.settings.scenes.bank.visible = val
	 		self:UpdateScene("bank")
	 	end
	)

	LAM:AddCheckbox(menu, "BP_SHOW_AT_TRADEHOUSE", "Show at Tradinghouse", "",
	 	function() return self.settings.scenes.tradinghouse.visible end,
	 	function(val) 
	 		self.settings.scenes.tradinghouse.visible = visible
	 		self:UpdateScene("tradinghouse")
	 	end
	)

	LAM:AddCheckbox(menu, "BP_SHOW_IN_TRADES", "Show in Trades", "",
	 	function() return self.settings.scenes.trade.visible end,
	 	function(val) 
	 		self.settings.scenes.trade.visible = val
	 		self:UpdateScene("trade")
	 	end
	)

	LAM:AddHeader(menu, "BP_MENU_HEADER_LOGGING", "Logging")
	LAM:AddDropdown(menu, "BP_LOG_LEVEL", "Log Level", "", LOG_PREFIXES,
        function() 
        	return self.settings.logLevel 
        end, 
        function(val) 
        	self.settings.logLevel = val 
           	LOG_FACTORY:SetStrLevel(val)
        end
    )

end

function Backpack:UpdateGroups()
	Log:D("Updating groups ...");
	local bag = self.bags[1];
	local tocheck = bag.slots;
	for _,group in pairs(self.groups) do
		group.slots = {};
		assert(group.filter);
		local unmatched = {};
		for _, slot in pairs(tocheck) do
				--Log:D("Checking ".. (item.Name or "nil"))
			local item = slot.item;
				--Log:T("Applying filter: "..group.filter.name)
			if ( group.filter:Matches(slot) ) then
				--	Log:T("Filter matches");
				table.insert(group.slots, slot);
			else
				table.insert(unmatched, slot);
			end
			tocheck = unmatched;
		end

		group.visible = group.slots == 0;
		Log:D("Filter matched "..#group.slots.." slots(s).");
	end

	for _, group in pairs(self.groups) do
		if #group.slots == 0 then

		end
		group:Update();
	end
	
end

function Backpack:CreateBags() 
	Log:T("Creating bags ... ");
	self.bags= {};

	local bagCount = GetMaxBags();
	for bagId=1,1 do
		local bag = BackpackBag:New(bagId);
		table.insert(self.bags, bag);
	end
	for _, bag in ipairs(self.bags) do
		Log:D("Bag " .. bag.id .." contains " .. #bag.slots ..  " slots.");
	end
end


function Backpack:Search( exp ) 
	local matches = 0;
	local items = {};
	for i=1,self.Inventory.ItemCount do
		if(string.gfind(self.Inventory.Items[i].Name, exp)() ~= nil) then
			matches = matches+1;
			items[matches] = self.Inventory.Items[i];
		end
	end

	return matches, items;
end

BACKPACK = Backpack:New();




