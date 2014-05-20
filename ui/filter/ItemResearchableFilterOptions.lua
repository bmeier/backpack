local TEMPLATE = "BP_ItemResearchableFilterOptions"
local CONTROL_NAME = "BP_ITEM_RESEARCHABLE_FILTER_OPTIONS"

local ItemResearchableFilterOptions = ZO_Object:Subclass()
function ItemResearchableFilterOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function ItemResearchableFilterOptions:Initialize( )
	local control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot,TEMPLATE)
	assert(control)
	self.control = control

	
	local checkbox = GetControl(control, "Invert")
	assert(checkbox)
	ZO_CheckButton_SetToggleFunction(checkbox, function(control, isChecked) self.invert = isChecked end)
	self.checkbox = checkbox
	self.invert = false
end


function ItemResearchableFilterOptions:SetOptions( options )
	if options.invert ~= nil then
		self.invert = options.invert
		ZO_CheckButton_SetCheckState(self.checkbox, self.invert)
	end
end
function ItemResearchableFilterOptions:GetOptions()
	return {
		invert = self.invert,
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemResearchable,  ItemResearchableFilterOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.ItemResearchable))