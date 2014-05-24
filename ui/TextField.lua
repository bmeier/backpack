local TextField = ZO_Object:Subclass()

function TextField:New(control)
	local obj = ZO_Object.New(self)
	obj:Initialize(control)
	return obj
end

function TextField:Initialize(control)
	self.edit = GetControl(control, "Edit")
end

function TextField:SetText( text )
	self.edit:SetText( text )
end

function TextField:GetText( )
	return self.edit:GetText()
end

backpack.ui.TextField = TextField