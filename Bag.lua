local Log = LOG_FACTORY:GetLog("BackpackBag")

BackpackBag = ZO_Object:Subclass();
BackpackBag.id = nil;
BackpackBag.name = "";
BackpackBag.numSlots = 0;
BackpackBag.slots = {}
BackpackBag.freeSlots = 0

function BackpackBag:New( id )
	assert(type(id) == "number")

	local bag = ZO_Object.New(self);
	bag.id = id;
	_, bag.numSlots = GetBagInfo(bag.id);
	bag.slots = {};
	for slotIdx=1, bag.numSlots do
		local slot = BackpackSlot:New(bag, slotIdx)
		table.insert(bag.slots, slot);
		if not slot.itemInfo then
			bag.freeSlots = bag.freeSlots + 1
		end
	end


	return bag;
end


function BackpackBag:OnSlotUpdated( slotIdx )
	assert(type(slotIdx) == "number")
	Log:T("BackpackBag:OnSlotUpdated( slotIdx )")
	
	
	local slot = self.slots[slotIdx];
	local wasEmpty = slot.itemInfo ~= nil
	
	slot:OnUpdate();
	
	local isEmpty = slot.itemInfo ~= nil
	
	if wasEmpty and not isEmpty then
		self.freeSlots = self.freeSlots - 1
	elseif not wasEmpty and isEmpty then
		self.freeSlots = self.freeSlots + 1
	end	
end






