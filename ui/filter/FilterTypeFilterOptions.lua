local TEMPLATE = "BP_FilterTypeFilterOptions"
local CONTROL_NAME = "BP_ITEM_FILTERTYPE_FILTER_OPTIONS"

local FilterTypeFilterOptions = ZO_Object:Subclass()
function FilterTypeFilterOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function FilterTypeFilterOptions:Initialize( )
	local control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot,TEMPLATE)
	assert(control)
	self.control = control

	local entries = {}	
	local combobox = ZO_ComboBox:New(GetControl(control, "DropDown"))
	for i, type in pairs(backpack.Item.FilterType) do
		local entry = combobox:CreateItemEntry(i, function() self.filterType = type end)
		entries[type] = entry
		combobox:AddItem(entry)
	end
	
	combobox:SelectItem(entries[backpack.Item.FilterType.ITEMFILTERTYPE_ALL])
	self.entries = entries
	self.combobox = combobox
end

function FilterTypeFilterOptions:GetOptions()
	return {
		type = self.filterType,
	}
end

function FilterTypeFilterOptions:SetOptions( options )
	local entry = self.entries[options.type]
	if entry then
		self.combobox:SelectItem(entry)
	end 
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType,  FilterTypeFilterOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType))