
local Log = LOG_FACTORY:GetLog("BackpackGroup")

local BackpackGroupFragment = ZO_FadeSceneFragment:Subclass()
BackpackGroupFragment.group = nil;

function BackpackGroupFragment:New(group)
	local fragment =  ZO_FadeSceneFragment.New(self, group.control.control);
	fragment.group = group;
	return fragment;
end

function BackpackGroupFragment:Show()
	if #self.group.slots ~= 0 and (self.group.hidden == false) then
		ZO_FadeSceneFragment.Show(self)
	end
	self:OnShown();
end

BackpackGroup = ZO_Object:Subclass();
BackpackGroup.control = nil;
BackpackGroup.fragment = nil;
BackpackGroup.name = "";
BackpackGroup.slots = {};
BackpackGroup.filter = nil;
BackpackGroup.hidden = false;
BackpackGroup.settings = {};

function BackpackGroup:New( name, filter )
	local group = ZO_Object.New(self);
	group.name = name
	group.filter = filter
	group:Initialize();
	return group;
end

function BackpackGroup:Initialize() 
	local name = self.name.."Control"
	self.settings = BACKPACK.settings.ui.groups[name]
	self.control = BackpackGroupWindow:New(self);
	self.fragment = BackpackGroupFragment:New(self);
end

function BackpackGroup:Update() 
	self.control:Update()
end

