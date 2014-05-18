local CompareOperation = ZO_Object:Subclass()

function CompareOperation:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function CompareOperation:Initialize(control)
	assert(control)
	
	local comboboxCtrl = GetControl(control, "DropDown")
	assert(comboboxCtrl)
	
	local combobox = ZO_ComboBox:New(comboboxCtrl)
	local entries = {}
	for k,v in pairs(backpack.filter.CompareOperation) do
		local entry = combobox:CreateItemEntry(v, function() self.compare = k end)
		entries[k] = entry
		combobox:AddItem(entry)
	end
		
	self.combobox = combobox
	self.entries = entries
	
	self.control = control	
	self.compare = backpack.filter.CompareOperation.Equals
	self.combobox:SelectItem(self.entries[self.compare])
end

function CompareOperation:SetCompareOperation( operation )
	local entry = self.entries[operation]
	if entry then
		self.combobox:SelectItem(entry)
	end
end

function CompareOperation:GetOperation()
	return self.compare
end

backpack.ui.filter.CompareOperationControl = CompareOperation