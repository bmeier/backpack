local Options = ZO_Object:Subclass()

function Options:New( filterType )
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function Options:Initialize(  filterType )
	self.name = ""
	self.type = filterType
end

backpack.ui.filter.DefaultFilterOptions = Options