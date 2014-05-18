local Log = LOG_FACTORY:GetLog("backpack.ui.scene.Fragment");
local Fragment = ZO_FadeSceneFragment:Subclass()

function Fragment:New( control )
	local fragment = ZO_FadeSceneFragment.New(self, control)
	fragment.enabled = true
	return fragment
end

function Fragment:Show()
	if self.enabled == true then
		ZO_FadeSceneFragment.Show(self)
	end
	self:OnShown()
end


backpack.ui.scene.Fragment = Fragment