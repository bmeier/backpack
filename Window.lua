local Log = LOG_FACTORY:GetLog("BackpackWindow")

BackpackWindow = ZO_CallbackObject:Subclass()
function BackpackWindow:New( name )
	local window = ZO_CallbackObject.New(self)
	window:InitializeWindow( name )
	return window;
end

function BackpackWindow:InitializeWindow( name )
	self.name = name
	self.control = CreateTopLevelWindow( name )
	self.settings =  BACKPACK.settings.ui.windows[name]
	assert(self.control)
	assert(self.settings)


	self.control:SetMovable(true)
	self.control:SetMouseEnabled(true)
	self.control:SetResizeHandleSize(MOUSE_CURSOR_RESIZE_NS)

	self.control:SetHandler('OnMouseDown', function() Log:T("OnMouseDown"); self:OnMouseDown() end)
	self.control:SetHandler('OnMouseUp', function() Log:T("OnMouseUp"); self:SaveSettings(); end);
	self.control:SetHandler('OnMoveStop', function() Log:T("OnMoveStop"); self:SaveSettings(); end)
	self.control:SetHandler('OnResizeStart', function() Log:T("OnResizeStart"); 
		self:OnResizeStart(self.control:GetWidth(), self.control:GetHeight()); 
	end)

	self.control:SetHandler('OnResizeStop', function() Log:T("OnResizeStop"); 
		self:OnResizeStop(self.control:GetWidth(), self.control:GetHeight()); 
	end)

	self.control.backdrop = CreateControl(name.."Backdrop", self.control, CT_BACKDROP)
	self.control.backdrop:SetAnchorFill(self.control)

	self:ApplySettings()
end

function BackpackWindow:OnMouseDown()

end

function BackpackWindow:OnResizeStart(width, height)

end

function BackpackWindow:OnResizeStop(width, height)
	Log:T("BackpackWindow:OnResize(width, height)")
	self:SaveSettings()
end

function BackpackWindow:DoLayout()
	Log:T("BackpackWindow:DoLayout()")
	self:SaveSettings()
end

function BackpackWindow:SetDimensions( width, height )
	self.settings.width = width or 0
	self.settings.height = heigth or 0

	self.control:SetDimension(width, height)
end

function BackpackWindow:ApplySettings()
	local settings = self.settings
	local control  = self.control
	assert(control)
	assert(settings)

	control:SetDimensions(settings.width, settings.height)
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settings.left, settings.top)
	
	--control.backdrop:SetCenterTexture(settings.backdrop.centerTexture)
	control.backdrop:SetCenterColor(unpack(settings.backdrop.centerColor))

	control.backdrop:SetEdgeTexture(settings.backdrop.edgeTexture, settings.backdrop.edgeWidth, settings.backdrop.edgeHeight)
	control.backdrop:SetEdgeColor(unpack(settings.backdrop.edgeColor))

	control.backdrop:ClearAnchors()
	control.backdrop:SetAnchor(TOPLEFT, control, TOPLEFT, -settings.insets.left, -settings.insets.top)
	control.backdrop:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, settings.insets.right, settings.insets.bottom)
	control:SetHitInsets(-settings.insets.left, -settings.insets.top, settings.insets.right, settings.insets.bottom )
end

function BackpackWindow:SaveSettings()
	local settings = self.settings
	local control  = self.control
	assert(control)
	assert(settings)
	settings.top = control:GetTop()
	settings.left = control:GetLeft()	
	settings.width = control:GetWidth()
	settings.height = control:GetHeight()
end

function BackpackWindow:Hide( )
	self.control:SetHidden(true)
end

function BackpackWindow:Show( )
	self.control:SetHidden(false)
end

function BackpackWindow:Toggle( )
	self.control:SetHidden(not self.control:IsHidden())
end

TestWindow = nil