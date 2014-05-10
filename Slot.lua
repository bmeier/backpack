local Log = LOG_FACTORY:GetLog("BackpackSlot")
local BackpackSlotControl = ZO_Object:Subclass();
BackpackSlotControl.control = nil
BackpackSlotControl.slot = nil;

function BackpackSlotControl:New( slot ) 
	assert(slot);
	local obj = ZO_Object.New(self);
	obj.slot = slot;
	obj:Initialize( );
	return obj;
end

function BackpackSlotControl:OnMouseEnter()
	if(self.slot.itemInfo) then
		assert(self.slot.itemInfo.link);
		ZO_PopupTooltip_SetLink(self.slot.itemInfo.link);
	else
		ZO_PopupTooltip_Hide();
	end
end


function BackpackSlotControl:OnMouseExit()
	ZO_PopupTooltip_Hide();
end
function BackpackSlotControl:OnClicked(control, button)
	if(button == 2) then
		self:ShowPopupMenu();
	end
end

function BackpackSlotControl:OnMouseDoubleClick(button)
	
	if(button == 1) then
		local bagId = self.slot.bag.id;
		local idx = self.slot.idx;
		if BACKPACK_SCENE.state == "shown" then
			
			if self.slot.itemInfo.usable then
				CallSecureProtected("UseItem",bagId, idx)
			elseif self.slot.itemInfo.equipable then
				EquipItem(bagId, idx)
			end

		elseif ZO_Store_IsShopping() then
			CallSecureProtected("PickupInventoryItem", bagId, idx)
			SetCursorItemSoundsEnabled(true)
			CallSecureProtected("PlaceInStoreWindow");
		elseif PLAYER_INVENTORY:IsBanking() then
        	CallSecureProtected("PickupInventoryItem", bagId, idx)
			SetCursorItemSoundsEnabled(true)
			local emptySlotIndex = FindFirstEmptySlotInBag(BAG_BANK)
    		if(emptySlotIndex ~= nil) then
        		CallSecureProtected("PlaceInInventory", BAG_BANK, emptySlotIndex)
    		end
    	elseif TRADE_WINDOW:IsTrading() then
			CallSecureProtected("PickupInventoryItem", bagId, idx)
			SetCursorItemSoundsEnabled(true)
			CallSecureProtected("PlaceInTradeWindow");
        elseif MAIL_SEND:GetState() == "shown" then
			CallSecureProtected("PickupInventoryItem", bagId, idx)
			SetCursorItemSoundsEnabled(true)
			CallSecureProtected("PlaceInAttachmentSlot");
		end
	end
end

function BackpackSlotControl:Initialize()
	local name = "BackpackSlotControl_"..self.slot.bag.id.."_"..self.slot.idx;
	local control = CreateControl(name, GuiRoot, CT_BUTTON);
	control:SetMouseEnabled(true);
	control:EnableMouseButton(2, true);
	control:SetHandler("OnClicked", function(control, button) self:OnClicked(control, button) end)
	control:SetHandler("OnMouseEnter", function(...)  self:OnMouseEnter(); end)
	control:SetHandler("OnMouseExit", function(...)  self:OnMouseExit(); end)
	control:SetHandler("OnMouseDoubleClick", function(control, button) self:OnMouseDoubleClick(button) end)

	control.background = CreateControl(name.."Background", control, CT_TEXTURE);
	control.background:SetAnchorFill(control);
	control.background:SetColor(0, 0, 0, 1);

	control.itemTexture = CreateControl(name.."Item", control, CT_TEXTURE);
	control.itemTexture:SetAnchorFill(control);
	control.itemTexture:SetHidden(true);

	control.label = CreateControl(name.."Label", control, CT_LABEL);
	control.label:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, -4, -4)
	control.label:SetFont("ZoFontGameMedium")
	--control.label:SetWidth(40);
	--control.label:SetHeight(20);
	
	control.border = CreateControl(name.."Border", control, CT_TEXTURE);
	control.border:SetAnchorFill(control);
	control.border:SetTexture("Backpack/itemborder.dds");
	control.border:SetDrawLayer(DL_OVERLAY);
	
	control:SetHidden(true);
	self.control = control;
	self:Update();
end


