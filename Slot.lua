local Log = LOG_FACTORY:GetLog("BackpackSlot")

BackpackSlot = ZO_Object:Subclass();

BackpackSlot.idx = 0;
BackpackSlot.bag = nil;
BackpackSlot.itemInfo = nil;
BackpackSlot.control = nil;

function BackpackSlot:New( bag, idx )
	local slot =  ZO_Object.New(self);
	slot.bag = bag;
	slot.idx = idx;
	slot.itemInfo = BackpackSlot_GetItemInfo(bag.id, idx);
	slot:CreateControl();
	return slot;
end

function BackpackSlot:OnUpdate( newItem ) 
	self.itemInfo = BackpackSlot_GetItemInfo(self.bag.id, self.idx);
	self.control:Update();
end

function BackpackSlot:CreateControl()
	local name = "BackpackSlotControl_"..self.bag.id.."_"..self.idx;
	local control = BackpackSlotControl:New(self);
	assert(control);
	self.control = control;
end

 function BackpackSlot_GetItemInfo( bagId, slotIdx )
	local item = nil;

	local itemId = GetItemInstanceId(bagId, slotIdx);
		if(itemId)  then 
			item = {};
			item.id = itemId;
			item.bag = bagId;
			item.slot = slotIdx;
			item.count = GetItemTotalCount(bagId, slotIdx);
			item.name = GetItemName(bagId, slotIdx);
			item.link = GetItemLink(bagId, slotIdx, LINK_STYLE_DEFAULT);
			item.type = GetItemType(bagId, slotIdx);
			item.filter = GetItemFilterTypeInfo(bagId, slotIdx)
			item.texture, _, _, _, _ = GetItemLinkInfo(item.link);
			_, _, _, item.meetsUsageRequirement, _,_,_, item.quality = GetItemInfo(bagId, slotIdx);
			local usable, onlyFromActionSlot = IsItemUsable(bagId, slotIdx);
			item.usable = usable and not onlyFromActionSlot
			item.equipable = IsEquipable(bagId, slotIdx);
			item.enchantable = IsItemEnchantable(bagId, slotIdx);
		end
	return item;
end
