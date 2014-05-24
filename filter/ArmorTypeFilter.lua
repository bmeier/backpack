local ff = backpack.filter.FILTER_FACTORY
local ArmorTypeFilter = ZO_Object:Subclass()

function ArmorTypeFilter:New( )
	local r = ZO_Object.New(self)
	r.name = "Armor Type"
	r.type = ff.FILTER_TYPES.ArmorType
	return r
end

function ArmorTypeFilter:Matches(slot, options)
	if(not slot) then return false; end
	if(not slot.itemInfo) then return false; end
	return (GetItemArmorType(slot.itemInfo.link) == options.type);
end

ff:RegisterFilter(ArmorTypeFilter:New())