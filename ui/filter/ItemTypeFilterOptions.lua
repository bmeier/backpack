local TEMPLATE = "BP_ItemTypeFilterOptions"
local CONTROL_NAME = "BP_ITEM_TYPE_FILTER_OPTIONS"

local ItemTypeOptions = ZO_Object:Subclass()
function ItemTypeOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function ItemTypeOptions:Initialize( )
	local control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot,TEMPLATE)
	assert(control)
	self.control = control

	
	local combobox = ZO_ComboBox:New(GetControl(control, "DropDown"))
	local entries = {}
	for i, type in pairs(backpack.Item.ItemType) do
		local entry = combobox:CreateItemEntry(i, function() self.type = type end)
		entries[type] = entry
		combobox:AddItem(entry)
	end
	self.entries = entries
	self.combobox = combobox
	self.combobox:SelectItem(entries[backpack.Item.ItemType.ITEMTYPE_ARMOR])
end
function ItemTypeOptions:SetOptions( options )
	local entry = self.entries[options.type]
	if entry then
		self.combobox:SelectItem(entry)
	end
end
function ItemTypeOptions:GetOptions()
	return {
		type = self.type,
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemType,  ItemTypeOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemType))