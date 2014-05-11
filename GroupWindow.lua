
----------------------------------------
--  BackpackGroupWindow
----------------------------------------
local Log = LOG_FACTORY:GetLog("BackpackGroupWindow")


local ResizeController = ZO_Object:Subclass()
ResizeController.changeColumns = true
ResizeController.direction = 0
local NORTH , EAST , SOUTH , WEST = 0, 1, 2, 3

function ResizeController:New( window )
	local controller = ZO_Object.New(self)
	controller.window = window

	return controller
end

function ResizeController:OnResizeStart( ... )
	local control = self.window.control
	EVENT_MANAGER:RegisterForUpdate(self.window.name, 250, function() self:OnUpdate() end)

	local x, y = GetUIMousePosition()
	local top, left, bottom, right = control:GetTop(), control:GetLeft(), control:GetBottom(), control:GetRight()

	self.prevWidth, self.prevHeight = control:GetDimensions()
	self.initialWidth = self.prevWidth
	self.initialHeight = self.initialHeight

	local dir
	local dxLeft  = math.abs(x-left)
	local dxRight = math.abs(x-right)



	local dx = math.min(math.abs(x-left), math.abs(x-right))
	local dy = math.min(math.abs(y-top), math.abs(y-bottom))

	if dx < dy then
		if math.abs(x-left) < math.abs(x-right) then
			dir = WEST
		else
			dir = EAST
		end
	else
		if math.abs(y-top) < math.abs(y-bottom) then
			dir = NORTH
		else
			dir = SOUTH
		end
	end
	self.direction = dir
end

