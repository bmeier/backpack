local Log = LOG_FACTORY:GetLog("Backpack");

local Backpack = ZO_Object:Subclass();
Backpack.ADDON_NAME = "Backpack";

Backpack.bags = {};
Backpack.filter = {};
Backpack.groups = {}

Backpack.settings = nil;

function Backpack:New()
	local r = ZO_Object.New( self );
	return r;
end

function Backpack:OnLoad()
	ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_BACKPACK", "Toggle Backpack")

	local settings = BackpackSettings:New()
	settings:OnAddOnLoaded()
	settings:CreateSettingsMenu()


	self:CreateBags();
	self:CreateDefaultGroups();

	self:UpdateGroups();


	BACKPACK_SCENE = BackpackScene:New();
	for i, group in pairs(self.groups) do
		BACKPACK_SCENE:AddFragment(group.fragment)
		for name, scene in pairs(self.settings.scenes) do
			if scene.visible then
				SCENE_MANAGER:GetScene(name):AddFragment(group.fragment)
			end
		end
	end
	BACKPACK_SCENE.emptySlotsLabel:SetText(self.bags[1].freeSlots.."/"..self.bags[1].numSlots)
	SCENE_MANAGER:Add(BACKPACK_SCENE);

	if (self.settings.firstRun) then
		local initialPosition = 0
		for i, group in pairs(self.groups) do
			group.control.control:ClearAnchors();
			group.control.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, initialPosition, initialPosition)
			initialPosition = initialPosition + 30
			self.settings.firstRun = false
		end
	end


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



function Backpack:GetSlot ( bagId, slotIdx )
	return self.bags[bagId].slots[slotIdx+1];
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
	if(updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT) then
		Log:D("Slot update dropped: Wrong reason: "..updateReason)
		return
	end

	if(bagId == 1 and updateReason == INVENTORY_UPDATE_REASON_DEFAULT) then

		local bag = self.bags[bagId];
		Log:D("Updating slot " ..slotIdx)
		bag:OnSlotUpdated(slotIdx, isNewItem)

		local slot = self:GetSlot(bagId, slotIdx)
		local oldGroup = slot.group
		local newGroup = self:GetGroup(bagId, slotIdx)


		if oldGroup ~= newGroup then
			oldGroup:RemoveSlot(slot)
			newGroup:AddSlot(slot)
			oldGroup:Update()
			newGroup:Update()
		else
			oldGroup:Update()
		end

		BACKPACK_SCENE.emptySlotsLabel:SetText(bag.freeSlots.."/"..bag.numSlots)

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

function Backpack:UpdateGroups()
	Log:D("Updating groups ...");
	local bag = self.bags[1];

	local tocheck = bag.slots;

	for _,group in pairs(self.groups) do
		group:RemoveAllSlots()
		Log:T("checking "..#tocheck.." slots(s).");
		assert(group.filter);
		local unmatched = {};
		for _, slot in pairs(tocheck) do
			--Log:T("slot: ", slot.bag.id, ", ", slot.idx, ", ", slot.itemInfo)
			assert(slot)
			if ( group.filter:Matches(slot) ) then
				Log:T(group.name, " filter matches!")
				group:AddSlot(slot)
			else
				table.insert(unmatched, slot);
			end
		end
		tocheck = unmatched;
		--	group.visible = group.slots == 0;
		Log:D(group.name .. " filter matched "..#group.slots.." slots(s).");
	end

	assert(#tocheck == 0)

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




