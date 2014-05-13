local Log = LOG_FACTORY:GetLog("Backpack");

local Backpack = ZO_Object:Subclass();


function Backpack:New()
	local backpack = ZO_Object.New( self );
	backpack:Initialize()
	return backpack;
end

function Backpack:Initialize()
	self.currentBag = BAG_BACKPACK
	self.bags = {};
	self.filter = {};
	self.groups = {}
	self.scene = nil
	self.ADDON_NAME = "Backpack";
	self.savedVars = nil;
	self.settings = nil;
	self.settingsObj = nil
end

function Backpack:OnLoad()
	ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_BACKPACK", "Toggle Backpack")

	local settings = BackpackSettings:New()
	settings:OnAddOnLoaded()
	settings:CreateSettingsMenu()
	self.settingsObj = settings


	self:CreateBags();
	self:CreateDefaultGroups();
	self:UpdateGroups();

	BACKPACK_SCENE = BackpackScene:New();
	for i, group in pairs(self.groups) do
		BACKPACK_SCENE:AddFragment(group.fragment)
		for name, settings in pairs(self.settings.scenes) do
			if settings.visible then
				local scene = SCENE_MANAGER:GetScene(name)
				scene:AddFragment(group.fragment)
			end
		end
	end
	
	for name, settings in pairs(self.settings.scenes) do
			local scene = SCENE_MANAGER:GetScene(name)
			scene:RegisterCallback("StateChange", 
			function(oldState, newState)
				if(newState == SCENE_SHOWING) then
					self:ShowBag(self.bags[BAG_BACKPACK])
				end
			end)
	end
	SCENE_MANAGER:Add(BACKPACK_SCENE);

	if (self.settings.firstRun) then
		local initialPosition = 50
		for i, group in pairs(self.groups) do
			group.window.control:ClearAnchors();
			group.window.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, initialPosition, initialPosition)
			initialPosition = initialPosition + 30
			self.settings.firstRun = false
		end
		
		-- omfg 
		self.settings.ui.groups["Empty"].hidden = true
		self.groups[8].fragment.forceHidden = true
	end
	
	self:ShowBag(self.bags[BAG_BACKPACK])
	
	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnSlotUpdate( ... ); end)
	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_BOUGHT_BAG_SPACE, function(...)  self.bags[1]:OnUpdate(); self:UpdateGroups() end)
	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_FULL_UPDATE, function(...) self.bags[1]:OnUpdate(); self:UpdateGroups() end)
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

function Backpack:ShowBag( bag )
	assert(bag)

	if bag.id ~= self.currentBag then
		self.currentBag = bag.id
		self:UpdateGroups()
		BACKPACK_SCENE:Update( bag )
	end


end

function Backpack:GetSlot ( bagId, slotIdx )
	return self.bags[bagId].slots[slotIdx];
end

function Backpack:GetGroup( bagId, slotIdx )
	local slot = self:GetSlot(bagId, slotIdx)
	local slotGroup = nil

	for i, group in pairs(self.groups) do
		if group.filter:Matches(slot) then
			slotGroup = group
			break
		end
	end

	return slotGroup
end

function Backpack:OnSlotUpdate( eventid,  bagId, slotIdx, isNewItem, itemSoundCategory, updateReason )
	Log:T("OnSlotUpdate: bagid: ", bagId, ", slotIdx: ", slotIdx, ", reason: ", updateReason)
	if updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT
	then
		Log:D("Slot update dropped: Wrong reason: ", updateReason)
		return
	end

	local bag = self.bags[bagId];
	if not bag
	then
		Log:D("Slot update dropped: Wrong bag: ", bagId)
		return
	end

	Log:D("Updating bag: ", bagId, ", slot: ", slotIdx)
	bag:UpdateSlot(slotIdx, isNewItem)

	if(bag.id == self.currentBag) then
		local slot = self:GetSlot(bagId, slotIdx)
		local oldGroup = slot.group
		local newGroup = self:GetGroup(bagId, slotIdx)

		if  (oldGroup ~= newGroup) then
			oldGroup:RemoveSlot(slot)
			newGroup:AddSlot(slot)
			oldGroup:Update()
			newGroup:Update()
		else
			oldGroup:Update()
		end
	end
	BACKPACK_SCENE.emptySlotsLabel:SetText(bag.freeSlots.."/"..bag.numSlots)
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
	table.insert(self.groups, group)

	group =	BackpackGroup:New("Apparel", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_ARMOR))
	table.insert(self.groups, group)

	group = BackpackGroup:New("Consumable", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_CONSUMABLE))
	table.insert(self.groups, group)


	group = BackpackGroup:New("Crafting", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_CRAFTING))
	table.insert(self.groups, group)

	group = BackpackGroup:New("Misc", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_MISCELLANEOUS))
	table.insert(self.groups, group)

	group = BackpackGroup:New("Quest", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_QUEST))
	table.insert(self.groups, group)

	group = BackpackGroup:New("Junk", CreateFilter(FILTER_TYPES.FilterType, ITEMFILTERTYPE_JUNK))
	table.insert(self.groups, group)

	group = BackpackGroup:New("Empty", emptySlots)
	table.insert(self.groups, group)

	group = BackpackGroup:New("Lost and Found", defaultFilter)
	table.insert(self.groups, group)
end

function Backpack:UpdateGroups()
	Log:D("Updating groups ...");
	local bag = self.bags[self.currentBag];
	local tocheck = bag.slots;
	for _,group in pairs(self.groups) do
		group:RemoveAll()
		Log:T("checking "..#tocheck.." slots(s).");
		assert(group.filter);
		local unmatched = {};
		for _, slot in pairs(tocheck) do
			--Log:T("slot: ", slot.bag.id, ", ", slot.idx, ", ", slot.itemInfo)
			assert(slot)
			if ( group.filter:Matches(slot) ) then
				--Log:T(group.name, " filter matches!")
				group:AddSlot(slot)
			else
				table.insert(unmatched, slot);
			end
		end
		group.settings = self.settings.ui.groups[group.name][self.currentBag];
		group:Update();
		tocheck = unmatched;
		Log:D(group.name .. " filter matched "..#group.slots.." slots(s).");
	end
	assert(#tocheck == 0)
end

function Backpack:CreateBags()
	Log:T("Creating bags ... ");
	self.bags= {};
	self.bags[BAG_BANK] = BackpackBag:New(BAG_BANK, "Bank")
	self.bags[BAG_BANK]:Update()

	self.bags[BAG_BACKPACK] = BackpackBag:New(BAG_BACKPACK, "Inventory")
	self.bags[BAG_BACKPACK]:Update()

	self.currentBag = BAG_BACKPACK
end

BACKPACK = Backpack:New();




