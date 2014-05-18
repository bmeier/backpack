local Log = LOG_FACTORY:GetLog("BackpackWindow")

BackpackWindow = ZO_CallbackObject:Subclass()
function BackpackWindow:New( name, settings )
	local window = ZO_CallbackObject.New(self)
	window:InitializeWindow( name, settings )
	return window;
end

function BackpackWindow:InitializeWindow( name, settings )
	self.name = name
	self.window = CreateTopLevelWindow( name )
	self.settings =  settings or BACKPACK.settings.ui.windows[name] 
	assert(self.window)
	assert(self.settings)


	self.window:SetMovable(true)
	self.window:SetMouseEnabled(true)

	self.window:SetHandler('OnMouseDown', function() Log:T("OnMouseDown"); self:OnMouseDown() end)
	self.window:SetHandler('OnMouseUp', function() Log:T("OnMouseUp"); self:SaveSettings(); end);
	self.window:SetHandler('OnMoveStop', function() Log:T("OnMoveStop"); self:SaveSettings(); end)
	self:ApplySettings()
end

function BackpackWindow:OnMouseDown()

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
	local window  = self.window
	assert(window)
	assert(settings)

	window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settings.left, settings.top)
end

function BackpackWindow:SaveSettings()
	local settings = self.settings
	local window  = self.window
	assert(window)
	assert(settings)
	settings.top = window:GetTop()
	settings.left = window:GetLeft()	
	settings.width = window:GetWidth()
	settings.height = window:GetHeight()
end

function BackpackWindow:Hide( )
	self.window:SetHidden(true)
end

function BackpackWindow:Show( )
	self.window:SetHidden(false)
end

function BackpackWindow:Toggle( )
	self.window:SetHidden(not self.control:IsHidden())
end