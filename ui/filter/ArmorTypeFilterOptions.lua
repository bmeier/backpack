local TEMPLATE = "BP_ArmorTypeFilterOptions"
local CONTROL_NAME = "BP_ARMOR_TYPE_FILTER_OPTIONS"
local Log = LOG_FACTORY:GetLog("backpack.ui.filter.ArmorTypeFilterOptions")
local ArmorTypeFilterOptions = ZO_Object:Subclass()
function ArmorTypeFilterOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

local ARMOR_TYPE_NAMES = {
	[ARMORTYPE_LIGHT] 	= GetString(BP_ARMORTYPE_LIGHT),
	[ARMORTYPE_MEDIUM]  = GetString(BP_ARMORTYPE_MEDIUM),
	[ARMORTYPE_HEAVY]   = GetString(BP_ARMORTYPE_HEAVY),
}
function ArmorTypeFilterOptions:Initialize( )
	local control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot,TEMPLATE)
	assert(control)
	self.control = control

	
	local combobox = ZO_ComboBox:New(GetControl(control, "DropDown"))
	local entries = {}
	for name, type in pairs(backpack.Item.ArmorType) do
		local entry = combobox:CreateItemEntry(ARMOR_TYPE_NAMES[type], function() Log:T("BP_"..name); self.type = type end)
		entries[type] = entry
		combobox:AddItem(entry)
	end
	self.entries = entries
	self.combobox = combobox
	self.combobox:SelectItem(entries[backpack.Item.ArmorType.ARMORTYPE_LIGHT])
end

function ArmorTypeFilterOptions:SetOptions( options )
	local entry = self.entries[options.type]
	if entry then
		self.combobox:SelectItem(entry)
	end
end

function ArmorTypeFilterOptions:GetOptions()
	return {
		type = self.type,
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ArmorType,  ArmorTypeFilterOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ArmorType))