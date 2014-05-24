local TEMPLATE = "BP_WeaponTypeFilterOptions"
local CONTROL_NAME = "BP_WEAPON_TYPE_FILTER_OPTIONS"

local WeaponTypeFilterOptions = ZO_Object:Subclass()
function WeaponTypeFilterOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function WeaponTypeFilterOptions:Initialize( )
	local control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot,TEMPLATE)
	assert(control)
	self.control = control

	
	local combobox = ZO_ComboBox:New(GetControl(control, "DropDown"))
	local entries = {}
	for name, type in pairs(backpack.Item.WeaponType) do
		local entry = combobox:CreateItemEntry(name, function() self.type = type end)
		entries[type] = entry
		combobox:AddItem(entry)
	end
	self.entries = entries
	self.combobox = combobox
	self.combobox:SelectItem(entries[backpack.Item.WeaponType.WEAPONTYPE_AXE])
end
function WeaponTypeFilterOptions:SetOptions( options )
	local entry = self.entries[options.type]
	if entry then
		self.combobox:SelectItem(entry)
	end
end
function WeaponTypeFilterOptions:GetOptions()
	return {
		type = self.type,
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.WeaponType,  WeaponTypeFilterOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.WeaponType))