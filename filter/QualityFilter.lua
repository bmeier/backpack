local ff = backpack.filter.FILTER_FACTORY
local QualityFilter = ZO_Object:Subclass()

function QualityFilter:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function QualityFilter:Initialize(...)
	self.type = ff.FILTER_TYPES.ItemQuality
	self.name = "Item Quality"
	self.desciption = "Filter items by quality"
end

function QualityFilter:Matches(slot, options)
	
	if not slot then return false end
	if not slot.itemInfo then return false end
	
	return slot.itemInfo.quality == options.quality
end

ff:RegisterFilter(QualityFilter:New())