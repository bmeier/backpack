local Log = LOG_FACTORY:GetLog("Backpack")
local Backpack = ZO_Object:Subclass()
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
	self:LoadGroups();
	self:UpdateGroups();

	BACKPACK_SCENE = backpack.ui.scene.Scene:New();
	for i, group in pairs(self.groups) do
		local fragment = group.fragment

		if not group:IsEmpty() and not group:IsHidden() then
			group.fragment:AddToScene("backpack")

			for name, settings in pairs(self.settings.scenes) do
				if settings.visible then
					group.fragment:AddToScene(name)
				end
			end
		end
	end

	for name, settings in pairs(self.settings.scenes) do
		local scene = SCENE_MANAGER:GetScene(name)
		scene:RegisterCallback("StateChange",
		function(oldState, newState)
			if(newState == SCENE_SHOWING) and settings.visible == true then
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
	end

	self:ShowBag(self.bags[BAG_BACKPACK])

	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function(...) self:OnSlotUpdate( ... ); end)
	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_BOUGHT_BAG_SPACE, function(...)  self.bags[BAG_BACKPACK]:Update(); self:UpdateGroups() end)
	EVENT_MANAGER:RegisterForEvent(Backpack.ADDON_NAME, EVENT_INVENTORY_FULL_UPDATE, function(...) self.bags[BAG_BACKPACK]:Update(); self:UpdateGroups() end)

	Log:D("Backpack loaded.");
end

function Backpack:UpdateScene( name )
	local settings = self.settings.scenes[name]
	local scene = SCENE_MANAGER:GetScene( settings.name )

	if( scene) then
		if ( settings.visible  ) then
			for i, group in pairs(self.groups) do
				if not group:IsEmpty() and not group:IsHidden() then
					group.fragment:AddToScene(settings.name)
				end
			end
		else
			for i, group in pairs(self.groups) do
				group.fragment:RemoveFromScene(settings.name)
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

function Backpack:FilterSlot( bagId, slotIdx )
	local slot = self:GetSlot(bagId, slotIdx)
	local slotGroup = nil

	for i, group in pairs(self.groups) do
		local filterData = self.settings.filter[group.filter]
		local filter = backpack.filter.FILTER_FACTORY:GetFilter(filterData.type)
		if filter:Matches(slot, filterData.options) then
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
		local newGroup = self:FilterSlot(bagId, slotIdx)

		if  oldGroup and oldGroup == newGroup then
			oldGroup:Update()
		else
			if oldGroup  then
				oldGroup:RemoveSlot(slot)
				oldGroup:Update()
			end
			if newGroup then
				newGroup:AddSlot(slot)
				newGroup:Update()
			else
				slot.control.control:SetHidden(true)
			end
		end
	end
	BACKPACK_SCENE.emptySlotsLabel:SetText(bag.freeSlots.."/"..bag.numSlots)
end

function Backpack:LoadGroups()
	if (self.settings.firstRun) then

		self.settings.filter["Apparel"] = {
			name = "Apparel",
			type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,
			options = { type=ITEMFILTERTYPE_ARMOR }
		}
		self.settings.groups["Apparel"] = {
			name ="Apparel",
			filter = "Apparel",
			weight = 0,
			hidden = false,
		}

		self.settings.filter["Consumable"] = {
			name = "Consumable",
			type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,
			options = { type=ITEMFILTERTYPE_CONSUMABLE }
		}
		self.settings.groups["Consumable"] = {
			name ="Consumable",
			filter = "Consumable",
			weight = 0,
			hidden = false,
		}


		self.settings.filter["Weapons"] = {
			name = "Weapons",
			type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,
			options = { type=ITEMFILTERTYPE_WEAPONS }
		}
		self.settings.groups["Weapons"] = {
			name ="Weapons",
			filter = "Weapons",
			weight = 0,
			hidden = false,
		}

		self.settings.filter["Armor"] = {
			name = "Armor",
			type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,
			options = { type=ITEMFILTERTYPE_ARMOR }
		}
		self.settings.groups["Armor"] = {
			name ="Armor",
			filter = "Armor",
			weight = 0,
			hidden = false,
		}

		self.settings.filter["Crafting"] = {
			name = "Crafting",
			type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,
			options = { type=ITEMFILTERTYPE_CRAFTING }
		}
		self.settings.groups["Crafting"] = {
			name ="Crafting",
			filter = "Crafting",
			weight = 0,
			hidden = false,
		}

		self.settings.filter["Misc"] = {
			name = "Misc",
			type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,
			options = { type=ITEMFILTERTYPE_MISCELLANEOUS }
		}
		self.settings.groups["Misc"] = {
			name ="Misc",
			filter = "Misc",
			weight = 0,
			hidden = false,
		}

	end

	for k,v in pairs(self.settings.groups) do
		if not v.weight then
			Log:W("No weight assignend to group '", v.name, "'")
			v.weight = 0
		end
		if v.hidden == nil then
			v.hidden = false
		end
		local group = BackpackGroup:New(v.name, v.filter)
		table.insert(self.groups, group)
	end
