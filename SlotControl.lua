local Log = LOG_FACTORY:GetLog("Backpack")

local function BackpackSlot_MailItem(bagId, idx)
	CallSecureProtected("PickupInventoryItem", bagId, idx)
	SetCursorItemSoundsEnabled(true)
	CallSecureProtected("PlaceInAttachmentSlot");
	ClearCursor()
end

local function BackpackSlot_TradeItem(bagId, idx)
	CallSecureProtected("PickupInventoryItem", bagId, idx)
	SetCursorItemSoundsEnabled(true)
	CallSecureProtected("PlaceInTradeWindow");
	ClearCursor()
end

local function BackpackSlot_SellItem(bagId, idx)
	CallSecureProtected("PickupInventoryItem", bagId, idx)
	SetCursorItemSoundsEnabled(true)
	CallSecureProtected("PlaceInStoreWindow");
	ClearCursor()
end

local function BackpackSlot_DepositItem(bagId, idx)
	local numBankSlots = BACKPACK.bags[BAG_BANK].numSlots

	local emptySlotIndex = nil
	local bagItemId = GetItemInstanceId(bagId, idx)
	local bagStackSize, _ = GetSlotStackSize(bagId, idx)

	for i=0,numBankSlots-1 do
		local bankItemId = GetItemInstanceId(BAG_BANK, i)
		if(bagItemId == bankItemId) then
			local bankStackSize, maxStackSize = GetSlotStackSize(BAG_BANK, i)
			if (bankStackSize + bagStackSize) < maxStackSize then
				emptySlotIndex = i
				break
			end
		end
	end

	if emptySlotIndex == nil then
		Log:T("No suitable slots found, using first free bank slot")
		emptySlotIndex =  FindFirstEmptySlotInBag(BAG_BANK)
	end

	--	Log:T("Empty slot: ", emptySlotIndex)

	if(emptySlotIndex ~= nil) then
		Log:D("Depositing item, slot: ", emptySlotIndex)
		SetCursorItemSoundsEnabled(true)
		CallSecureProtected("PickupInventoryItem", bagId, idx)
		CallSecureProtected("PlaceInInventory", BAG_BANK, emptySlotIndex)
		SetCursorItemSoundsEnabled(false)
		ClearCursor()
	else
	--bank full
	end

end

BackpackSlotControl = ZO_Object:Subclass();
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
	Log:T("bag: ", self.slot.bag.id, ", slot:", self.slot.idx)
	if(self.slot.itemInfo) then
		assert(self.slot.itemInfo.link);

		InitializeTooltip(ItemTooltip)
		ItemTooltip:SetBagItem(self.slot.bag.id, self.slot.idx)

		if(self.slot.itemInfo.equipable == true) then
			ItemTooltip:ShowComparativeTooltips()
			ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip1)
			ZO_PlayShowAnimationOnComparisonTooltip(ComparativeTooltip2)
			ZO_Tooltips_SetupDynamicTooltipAnchors(ItemTooltip, self.control, ComparativeTooltip1, ComparativeTooltip2)
		else
			ZO_Tooltips_SetupDynamicTooltipAnchors(ItemTooltip, self.control)
		end
	else
		ItemTooltip:SetHidden(true)
	end
end


function BackpackSlotControl:OnMouseExit()
	if not self.slot:IsEmpty() then
		if(self.slot.itemInfo.equipable) then
			ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip1)
			ZO_PlayHideAnimationOnComparisonTooltip(ComparativeTooltip2)
		end
	end
	ClearTooltip(ItemTooltip)
end
function BackpackSlotControl:OnClicked(control, button)
	if(button == 2) then
		self:ShowPopupMenu();
	end
end

function BackpackSlotControl:OnMouseDoubleClick(button)

	if(button == 1 and self.slot.itemInfo) then
		local bagId = self.slot.bag.id;
		local idx = self.slot.idx;
		if BACKPACK_SCENE.state == "shown" then
			if self.slot.itemInfo.usable then
				CallSecureProtected("UseItem",bagId, idx)
			elseif self.slot.itemInfo.equipable then
				EquipItem(bagId, idx)
			end
			ClearCursor()
		elseif ZO_Store_IsShopping() then
			BackpackSlot_SellItem(bagId,idx)
		elseif PLAYER_INVENTORY:IsBanking() then
			BackpackSlot_DepositItem(bagId, idx)
		elseif TRADE_WINDOW:IsTrading() then
			BackpackSlot_TradeItem(bagId,idx)
		elseif MAIL_SEND:GetState() == "shown" then
			BackpackSlot_MailItem(bagId,idx)
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
	control:SetHandler("OnDragStart",
	function()
		if self.slot.itemInfo then
			CallSecureProtected("PickupInventoryItem", self.slot.bag.id, self.slot.idx)
		end
	end
	)

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
	--	Log:T("Updating SlotControl ...");
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
		end
		control.itemTexture:SetColor(unpack(itemColor));
	else
		control.label:SetText("");
		control.label:SetHidden(true);
		control.itemTexture:SetHidden(true);
	end
	
	if(self.slot.bag.id == BAG_BANK) then
		control.itemTexture:SetDesaturation(1)
	else
		control.itemTexture:SetDesaturation(0)
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

		if bagId == BAG_BACKPACK then
			if (TRADING_HOUSE:IsAtTradingHouse())  then
				AddMenuItem("Sell",
				function()
					CallSecureProtected("PickupInventoryItem", bagId, idx)
					SetCursorItemSoundsEnabled(true)
					CallSecureProtected("PlaceInTransferWindow");

					ClearCursor()
					ClearMenu()
				end)
			elseif ZO_Store_IsShopping() then
				AddMenuItem("Sell",
				function()
					BackpackSlot_SellItem(bagId,idx)
					ClearMenu()
				end
				)
			elseif TRADE_WINDOW:IsTrading() then
				AddMenuItem("Trade",
				function()
					BackpackSlot_TradeItem(bagId,idx)
					ClearMenu()
				end
				)
			elseif PLAYER_INVENTORY:IsBanking() then
				AddMenuItem("Deposit",
				function()
					BackpackSlot_DepositItem(bagId, idx)
					ClearMenu()
				end
				)
			elseif not MAIL_SEND:IsHidden() then
				AddMenuItem("Send",
				function()
					BackpackSlot_MailItem(bagId,idx)
					ClearMenu()
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
		end
		AddMenuItem("Link in Chat", function() ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, item.linkBrackets)) end);
		AddMenuItem("Mark as Junk", function()
			SetItemIsJunk(bagId, idx, true)
			PlaySound(SOUNDS.INVENTORY_ITEM_JUNKED)
		end);
		AddMenuItem("Report Item", function() ZO_FEEDBACK:OpenBrowserByType(BROWSER_TYPE_USER_ITEM_BUG, item.link) end);
		ShowMenu(self)
	end
end

function BackpackSlotControl_DestroyItem(bag, slot)
	CallSecureProtected("PickupInventoryItem", bag, slot)
	SetCursorItemSoundsEnabled(true)
	CallSecureProtected("PlaceInWorldLeftClick");
end
