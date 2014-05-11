local Log = LOG_FACTORY:GetLog("BackpackScene");
BackpackScene = ZO_Scene:Subclass();


BackpackScene.emptySlotsLabel = nil
BackpackScene.backpack = nil;
BackpackScene.searchBox = nil;
BackpackScene.tooltip = nil;
BackpackScene.keybindStrip = {
	{
		alignment = KEYBIND_STRIP_ALIGN_CENTER,
		name = GetString(SI_QUEST_JOURNAL_CYCLE_FOCUSED_QUEST),
		keybind = "UI_SHORTCUT_CYCLE_FOCUSED_QUEST",
		callback = function()
			local IGNORE_SCENE_RESTRICTION = true
			QUEST_TRACKER:AssistNext(IGNORE_SCENE_RESTRICTION)
		end
	},
}

function BackpackScene:New( )
	local scene = ZO_Scene.New(self, "backpack", SCENE_MANAGER);
	scene:RegisterCallback("StateChange",  function(oldValue, newValue) self:OnStateChange(oldValue, newValue) end)
	
	scene:AddFragmentGroup(FRAGMENT_GROUP.UI_WINDOW)
	scene:AddFragment(KEYBIND_STRIP_FRAGMENT);
	scene:AddFragment(TOP_BAR_FRAGMENT)
	
	--scene.searchBox = BackpackSearchbox:New();
	--scene:AddFragment(scene.searchBox.fragment);
	
	local labelWindow = CreateTopLevelWindow("BackpackFreeSlotsWindow")
	self.emptySlotsLabel = CreateControl("BackpackFreeSlotsLabel", labelWindow, CT_LABEL)
	self.emptySlotsLabel:SetFont("EsoUi/Common/Fonts/Univers67.otf|64|soft-shadow-thick")
	self.emptySlotsLabel:SetAnchor(BOTTOMRIGHT, KEYBIND_STRIP.control, TOPRIGHT, -10, -20)
	self.emptySlotsLabel:SetHidden(true)
	
	local slotsFragment = ZO_FadeSceneFragment:New(self.emptySlotsLabel)
	scene:AddFragment(slotsFragment)
	
	return scene;
end

function BackpackScene:Initiailize()

end

function BackpackScene:OnStateChange(oldState, newState)
	Log:T("BackpackScene:OnStateChange(oldState, newState)");
	if(newState == SCENE_HIDING) then
		ClearMenu();
	end
end

BACKPACK_SCENE = nil