function ResizeController:OnUpdate( ... )
	--Log:T("ResizeController:OnUpdate, changing column count: ", self.changeColumnCount)

	local window = self.window
	local control = self.window.control
	local scale = BACKPACK.settings.ui.scale

	-- scaled
	local w, h = control:GetWidth(), control:GetHeight()

	--unscaled :(
	local prefW, prefH = self.window:GetPrefDimensions()
	local delta = (BACKPACK.settings.ui.iconSize + BACKPACK.settings.ui.group.padding) * BACKPACK.settings.ui.scale

	--Log:T("w: ", w,", prefW: ", prefW, ", dw: ", dw)
	--Log:T("h: ", h, ", dh: ", dh)
	--Log:T("cols: ", window.settings.columns )
	local top, left = control:GetTop(), control:GetLeft()
	if(self.changeColumns) then
		local dw = w-(prefW*scale)
		if dw >= delta then
			local columns = window.group.settings.columns
			while dw >=delta and columns < #window.group.slots do
				dw = dw - delta
				columns = columns + 1
			end
			window:SetColumns(columns)
			local newWidth, newHeight = window:DoLayout()
			window.control:SetHeight(newHeight)
			if self.direction == EAST then
				control:ClearAnchors()
				control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
			end
		elseif dw < 0 and window.group.settings.columns > 1 then
			local columns = window.group.settings.columns
			while dw < 0 and columns > 1 do
				dw = dw + delta
				columns = columns - 1
			end
			window:SetColumns(columns)
			local newWidth, newHeight = window:DoLayout()
			window.control:SetHeight(newHeight)
			if self.direction == EAST then
				control:ClearAnchors()
				control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
			end
		end
	else
		local dh = h-(prefH*scale)
		if dh >= delta then
			local rows = window.group.settings.rows
			while dh >=delta and rows < #window.group.slots do
				dh = dh - delta
				rows = rows + 1
			end
			window:SetRows(rows)
			local newWidth, newHeight = window:DoLayout()
			

			window.control:SetWidth(newWidth)
			if self.direction == SOUTH then
				control:ClearAnchors()
				control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
			end
		elseif dh < 0 and window.group.settings.rows > 1 then
			local rows =window.group.settings.rows
			while dh < 0 and rows > 1 do
				dh = dh + delta
				rows = rows - 1
			end
			window:SetRows(rows)
			local newWidth, newHeight = window:DoLayout()
			window.control:SetWidth(newWidth)
			if self.direction == SOUTH then
				control:ClearAnchors()
				control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
			end
		end
	end
end

function ResizeController:OnResizeStop( ... )
	EVENT_MANAGER:UnregisterForUpdate(self.window.name)
	local w, h = self.window:DoLayout()
	Log:T("pref dimensions: ", w, ", ", h)
	self.window.control:SetDimensions(w, h)
end




BackpackGroupWindow = BackpackWindow:Subclass()
BackpackGroupWindow.group = nil;
BackpackGroupWindow.control = nil;
BackpackGroupWindow.prefWidth = 0
BackpackGroupWindow.prefHeight = 0
BackpackGroupWindow.layoutDirty = false
BackpackGroupWindow.layoutColumns = true


function BackpackGroupWindow:New( group )
	assert(group)
	local obj = BackpackWindow.New(self, "BackpackGroupWindow".. group.name)
	assert(obj.control)
	obj:Initialize(group );
	obj.resizeController = ResizeController:New(obj)
	return obj;	
end


function BackpackGroupWindow:ApplySettings()
	BackpackWindow.ApplySettings(self)
end

function BackpackGroupWindow:OnResizeStart(width, height)
	Log:T("BackpackGroupWindow:OnResizeStart(width, height)")
	self.resizeController:OnResizeStart()
end

function BackpackGroupWindow:OnResizeStop()
	Log:T("OnResizeStop(width, height)")
	self.resizeController:OnResizeStop()
end

function BackpackGroupWindow:Initialize( group )
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
end


function BackpackGroupWindow:SetColumns( columns )
	--Log:T("SetColumns old columns: " .. self.group.settings.columns)
	--Log:T("SetColumns old rows: " .. self.group.settings.rows)
	if columns > #self.group.slots then
		columns = #self.group.slots
	end

 	if columns < 1 then 

 		columns = 1 
 	end

    self.group.settings.columns = columns
   -- Log:T("SetColumns new columns: " .. self.group.settings.columns)
    local rows = math.ceil(#self.group.slots/columns)
    
 	self.group.settings.rows = rows
 	self.layoutColumns = true
 	--Log:T("SetColumns new rows: " .. self.group.settings.rows)
end

function BackpackGroupWindow:SetRows( rows )
    local columns = math.ceil(#self.group.slots/rows)
    self:SetColumns(columns)
 	self.layoutColumns = false
end

function BackpackGroupWindow:DoLayout()
	--Log:T("BackpackGroupWindow:DoLayout()")

	local control = self.control
	local group = self.group
	local columns = self.group.settings.columns
	assert(columns)
	local rows = math.ceil(#group.slots / columns) 
assert(rows)
	self.group.settings.rows = rows

	local iconSize = BACKPACK.settings.ui.iconSize
	local padding  = BACKPACK.settings.ui.group.padding
	local insets   = BACKPACK.settings.ui.group.insets
	

	local width  = (columns*iconSize) + ((columns-1)*padding);
	local contentHeight = (rows * iconSize) + ((rows-1)*padding);
	local windowHeight = contentHeight + self.control.label:GetFontHeight();

	self.control.content:SetDimensions(width, contentHeight)
--	self.control:SetDimensions(width, windowHeight)
	local row = 1;
	local col = 1;
	for i=1, #self.group.slots do
		local slot = self.group.slots[i].control.control;
		local top =  (row-1)*(iconSize+padding);
		local left = (col-1)*(iconSize+padding);

		slot:ClearAnchors()
		slot:SetAnchor(TOPLEFT, control.content, TOPLEFT, left, top);

			if(col == columns) then 
				row = row + 1; 
				col= 1;
			else
				col = col + 1;
			end
	end
	
	self.prefWidth = width
	self.prefHeight = windowHeight

	return width, windowHeight
end

function BackpackGroupWindow:GetPrefDimensions()
	return self.prefWidth, self.prefHeight
end

function BackpackGroupWindow:Update(  )
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
	
	self.layoutDirty = true
	local width, height = self:DoLayout()	
	self.control:SetDimensions(width, height)
end