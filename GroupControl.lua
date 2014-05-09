
----------------------------------------
--  BackpackGroupControl
----------------------------------------
local Log = LOG_FACTORY:GetLog("BackpackGroupControl")

BackpackGroupControl = BackpackWindow:Subclass()
BackpackGroupControl.group = nil;
BackpackGroupControl.control = nil;

function BackpackGroupControl:New( group,  settings )
	assert(group)
	local obj = BackpackWindow.New(self, "BackpackGroupControl".. (group.name or "nil"));
	assert(obj.control)
	obj:Initialize(group,  settings);
	return obj;	
end


function BackpackGroupControl:OnResizeStart(width, height)
	Log:T("BackpackGroupControl:OnResizeStart(width, height)")
end

function BackpackGroupControl:OnResizeStop()
	Log:T("OnResizeStop(width, height)")
	self:SetColumnsFromWidth()
	self:DoLayout()
end

function BackpackGroupControl:SetColumnsFromWidth( )
	local width = self.control:GetWidth()
	local columns = math.floor( width / BACKPACK.settings.ui.iconSize )


	self.settings.columns = self:Limit(columns)
	Log:T("new column count: ", columns)
end

function BackpackGroupControl:Limit(columns)
	if columns > BACKPACK.settings.ui.group.maxColumnCount then
		columns = BACKPACK.settings.ui.group.maxColumnCount
	elseif columns < BACKPACK.settings.ui.group.minColumnCount then
		columns = BACKPACK.settings.ui.group.minColumnCount
	end
	return columns
end

function BackpackGroupControl:Initialize( group,  settings )
	assert(group)
	assert(self.control)
	
	local control = self.control;
	local name    = control:GetName()

	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);
	control:SetHidden(true)
	
	control.label = CreateControl(name ..  "Label", control, CT_LABEL)
	control.label:SetText(group.name);
	control.label:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0);
	control.label:SetFont(BACKPACK.settings.ui.group.font);
	control.label:SetParent(control);

	control.content = CreateControl(name .. "ContentPanel", control, CT_CONTROL)
	control.content:SetParent(control);
	control.content:SetAnchor(TOPLEFT, control.label, BOTTOMLEFT, 0, 0);

	self.group = group;
	self.control = control;
	self.control:SetHandler("Showing", 
		function() 
			if(#self.group.slots > 0) then
				self.control:SetHidden(false)
			else
				self.control:SetHidden(true)
			end 
		end )

	self:Update()
	self:DoLayout()
end


function BackpackGroupControl:DoLayout(width, height)
	Log:T("BackpackGroupControl:DoLayout(width, height): ", width, ", ", height)


	local control = self.control
	local group = self.group
	local columns = self.settings.columns
	local iconSize = BACKPACK.settings.ui.iconSize
	local padding  = BACKPACK.settings.ui.group.padding
	local insets   = BACKPACK.settings.ui.group.insets

	local rows = math.ceil(#group.slots / columns);
	width  = (columns*iconSize) + ((columns-1)*padding);

	local contentHeight = (rows * iconSize) + ((rows-1)*padding);
	local windowHeight = contentHeight + self.control.label:GetFontHeight();

	self.control.content:SetDimensions(width, height)
	self.control:SetDimensions(width, windowHeight)

	--if(columns ~= self.columns) then
		local r = 1;
		local c = 1;

		for i=1, #self.group.slots do
			local slot = self.group.slots[i].control.control;
			local top =  (r-1)*(iconSize+padding);
			local left = (c-1)*(iconSize+padding);
			slot:ClearAnchors()
			slot:SetAnchor(TOPLEFT, control.content, TOPLEFT, left, top);
			if(c == columns) then 
				r = r + 1; 
				c = 1;
			else
				c = c + 1;
			end
		end
	--end
	
end

function BackpackGroupControl:Update(  )
	local group   = self.group;
	local control = self.control;

	control:SetScale(BACKPACK.settings.ui.scale);
	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);

	for i=1,control.content:GetNumChildren() do
		local c = control.content:GetChild(i);
		if c then
			c:SetParent(nil)
			c:SetHidden(true)
		end
	end

	for i, slot in pairs(group.slots) do
		slot.control.control:SetParent(control.content)
		slot.control.control:SetHidden(false)
	end
	
	if not self.settings.columns or (self.settings.columns == 0) then
		local columns = #group.slots
		self:Limit(columns)
		if(columns > 6) then
			columns = 6
		end
		self.settings.columns = columns
	end
	self:DoLayout()	
end