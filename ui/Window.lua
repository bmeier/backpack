local Log = LOG_FACTORY:GetLog("backpack.ui.Window")

local function LoadSettings(control)
	local settings = BACKPACK.settings.ui.windows[control:GetName()]

	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settings.left, settings.top)
end

local function SaveSettings(control)
	local settings = BACKPACK.settings.ui.windows[control:GetName()]
	settings.left = control:GetLeft()
	settings.top  = control:GetTop()
end

local Window = ZO_Object:Subclass()

function Window:New( control )
	local obj = ZO_Object.New(self)
	obj:Initialize( control )
	return obj
end

function Window:Initialize( control )
	control.controller = self
	self.control = control

	if not BACKPACK then
		-- postpone loading settings
		EVENT_MANAGER:RegisterForEvent(control:GetName(), EVENT_PLAYER_ACTIVATED,
		function()
			self:LoadSettings()
			EVENT_MANAGER:UnregisterForEvent(control:GetName(), EVENT_PLAYER_ACTIVATED)
		end
		)
	else
		self:LoadSettings()
	end
end

function Window:LoadSettings()
	LoadSettings(self.control)
end

function Window:OnMoveStop()
	Log:T("Window:OnMoveStop()")
	SaveSettings(self.control)
end
backpack.ui.Window = Window