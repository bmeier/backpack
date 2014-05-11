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
	bag:OnUpdate()
	return bag;
end

function BackpackBag:OnUpdate(  )
	local _, newSlotCount = GetBagInfo(self.id);
	if self.numSlots < newSlotCount then
		for i=self.numSlots , newSlotCount-1 do
			table.insert(self.slots, BackpackSlot:New(self, i))
		end
		assert(#self.slots == newSlotCount)
		self.numSlots = newSlotCount
	elseif self.numSlots > newSlotCount then
		for i=newSlotCount,self.numSlots-1 do
			self.slots[i] = nil
		end
		assert(#self.slots == newSlotCount)
		self.numSlots = newSlotCount
	end
	
	self.freeSlots = 0
	for slotIdx=1, self.numSlots do
		local slot = self.slots[slotIdx]
		slot:OnUpdate()
		
		if not slot.itemInfo then
			self.freeSlots = self.freeSlots + 1
		end
	end
end

function BackpackBag:OnSlotUpdated( slotIdx )
	assert(type(slotIdx) == "number")
	Log:T("BackpackBag:OnSlotUpdated( slotIdx )")
	
	
	local slot = self.slots[slotIdx+1];
	local wasEmpty = slot.itemInfo == nil
	
	slot:OnUpdate();
	
	local isEmpty = slot.itemInfo == nil
	
	if wasEmpty and not isEmpty then
		self.freeSlots = self.freeSlots - 1
	elseif not wasEmpty and isEmpty then
		self.freeSlots = self.freeSlots + 1
	end	
end






