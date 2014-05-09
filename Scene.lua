local Log = LOG_FACTORY:GetLog("BackpackScene");
local BackpackScene = ZO_Scene:Subclass();

BackpackScene.backpack = nil;
BackpackScene.searchBox = nil;
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
	scene:AddFragment(KEYBIND_STRIP_FRAGMENT);
   scene:AddFragment(MOUSE_UI_MODE_FRAGMENT)
   scene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
   scene:AddFragment(CLEAR_CURSOR_FRAGMENT)
   scene:AddFragment(UI_COMBAT_OVERLAY_FRAGMENT)
   scene:AddFragment(FRAME_PLAYER_FRAGMENT)
   scene:AddFragment(SYSTEM_WINDOW_SOUNDS)

   scene:AddFragmentGroup(FRAGMENT_GROUP.UI_WINDOW)
   scene:AddFragment(TOP_BAR_FRAGMENT)
   scene.searchBox = BackpackSearchbox:New();
  -- scene:AddFragment(searchBox);
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

BACKPACK_SCENE = BackpackScene:New();
SCENE_MANAGER:Add(BACKPACK_SCENE);

