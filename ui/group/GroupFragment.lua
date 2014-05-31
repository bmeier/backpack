local Log = LOG_FACTORY:GetLog("backpack.ui.group.Fragment")

local function RemoveFromScenes( fragment )
	SCENE_MANAGER:RemoveFragment(fragment.control)
	for _, name in pairs(fragment.scenes) do
		Log:D("Removing fragment ", fragment.group.name , " from scene ", name)
		fragment:RemoveFromScene(name)

	end
end

local function AddToScenes( fragment )
	fragment:AddToScene("backpack")
	for _, data in pairs(BACKPACK.settings.scenes) do
		Log:D("Adding fragment ", fragment.group.name , " to scene ", data.name)
		fragment:AddToScene(data.name)
	end
end


local Fragment = ZO_Object:Subclass()
function Fragment:New(group)
	local fragment = ZO_Object.New(self) -- ZO_FadeSceneFragment.New(self, group.window.control);
	fragment:Initialize( group )
	return fragment;
end

local nextId = 1;
function Fragment:Initialize( group )
	self.group = group;
	self.scenes = {}
	self.control =  ZO_FadeSceneFragment:New(group.window.control);
end

function Fragment:AddToScene ( sceneName )
	local scene = SCENE_MANAGER:GetScene(sceneName)
	if scene and not scene.fragments[self.control] then
		scene:AddFragment(self.control)
		table.insert(self.scenes, sceneName)
	else
		Log:E("Error: Could not find scene ", sceneName)
	end
end


function Fragment:RemoveFromScene ( sceneName )
	local scene = SCENE_MANAGER:GetScene(sceneName)
	if( scene ) then
		--this may not be working for all scenes
		scene:RemoveFragment(self.control)
	else
		Log:E("Failed to remove fragment from scene '", sceneName, "'")
	end
end


function Fragment:Update()
	Log:T("GroupFragment:Update()")
	local hide = self.group:IsEmpty() or self.group:IsHidden()
	if hide then
		RemoveFromScenes(self)
	else
		AddToScenes(self)
	end
end

backpack.ui.group.GroupFragment = Fragment