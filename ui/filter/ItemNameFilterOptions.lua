local ItemNameFilterOptions = ZO_Object:Subclass()
local TEMPLATE = ""

function ItemNameFilterOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function ItemNameFilterOptions:Initialize()
	local control = CreateControlFromVirtual("BP_ITEM_NAME_FILTER_OPTIONS", GuiRoot, "BP_ItemNameFilterOptions")
	local textfield = GetControl(control, "TextField")
	self.textfield = GetControl(textfield, "Edit")
	self.control = control	
end

function ItemNameFilterOptions:SetOptions( options )
	self.textfield:SetText(options.name)
end

function ItemNameFilterOptions:GetOptions()
	return { name = self.textfield:GetText() }
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemName, ItemNameFilterOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemName))