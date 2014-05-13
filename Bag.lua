local Log = LOG_FACTORY:GetLog("BackpackBag")

BackpackBag = ZO_Object:Subclass();

function BackpackBag:New( id, name )
	assert(type(id) == "number")

	local bag = ZO_Object.New(self);
	bag:Initialize( id, name )
	return bag;
end

function BackpackBag:Initialize( id, name )
	self.id = id;
	self.name = name
	self.numSlots = 0
	self.freeSlots = 0
	self.slots = {}
--	self.slots.controls = {}
	self.texture, _ = GetBagInfo(id)
	self.groups = {}
end

function BackpackBag:Update(  )
	assert(self.id)

	Log:T("Updating bag ", self.id)
	local _, newSlotCount = GetBagInfo(self.id);

	if self.numSlots < newSlotCount then
		for i=self.numSlots , newSlotCount-1 do
			local slot = BackpackSlot:New(self, i)
			self.slots[i] = slot
		end
		assert(#self.slots == newSlotCount-1, #self.slots..", "..newSlotCount)
		self.numSlots = newSlotCount
	elseif self.numSlots > newSlotCount then
		for i=newSlotCount,self.numSlots-1 do
			self.slots[i].bag = nil
			self.slots[i] = nil
		end
		assert(#self.slots == newSlotCount-1, #self.slots..", "..newSlotCount)
		self.numSlots = newSlotCount
	end

	self.freeSlots = 0
	for slotIdx=0, self.numSlots-1 do
		local slot = self.slots[slotIdx]
		assert(slot.bag.id == self.id)
		assert(slot.bag == self)
		slot:OnUpdate()
		assert(slot.bag == self)
		if not slot.itemInfo then
			self.freeSlots = self.freeSlots + 1
		end
	end
end

function BackpackBag:GetSlotCount()
	return self.numSlots
end

function BackpackBag:GetFreeSlotCount()
	return self.freeSlots
end

function BackpackBag:UpdateSlot( slotIdx )
	Log:T("BackpackBag:UpdateSlot( slotIdx )")

	assert(type(slotIdx) == "number")
	local slot = self.slots[slotIdx];

	local wasEmpty = slot:IsEmpty()
	assert(slot.bag == self)
	slot:OnUpdate();
	local isEmpty = slot:IsEmpty()

	if wasEmpty and not isEmpty then
		self.freeSlots = self.freeSlots - 1
	elseif not wasEmpty and isEmpty then
		self.freeSlots = self.freeSlots + 1
	end
end






