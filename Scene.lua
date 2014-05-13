local Log = LOG_FACTORY:GetLog("BackpackScene");

local BackpackFragment = ZO_FadeSceneFragment:Subclass()

function BackpackFragment:New( control )
	local fragment = ZO_FadeSceneFragment.New(self, control)
	fragment.enabled = true
	return fragment
end

function BackpackFragment:Show()
	if self.enabled == true then
		ZO_FadeSceneFragment.Show(self)
	end
	
	self:OnShown()
end

BackpackScene = ZO_Scene:Subclass();


BackpackScene.emptySlotsLabel = nil
BackpackScene.backpack = nil;
BackpackScene.searchBox = nil;
BackpackScene.bagSwitcherWindow = nil

function BackpackScene:New( )
	local scene = ZO_Scene.New(self, "backpack", SCENE_MANAGER);
	scene:RegisterCallback("StateChange",  function(oldValue, newValue) scene:OnStateChange(oldValue, newValue) end)
	
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

	scene.bagSwitcherWindow = CreateTopLevelWindow("BackpackBagSwitcher")
	local relTo = scene.bagSwitcherWindow
	local relPoint = TOPLEFT
	
	scene.bagSwitcherWindow.buttons = {}
	for i,bag in pairs(BACKPACK.bags) do
		local button = CreateControl("BackpackBagSwitcherButton"..i, scene.bagSwitcherWindow, CT_BUTTON)
		button:SetNormalTexture(bag.texture)
		button:SetDimensions(64, 64)
		
		button:SetHandler("OnClicked", 
			function() 
				
				--what a dirty hack 
				for i, b in pairs(scene.bagSwitcherWindow.buttons) do
					if i == bag.id then
						b:SetDesaturation(0)
					else
						b:SetDesaturation(1)
					end
				end
				BACKPACK:ShowBag( bag ) 
			end
		)
			
		button:ClearAnchors()
		button:SetAnchor(TOPLEFT, relTo, relPoint, 10, 0)
		relTo = button				
		relPoint = TOPRIGHT
		
		button.tooltipText = "Show " .. bag.name
		button:SetHandler("OnMouseEnter",
			function(  )
				InitializeTooltip(InformationTooltip, button)
				SetTooltipText(InformationTooltip, button.tooltipText)
			end
		)
		
		button:SetHandler("OnMouseExit",
			function(  )
				ClearTooltip(InformationTooltip)
			end
		)
		
	--	button:SetHidden(true)
		

		
		if(i ~= BACKPACK.currentBag) then
			button:SetDesaturation(1)
		end
		
		scene.bagSwitcherWindow.buttons[bag.id] =  button
		
		
	end	
	scene.bagSwitcherWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 10, 10)
	scene.bagSwitcherWindow:SetHidden(true)
	scene:AddFragment( ZO_FadeSceneFragment:New(scene.bagSwitcherWindow) )
	return scene;
end

function BackpackScene:Initiailize()

end


function BackpackScene:Update( bag )
	self.emptySlotsLabel:SetText(bag.freeSlots.."/"..bag.numSlots)
	
	for i, button in pairs(self.bagSwitcherWindow.buttons) do
		if( i == bag.id) then
			button:SetDesaturation(0)
		else
			button:SetDesaturation(1)
		end
	end
end

function BackpackScene:OnStateChange(oldState, newState)
	Log:T("BackpackScene:OnStateChange(oldState, newState)")
	Log:T("Bank slots ", BACKPACK.bags[BAG_BANK].numSlots )
	
	if(BACKPACK.currentBag == BAG_BANK) 
	then
		Log:T("Current bag: bank")
	else
		Log:T("Current bag: backpack")
	end
	if(newState == SCENE_HIDING) then
		ClearMenu();
	end
end

BACKPACK_SCENE = nil