end

function Backpack:UpdateGroups()
	Log:D("Updating groups ...");
	for j, bag in pairs(self.bags) do
		for i, slot in pairs(bag.slots) do
			slot.control.control:SetHidden(true)
		end
	end
	local bag = self.bags[self.currentBag];
	local tocheck = bag.slots;

	table.sort(self.groups,
	function(a, b)
		if not a then return false end
		if not b then return true end
		assert(a)
		assert(b)
		assert(a.name)
		assert(b.name)
		local weightA = BACKPACK.settings.groups[a.name].weight
		assert(weightA, "Group '"..a.name.."' has no weight assigned")
		local weightB = BACKPACK.settings.groups[b.name].weight
		assert(weightB, "Group '"..b.name.."' has no weight assigned")

		return weightA > weightB
	end
	)


	local unmatched = {}
	for _,group in pairs(self.groups) do
		repeat
			assert(group.filter);
			local filterData = self.settings.filter[group.filter]


			group:RemoveAll()
			unmatched = {}


			if filterData then
				local filter = backpack.filter.FILTER_FACTORY:GetFilter(filterData.type)
				assert(filter, "No filter for group ".. group.name)

				for _, slot in pairs(tocheck) do
					--Log:T("slot: ", slot.bag.id, ", ", slot.idx, ", ", slot.itemInfo)
					assert(slot)
					if ( filter:Matches(slot, filterData.options) ) then
						--Log:T(group.name, " filter matches!")
						group:AddSlot(slot)
					else
						table.insert(unmatched, slot);
					end
				end
			else
				Log:E("No filter assigned to group '", group.name, "'")
			end
			group.settings = self.settings.ui.groups[group.name][self.currentBag];
			group:Update();
			tocheck = unmatched;
		--Log:D(filterData.name .. " filter matched "..#group.slots.." slots(s).");
		until true
	end
	--	assert(#tocheck == 0)
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

function Backpack:ShowFilterSettings( filter )
	backpack.ui.filter.FILTER_OPTIONS_DIALOG:SetFilter( filter )
	backpack.ui.filter.FILTER_OPTIONS_DIALOG:Show()
end

function Backpack:CreateFilter( filter )
	self.settings.filter[filter.name] = filter

end

function Backpack:ShowGroupSettings()
	backpack.ui.group.GROUP_DIALOG:Show()
end

function Backpack:DeleteGroup( name )
	self.settings.groups[name] = nil
	local group, idx = self:GetGroup( name )
	if group then
		self.groups[idx] = nil

		local fragment = group.fragment

		if fragment then
			fragment:RemoveFromScenes()

			-- remove the group fragment from scenes
			for k,v in pairs(self.settings.scenes) do
				local scene = SCENE_MANAGER:GetScene(v.name)
				if scene.fragments[fragment] then
					scene.fragments[fragment] = nil
				end
			end

			if BACKPACK_SCENE.fragments[fragment] then
				BACKPACK_SCENE.fragments[fragment] = nil
			end


		end
		group.fragment = nil

		group.window = nil
		group = nil
	end
end



function Backpack:GetGroup( name )
	for k, v in pairs(self.groups) do
		if v.name == name then
			return v, k
		end
	end
end

function Backpack:AddGroup( group )
	assert(group.name)
	assert(group.filter)
	assert(group.weight)
	assert(group.hidden ~= nil)
	self.settings.groups[group.name] = group
	local group = BackpackGroup:New(group.name, group.filter)
	table.insert(self.groups, group)
	group.fragment:Update()
end

function Backpack:DeleteFilter( name )
	if self.settings.filter[name] then
		self.settings.filter[name] = nil
	end
end

BACKPACK = Backpack:New();




