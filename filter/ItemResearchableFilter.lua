local Log = LOG_FACTORY:GetLog("ItemResearchableFilter")
local ff = backpack.filter.FILTER_FACTORY
local ItemResearchableFilter = ZO_Object:Subclass()
local libResearch = LibStub:GetLibrary("libResearch")

function ItemResearchableFilter:New( )
	local r = ZO_Object.New(self)
	r.description = ""
	r.name = "Researchable Items"
	r.type = ff.FILTER_TYPES.ItemResearchable
	return r
end

function ItemResearchableFilter:Matches(slot, options)
	if not slot then return false end
	if not slot.itemInfo then return false end


	local itemTypeFilter = ff:GetFilter(ff.FILTER_TYPES.FilterType)
	if not itemTypeFilter:Matches(slot, { type=ITEMFILTERTYPE_ARMOR } ) and not itemTypeFilter:Matches(slot, { type=ITEMFILTERTYPE_WEAPONS}) then
		return false
	end

	local isResearchable = false
	if(libResearch) then
		isResearchable = libResearch:IsItemResearchable(slot.bag.id, slot.idx)
	end

	if options.invert ~= nil and options.invert == true then
		isResearchable = not isResearchable
	end
	return isResearchable
end


ff:RegisterFilter(ItemResearchableFilter:New())
assert(ff:GetFilter(ff.FILTER_TYPES.ItemResearchable))
