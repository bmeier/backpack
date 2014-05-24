local ff = backpack.filter.FILTER_FACTORY
local ItemWeaponTypeFilter = ZO_Object:Subclass()

function ItemWeaponTypeFilter:New( )
	local r = ZO_Object.New(self)
	r.description = "Filters items based on their type"
	r.name = "Weapon Type"
	r.type = ff.FILTER_TYPES.WeaponType
	return r
end

function ItemWeaponTypeFilter:Matches(slot, options)
	if(not slot) then return false; end
	if(not slot.itemInfo) then return false; end
	return (GetItemWeaponType(slot.itemInfo.link) == options.type);
end

ff:RegisterFilter(ItemWeaponTypeFilter:New())