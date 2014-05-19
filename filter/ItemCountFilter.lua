local ff = backpack.filter.FILTER_FACTORY
local ItemCountFilter = ZO_Object:Subclass()

function ItemCountFilter:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function ItemCountFilter:Initialize(...)
	self.type = ff.FILTER_TYPES.ItemCount
	self.name = "Item Count"
	self.desciption = "Filter items by stack size"
end

local operations = {
	[backpack.filter.CompareOperation.LESS_OR_EQUAL] = function(a, b) return a <= b end,
	[backpack.filter.CompareOperation.LESS] = function(a, b) return a < b end,
	[backpack.filter.CompareOperation.EQUAL] = function(a, b) return a == b end,
	[backpack.filter.CompareOperation.GREATER_OR_EQUAL] = function(a, b) return a >= b end,
	[backpack.filter.CompareOperation.GREATER] = function(a, b) return a > b end,
}

function ItemCountFilter:Matches(slot, options)
	if not slot then return false end
	if not slot.itemInfo then return false end

	local op = options.op
	if not op then
		Log:W("Missing compare operation")
		op = backpack.filter.CompareOperation.EQUAL
	end

	if(options.total == true) then
		return operations[op](slot.itemInfo.total, options.count)
	else
		return operations[op](slot.itemInfo.count, options.count)
	end
end

ff:RegisterFilter(ItemCountFilter:New())