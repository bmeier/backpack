local Log = LOG_FACTORY:GetLog("ItemCountFilterOptions")
local TEMPLATE = ""

local ItemCountFilterOptions = ZO_Object:Subclass()
function ItemCountFilterOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function ItemCountFilterOptions:Initialize( )
	local control = CreateControlFromVirtual("BP_ITEM_COUNT_FILTER_OPTIONS", GuiRoot, "BP_ItemCountFilterOptions")
	self.control = control
	self.textfield = GetControl(GetControl(control, "Count"), "Edit")
	assert(self.textfield)
	self.textfield:SetTextType(NUMERIC_UNSIGNED_INT)
	ZO_EditDefaultText_Initialize(self.textfield, "")

	local compareOpCtrl = GetControl(self.control, "CompareOperation")
	assert(compareOpCtrl)

	self.count = 0
	self.compareOp = backpack.ui.filter.CompareOperationControl:New(compareOpCtrl)
end

function ItemCountFilterOptions:SetOptions( options )
	self.count = options.count
	self.compareOp:SetCompareOperation(options.op)
	self.textfield:SetText(options.count)
end

function ItemCountFilterOptions:SetQuality( quality )
	self.combobox:SelectItem(self.entries[quality])
end

function ItemCountFilterOptions:GetOptions()
	local number = tonumber(self.textfield:GetText())
	if not number then
		Log:E("Illegal item Count. Setting item count to zero")
		number = 0
	elseif number < 0 then
		Log:E("Illegal item Count. Setting item count to zero")
		number = 0
	end


	return {
		total = false,
		count = number,
		op = self.compareOp:GetOperation()
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemCount,  ItemCountFilterOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemCount))