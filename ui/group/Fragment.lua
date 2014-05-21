local Log = LOG_FACTORY:GetLog("backpack.ui.group.Fragment")
local Fragment = ZO_FadeSceneFragment:Subclass()

function Fragment:New(group)
	local fragment =  ZO_FadeSceneFragment.New(self, group.window.control);
	fragment:Initialize( group )
	return fragment;
end

function Fragment:Initialize( group )
	self.group = group;
	self.forceHidden =  false
end

function Fragment:Show()
	Log:T("Fragment Show()")
	if not self.forceHidden then
		ZO_FadeSceneFragment.Show(self)
	end
	self:OnShown()
end

function Fragment:Hide()
	Log:T("Fragment Hide()")
	if not self.forceHidden then
		ZO_FadeSceneFragment.Hide(self)
	end
	self:OnHidden()
end

function Fragment:Update()
	local hide = #self.group.slots == 0 or (BACKPACK.settings.ui.groups[self.group.name].hidden == true)
	if hide then
		if self:IsShowing() then
			self:Hide()
		end
	else
		-- show the fragment
		if self.forceHidden == true then -- fragment has been forced to stay hidden
			ZO_FadeSceneFragment.Show(self)
			self:OnShown()
		end
	end

	self.forceHidden = hide
end

backpack.ui.group.Fragment = Fragment