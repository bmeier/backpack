
local Log = LOG_FACTORY:GetLog("BackpackGroup")

local BackpackGroupFragment = ZO_FadeSceneFragment:Subclass()

function BackpackGroupFragment:New(group)
	local fragment =  ZO_FadeSceneFragment.New(self, group.window.control);
	fragment:Initialize( group )
	return fragment;
end

function BackpackGroupFragment:Initialize( group )
	self.group = group;
	self.forceHidden =  false
end

function BackpackGroupFragment:Show()
	Log:T("Fragment Show()")
	if not self.forceHidden then
		ZO_FadeSceneFragment.Show(self)
	end
	self:OnShown()
end

function BackpackGroupFragment:Hide()
	Log:T("Fragment Hide()")
	if not self.forceHidden then
		ZO_FadeSceneFragment.Hide(self)
	end
	self:OnHidden()
end

function BackpackGroupFragment:Update()
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

BackpackGroup = ZO_Object:Subclass();
BackpackGroup.name = name
BackpackGroup.filter = filter

BackpackGroup.fragment = nil;

BackpackGroup.hidden = false;
BackpackGroup.settings = {};

function BackpackGroup:New( name, filter )
	local group = ZO_Object.New(self);
	group.control = nil;
	group.filter = filter
	group.name = name
	group.slots = {}
	group.bag = nil
	group:Initialize();
	return group;
end

function BackpackGroup:Initialize()
	local name = self.name.."Control"
	local settings = BACKPACK.settings.ui.groups[self.name]
	self.settings = settings[BACKPACK.currentBag]

	local window = BackpackGroupWindow:New( self )



	assert(window)
	self.window = window
	self.fragment = BackpackGroupFragment:New(self);
end

function BackpackGroup:Update()
	self.window:Update()
	self.fragment:Update()
end

function BackpackGroup:RemoveSlot( slot )
	local idx = nil
	for i,s in pairs(self.slots) do
		if(s == slot) then
			idx = i
		end
	end

	if idx then
		self.slots[idx].group = nil
		self.slots[idx].control.control:SetParent(nil)
		self.slots[idx].control.control:SetHidden(true)
		table.remove(self.slots, idx)
	end
end

function BackpackGroup:RemoveAll()
	Log:T("Removing all slots from group ...")

	for i,s in pairs(self.slots) do
		s.group = nil
		s.control.control:SetParent(nil)
		s.control.control:SetHidden(true)
		--s.control.control = nil
	end
	self.slots = {}
end

function BackpackGroup:AddSlot( slot )
	assert( slot )
	table.insert(self.slots, slot)
	slot.group = self
end


