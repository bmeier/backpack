
local Log = LOG_FACTORY:GetLog("BackpackGroup")

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
	group.data = BACKPACK.settings.groups[name]
	group:Initialize();
	return group;
end

function BackpackGroup:Initialize()
	local name = self.name.."Control"
	local settings = BACKPACK.settings.ui.groups[self.name]
	self.settings = settings[BACKPACK.currentBag]

	local window = backpack.ui.group.GroupWindow:New( self )



	assert(window)
	self.window = window
	self.fragment = backpack.ui.group.GroupFragment:New(self);
end

function BackpackGroup:Update()
	Log:D("Updating group ", self.name)
	local settings = BACKPACK.settings.ui.groups[self.name]
	self.settings = settings[BACKPACK.currentBag]
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
		table.remove(self.slots, idx)
	end
end

function BackpackGroup:RemoveAll()
	Log:T("Removing all slots from group ...")

	for i,s in pairs(self.slots) do
		s.group = nil
	end
	self.slots = {}
end

function BackpackGroup:AddSlot( slot )
	assert( slot )
	table.insert(self.slots, slot)
	slot.group = self

	local hidden = not self.fragment.control:IsShowing()
	slot.control.control:SetHidden(hidden)
end

function BackpackGroup:AddToScene( sceneName )
	local scene = SCENE_MANAGER:GetScene(sceneName)
	if scene then
		if not scene.fragments[self.fragment] then
			scene:AddFragment(self.fragment)
		end
	end
end

function BackpackGroup:RemoveFromScene ( sceneName )
	local scene = SCENE_MANAGER:GetScene( sceneName )
	if scene then
		-- not a good idea
		scene.fragments[self.fragment] = nil
	end
end

function BackpackGroup:IsEmpty()
	return #self.slots == 0
end

function BackpackGroup:IsHidden()
	return self.data.hidden == true
end

function BackpackGroup:SetHidden( hidden )
	self.data.hidden = hidden
	self.fragment:Update()
end

