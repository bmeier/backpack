local TEMPLATE = ""

local ItemQualityOptions = ZO_Object:Subclass()
function ItemQualityOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end


local QUALITY_NAMES = {
	[ITEM_QUALITY_TRASH]		= 	GetString(BP_ITEM_QUALITY_TRASH),
	[ITEM_QUALITY_NORMAL]		=	GetString(BP_ITEM_QUALITY_NORMAL),
	[ITEM_QUALITY_MAGIC]  		=	GetString(BP_ITEM_QUALITY_MAGIC),
	[ITEM_QUALITY_ARCANE] 		= 	GetString(BP_ITEM_QUALITY_ARCANE),
	[ITEM_QUALITY_ARTIFACT]	 	=	GetString(BP_ITEM_QUALITY_ARTIFACT),
	[ITEM_QUALITY_LEGENDARY]	= 	GetString(BP_ITEM_QUALITY_LEGENDARY),
}

function ItemQualityOptions:Initialize( )
	self.itemQuality = backpack.Item.Quality.ITEM_QUALITY_MAGIC
	local control = CreateControlFromVirtual("BP_ITEM_QUALITY_FILTER_OPTIONS", GuiRoot, "BP_ItemQualityFilterOptions")
	local combobox = ZO_ComboBox:New(GetControl(control, "DropDown"))

	self.entries = {}
	combobox:SetSortOrder(ZO_SORT_ORDER_UP, ZO_SORT_BY_NAME_NUMERIC)
	for name, quality in pairs(backpack.Item.Quality) do
		local color = GetItemQualityColor(quality);
		local entry = combobox:CreateItemEntry("|c"..color:ToHex()..QUALITY_NAMES[quality].."|r", function() self.quality = quality end)
		combobox:AddItem(entry)
		self.entries[quality] = entry
	end
	combobox:SelectItem(self.entries[backpack.Item.Quality.ITEM_QUALITY_NORMAL])
	self.control = control
	self.combobox = combobox

	local compareOpCtrl = GetControl(self.control, "CompareOperation")
	assert(compareOpCtrl)

	self.compareOp = backpack.ui.filter.CompareOperationControl:New(compareOpCtrl)
end

function ItemQualityOptions:SetOptions( options )
	self.quality = options.quality
	self.combobox:SelectItem(self.entries[self.quality])
	self.compareOp:SetCompareOperation(options.op)
end

function ItemQualityOptions:SetQuality( quality )
	self.combobox:SelectItem(self.entries[quality])
end

function ItemQualityOptions:GetOptions()
	return {
		quality = self.quality,
		op = self.compareOp:GetOperation()
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemQuality,  ItemQualityOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemQuality))