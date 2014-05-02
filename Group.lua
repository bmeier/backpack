
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




----------------------------------------
--  BackpackGroupControl
----------------------------------------
local BackpackGroupControl = ZO_Object:Subclass()
BackpackGroupControl.group = nil;
BackpackGroupControl.control = nil;
BackpackGroupControl.parent = nil;
BackpackGroupControl.itemMouseHandler = nil;
BackpackGroupControl.itemButtons = {};

BackpackGroupControl.columns = 0;
BackpackGroupControl.settings = DEFAULT_SETTINGS;

local DEFAULT_SETTINGS = { top=0, left=0, width=0, height=0 };


function BackpackGroupControl:new( group,  settings )
	assert(group)
	local obj = ZO_Object.New(self);
	obj:Initialize(group,  settings);
	return obj;	
end

function BackpackGroupControl:storePosition()
	BACKPACK.settings.ui.group.controls[self.group.name].left = self.control:GetLeft();
	BACKPACK.settings.ui.group.controls[self.group.name].top = self.control:GetTop();
end

function BackpackGroupControl:Initialize( group,  settings )
	if( control ) then Log:W("BackpackGroupControl already initialized.") return end
	assert(group)

		
	local name    = "BackpackGroupControl".. (group.name or "nil")
	local control = WINDOW_MANAGER:CreateTopLevelWindow(name)

    local left = BACKPACK.settings.ui.group.controls[group.name].left;
	local top  = BACKPACK.settings.ui.group.controls[group.name].top;
	local insets = 0 --BACKPACK.settings.ui.group.insets;
	

	control:SetMouseEnabled(true)
	control:SetMovable(true);
	control:SetHandler('OnMouseUp', function() Log:T("OnMouseUp"); self:storePosition(); end);
	control:SetHandler('OnMoveStop', function() Log:T("OnMoveStop"); self:storePosition(); end)
	control:SetHandler('OnClicked', function() Log:T("OnClicked"); end)

	control:SetResizeToFitDescendents(true);	
	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);
	control:SetHidden(true);

--	control.background = {}
--	control.background.left = WINDOW_MANAGER:CreateControl(name.."BackgroundLeft", control, CT_TEXTURE)
--	control.background.left:SetTexture("Esoui/art/miscellaneous/centerscreen_left.dds");
--	control.background.left:SetAnchor(TOPLEFT, control, TOPLEFT, -32 -32);
--	control.background.left:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 32, 64);

	--control.background.right = WINDOW_MANAGER:CreateControl(name.."BackgroundRight", control, CT_TEXTURE)
	--control.background.right:SetTexture("Esoui/art/miscellaneous/centerscreen_right.dds");
	--control.background.right:SetAnchor(TOPLEFT, control.background.left, TOPRIGHT)
	--control.background.right:SetAnchor(BOTTOMRIGHT, control.background.left, BOTTOMRIGHT, 5, 0);

	--control.background.right:SetAnchor(BOTTOMLEFT, control,  BOTTOM, 0, insets)
	--control.background.right:SetAnchor(TOPRIGHT, control, TOPRIGHT, insets, insets);

	--control.background:SetColor(1, 0, 0, 0.5);
	
	--control.background:SetAnchor(TOPLEFT, control, TOPLEFT);
	--control.background:SetAnchor(BOTTOMRIGHT, control, BOTTOM);
	

	control.label = WINDOW_MANAGER:CreateControl(name ..  "Label", control, CT_LABEL)
	control.label:SetText(group.name);
	control.label:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0);
	control.label:SetFont(BACKPACK.settings.ui.group.font);
	control.label:SetParent(control);
	control.label:SetMouseEnabled(true);
	--control.label:SetMovable(true);
	control.label:SetHandler("OnClicked", function(...) Log:T("Label clicked") end);

	

	local columns = BACKPACK.settings.ui.group.maxColumnCount;
	if (columns > #group.slots) then columns = #group.slots end
	local rows = math.ceil(#group.slots / columns);

	local iconSize = BACKPACK.settings.ui.iconSize;
	local padding  = BACKPACK.settings.ui.group.padding;
	local insets   = BACKPACK.settings.ui.group.insets;

	local width  = (columns*iconSize) + ((columns-1)*padding);
	local height = (rows * iconSize) + ((rows-1)*padding);

	
	control.content = WINDOW_MANAGER:CreateControl(name .. "ContentPanel", control, CT_CONTROL)
	control.content:SetParent(control);
	control.content:SetDimensions(width, height);
	control.content:SetAnchor(TOPLEFT, control.label, BOTTOMLEFT, 0, 0);
	control:SetDimensions(width, height+100);
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top);

	self.group = group;
	self.settings = settings;
	self.control = control;
	self.control:SetHandler("Showing", 
		function() 
			if(#self.group.slots > 0) then
				self.control:SetHidden(false)
			else
				self.control:SetHidden(true)
			end 
		end )


end

function BackpackGroupControl:Update(  )
	local group   = self.group;
	local control = self.control;

	local left    = BACKPACK.settings.ui.group.controls[group.name].left;
	local top     = BACKPACK.settings.ui.group.controls[group.name].top;
	local insets  = 0 --BACKPACK.settings.ui.group.insets;
	
	control:SetScale(BACKPACK.settings.ui.scale);
	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);

	for i=1,control.content:GetNumChildren() do
		local c = control.content:GetChild(i);
		if c then
			c:SetParent(nil)
			c:SetHidden(true)
		end
	end
	
	local columns = BACKPACK.settings.ui.group.maxColumnCount;
	if (columns > #group.slots) then columns = #group.slots end
	local rows = math.ceil(#group.slots / columns);

	local iconSize = BACKPACK.settings.ui.iconSize;
	local padding  = BACKPACK.settings.ui.group.padding;
	local insets   = BACKPACK.settings.ui.group.insets;

	local width  = (columns*iconSize) + ((columns-1)*padding);
	local height = (rows * iconSize) + ((rows-1)*padding);

	
	control.content:SetDimensions(width, height);
	
	local r = 1;
	local c = 1;

	for i=1, #group.slots do
		local slot = group.slots[i].control.control;
		local top =  (r-1)*(iconSize+padding);
		local left = (c-1)*(iconSize+padding);
		slot:SetDimensions(iconSize, iconSize);
		slot:SetParent(control.content);
		slot:SetHidden(false);
		slot:SetAnchor(TOPLEFT, control.content, TOPLEFT, left, top);
		if(c == columns) then 
			r = r + 1; 
			c = 1;
		else
			c = c + 1;
		end
	end

end


BackpackGroup = ZO_Object:Subclass();
BackpackGroup.control = nil;
BackpackGroup.fragment = nil;
BackpackGroup.name = "";
BackpackGroup.slots = {};
BackpackGroup.filter = nil;
BackpackGroup.hidden = false;

function BackpackGroup:New( name, filter )
	local group = ZO_Object.New(self);
	group.name = name
	group.filter = filter
	group:Initialize();
	return group;
end

function BackpackGroup:Initialize() 
	local name = self.name.."Control"
	self.control = BackpackGroupControl:new(self);
	self.fragment = BackpackGroupFragment:New(self);
end

function BackpackGroup:Update() 


	self.control:Update()
end

