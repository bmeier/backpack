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

local operations = {
	[backpack.filter.CompareOperation.LESS_OR_EQUAL] = function(a, b) return a <= b end,
	[backpack.filter.CompareOperation.LESS] = function(a, b) return a < b end,
	[backpack.filter.CompareOperation.EQUAL] = function(a, b) return a == b end,
	[backpack.filter.CompareOperation.GREATER_OR_EQUAL] = function(a, b) return a >= b end,
	[backpack.filter.CompareOperation.GREATER] = function(a, b) return a > b end,
}

function QualityFilter:Matches(slot, options)
	
	if not slot then return false end
	if not slot.itemInfo then return false end
	local op = options.op
	if not op then 
		Log:W("Missing compare operation")
		op = backpack.filter.CompareOperation.EQUAL
	end
	
	
	return operations[op](slot.itemInfo.quality, options.quality)
end

ff:RegisterFilter(QualityFilter:New())