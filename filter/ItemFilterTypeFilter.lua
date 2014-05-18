local Log = LOG_FACTORY:GetLog("ItemFilterTypeFilter")

local ItemFilterTypeFilter = ZO_Object:Subclass()

function ItemFilterTypeFilter:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function ItemFilterTypeFilter:Initialize(...)
	self.type = backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType
	self.name = "Item Filter Type"
	self.description = "Filter items with the default TESO filters"
end

-- @param options 
function ItemFilterTypeFilter:Matches( slot, options )
	-- options A table with filter options. 
	-- {
	--  	type = ITEMFILTERTYPE_XXX
	-- } 
	
	assert(slot)
	assert(options)
	assert(options.type)
	
	if(not slot) then return false; end
	if(not slot.itemInfo) then return false; end

	return (slot.itemInfo.filter == options.type);
end

backpack.filter.FILTER_FACTORY:RegisterFilter(ItemFilterTypeFilter:New())