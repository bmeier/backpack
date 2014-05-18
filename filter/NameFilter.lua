local Log = LOG_FACTORY:GetLog("ItemNameFilter") 
local ff = backpack.filter.FILTER_FACTORY
local ItemNameFilter = Filter:Subclass()

function ItemNameFilter:New( )
	local r = Filter.New(self)
	r.description = "Filters items based on their names"
	r.name = "Item Name"
	r.type = ff.FILTER_TYPES.ItemName
	return r
end

function ItemNameFilter:Matches(slot, options)
	if not slot then return false end
	if not slot.itemInfo then return false end
	return string.find(zo_strlower(slot.itemInfo.name), zo_strlower(options.name)) ~= nil;
end

ff:RegisterFilter(ItemNameFilter:New())