function BackpackSlotControl:Update()
	Log:T("Updating SlotControl ...");
	assert(self.slot);
	
	ClearMenu();

	local control = self.control;
	control:SetDimensions(BACKPACK.settings.ui.iconSize, BACKPACK.settings.ui.iconSize);
	
	local color = ZO_ColorDef:New(unpack(BACKPACK.settings.ui.emptyBorderColor))
	local item = self.slot.itemInfo;
	if(item) then
		color = GetItemQualityColor(item.quality);
		control.itemTexture:SetTexture(item.texture);
		control.itemTexture:SetHidden(false);
		
		control.label:SetText(""..item.count);
		if(item.count > 1) then
			control.label:SetHidden(false);
		else
			control.label:SetHidden(true);
		end

		local itemColor = {1, 1, 1, 1}
		if not item.meetsUsageRequirement then
			itemColor = {1, 0, 0, 1}
		-- else
		-- 	local playerLevel = GetUnitLevel("player")
		-- 	local itemLevel = GetItemLevel(self.slot.bag.id, self.slot.idx)

		-- 	assert(playerLevel)
		-- 	assert(itemLevel)
		-- 	if playerLevel < itemLevel then
		-- 		itemColor = {1, 0, 0, 1}
		-- 	end
		end
		control.itemTexture:SetColor(unpack(itemColor));
	else
		control.label:SetText("");
		control.label:SetHidden(true);
		control.itemTexture:SetHidden(true);
	end
	control.border:SetColor(color:UnpackRGB());
end

function BackpackSlotControl:ShowPopupMenu()
	ClearMenu();
	local item = self.slot.itemInfo;
	if(item) then
		local link = self.slot.itemInfo.link
		local count = self.slot.itemInfo.count
		local bagId = self.slot.bag.id
		local idx = self.slot.idx
		local empty = function() Log:E("Not implemented") end;
		-- 
		if (TRADING_HOUSE:IsAtTradingHouse())  then
			CallSecureProtected("PickupInventoryItem", bagId, idx)
			SetCursorItemSoundsEnabled(true)
			CallSecureProtected("PlaceInTransferWindow");
		elseif ZO_Store_IsShopping() then
			AddMenuItem("Sell", 
				function()
					CallSecureProtected("PickupInventoryItem", bagId, idx)
					SetCursorItemSoundsEnabled(true)
					CallSecureProtected("PlaceInStoreWindow");
					ClearMenu();
				end
			)
        elseif TRADE_WINDOW:IsTrading() then
        	AddMenuItem("Trade", 
        		function()
					CallSecureProtected("PickupInventoryItem", bagId, idx)
					SetCursorItemSoundsEnabled(true)
					CallSecureProtected("PlaceInTradeWindow");
					ClearMenu();
				end
			)
        elseif PLAYER_INVENTORY:IsBanking() then
        	AddMenuItem("Deposit", 
        		function()
					CallSecureProtected("PickupInventoryItem", bagId, idx)
					SetCursorItemSoundsEnabled(true)
					local emptySlotIndex = FindFirstEmptySlotInBag(BAG_BANK)
    				if(emptySlotIndex ~= nil) then
        				CallSecureProtected("PlaceInInventory", BAG_BANK, emptySlotIndex)
    				end
    				ClearMenu();
				end
			)
		elseif not MAIL_SEND:IsHidden() then
        	AddMenuItem("Send", 
        		function()
					CallSecureProtected("PickupInventoryItem", bagId, idx)
					SetCursorItemSoundsEnabled(true)
					CallSecureProtected("PlaceInAttachmentSlot");
					ClearMenu();
				end
			)
        end	

        if item.count > 1 then
        	AddMenuItem("Split", 
				function() 
					empty();
					ClearMenu();
				end
			)
        end

		if(item.usable) then
			AddMenuItem("Use", 
				function() 
					CallSecureProtected("UseItem",bagId, idx)
					ClearMenu();
				end
			)
		end

		if(item.equipable) then
			AddMenuItem("Equip", 
				function()
					EquipItem(bagId, idx)
					ClearMenu()
				end
			);
		end

		if(item.enchantable) then
			AddMenuItem("Enchant", 
				function() 
					ZO_Dialogs_ShowDialog("ENCHANTING", {bag = bagId, index = idx }) 
					ClearMenu()
				end
			);
		end

	    AddMenuItem("Destroy", function() BackpackSlotControl_DestroyItem(bagId, idx); ClearMenu();  end) -- Log:T(CallSecureProtected("PlaceInWorldLeftClick")) end);--ZO_Dialogs_ShowDialog("DESTROY_ITEM_PROMPT", nil, {mainTextParams = {link, count, GetString(SI_DESTROY_ITEM_CONFIRMATION)}}) end)
	    AddMenuItem("Link in Chat", empty);
	    AddMenuItem("Mark as Junk", empty);
	    AddMenuItem("Report Item", empty);
	    ShowMenu(self)
	end
end

function BackpackSlotControl_DestroyItem(bag, slot)
	CallSecureProtected("PickupInventoryItem", bag, slot)
	SetCursorItemSoundsEnabled(true)
	CallSecureProtected("PlaceInWorldLeftClick");
end

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
