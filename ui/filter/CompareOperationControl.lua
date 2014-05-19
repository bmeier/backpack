local CompareOperationControl = ZO_Object:Subclass()

function CompareOperationControl:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function CompareOperationControl:Initialize(control)
	assert(control)
	
	local comboboxCtrl = GetControl(control, "DropDown")
	assert(comboboxCtrl)
	
	local combobox = ZO_ComboBox:New(comboboxCtrl)
	local entries = {}
	for k,v in pairs(backpack.filter.CompareOperation) do
		local entry = combobox:CreateItemEntry(k, function() self.compare = v end)
		entries[v] = entry
		combobox:AddItem(entry)
	end
		
	self.combobox = combobox
	self.entries = entries
	
	self.control = control	
	self.compare = backpack.filter.CompareOperation.EQUAL
	assert(self.entries[self.compare])
	self.combobox:SelectItem(self.entries[self.compare])
end

function CompareOperationControl:SetCompareOperation( operation )
	local entry = self.entries[operation]
	assert(entry)
	if entry then
		self.combobox:SelectItem(entry)
	end
end

function CompareOperationControl:GetOperation()
	return self.compare
end

backpack.ui.filter.CompareOperationControl = CompareOperationControl