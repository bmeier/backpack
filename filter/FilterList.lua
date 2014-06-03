local ff = backpack.filter.FILTER_FACTORY
local FilterList = ZO_Object:Subclass()

function FilterList:New( )
	local r = ZO_Object.New(self)
	r.description = "Filters items based on their type"
	r.name = "Combine Filters"
	r.type = ff.FILTER_TYPES.FilterList
	return r
end

local calling = false
function FilterList:Matches(slot, options)
	if not options then return false end

	if not options.filter then return false end
	if not options.op then return false end
	if calling == true then calling = false; return false end
	
	local matches = true
	if options.op == ff.BOOLEAN_OPS.OR  then
		matches = false
	end
	for _, filter in pairs(options.filter) do
		
		local data = BACKPACK.settings.filter[filter]
		if not data then return false end
		calling = true
		local filterMatches = ff:GetFilter(data.type):Matches(slot, data.options)
		calling = false
		if options.op == ff.BOOLEAN_OPS.OR  then
			if  filterMatches == true then
				return true
			end
		else
			if filterMatches == false then
				return false
			end
		end
	end
	return matches;
end

ff:RegisterFilter(FilterList:New())