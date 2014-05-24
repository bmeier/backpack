local Log = LOG_FACTORY:GetLog("backpack.filter.FilterFactory")
local FilterFactory = ZO_Object:Subclass()

FilterFactory.FILTER_TYPES = {
	Default = 0,
	Or = 1,
	And = 2,
	ItemType = 3,
	EmptySlot = 4,
	FilterType = 5,
	ItemName = 6,
	ItemQuality = 7,
	Durability = 8,
	ItemCount = 9,
	ItemResearchable = 10, 
	WeaponType = 11,
	ArmorType = 12
}

function FilterFactory:New()
	local factory = ZO_Object.New(self)
	factory.filter = {}
	return factory
end

function FilterFactory:RegisterFilter( filter )
	self.filter[filter.type] = filter
end


function FilterFactory:GetFilter( type )
	assert(type)
	return self.filter[type]
end

function FilterFactory:GetFilterTypes()
	local types = {}
	for type, func in pairs(self.filter)
	do
		table.insert(types, type)
	end
	return types
end

backpack.filter.FILTER_FACTORY = FilterFactory:New()