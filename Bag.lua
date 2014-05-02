local Log = LOG_FACTORY:GetLog("BackpackBag")

BackpackBag = ZO_Object:Subclass();
BackpackBag.id = nil;
BackpackBag.name = "";
BackpackBag.numSlots = 0;
BackpackBag.slots = {}


function BackpackBag:New( id )
	assert(type(id) == "number")

	local bag = ZO_Object.New(self);
	bag.id = id;
	_, bag.numSlots = GetBagInfo(bag.id);
	bag.slots = {};
	for slotIdx=1, bag.numSlots do
		local slot = BackpackSlot:New(bag, slotIdx)
		table.insert(bag.slots, slot);
	end


	return bag;
end


function BackpackBag:OnSlotUpdated( slotIdx )
	assert(type(slotIdx) == "number")
	Log:T("BackpackBag:OnSlotUpdated( slotIdx )")
	local slot = self.slots[slotIdx];
	slot:OnUpdate();
end






