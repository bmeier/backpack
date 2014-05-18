local ff = backpack.filter.FILTER_FACTORY
local ItemTypeFilter = Filter:Subclass()

function ItemTypeFilter:New( )
	local r = ZO_Object.New(self)
	r.description = "Filters items based on their type"
	r.name = "Item Type"
	r.type = ff.FILTER_TYPES.ItemType
	return r
end

function ItemTypeFilter:Matches(slot, options)
	if(not slot) then return false; end
	if(not slot.itemInfo) then return false; end
	return (slot.itemInfo.type == options.type);
end

ff:RegisterFilter(ItemTypeFilter:New())