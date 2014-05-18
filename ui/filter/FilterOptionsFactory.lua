local Factory = ZO_Object:Subclass()

function Factory:New()
	local factory = ZO_Object.New(self)
	factory:Initialize()
	return factory
end

function Factory:Initialize()
	self.options = {}
end

function Factory:Register(filterType, filterOptions)
	assert(filterOptions.SetOptions, "Missing SetOptions for filter type "..filterType)
	assert(filterOptions.GetOptions, "Missing GetOptions for filter type "..filterType)
	
	self.options[filterType] = filterOptions
end

function Factory:GetOptions( filterType )
	return self.options[filterType]
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY = Factory:New()