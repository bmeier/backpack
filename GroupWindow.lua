----------------------------------------
--  BackpackGroupWindow
----------------------------------------
local Log = LOG_FACTORY:GetLog("BackpackGroupWindow")

local NORTH , EAST , SOUTH , WEST = 0, 1, 2, 3
local ResizeController = ZO_Object:Subclass()
ResizeController.direction = 0
ResizeController.delta = 0

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

	local dx = math.min(math.abs(x-left), math.abs(x-right))
	local dy = math.min(math.abs(y-top), math.abs(y-bottom))

	if dx < dy then
		if math.abs(x-left) < math.abs(x-right) then
			self.direction  = WEST
		else
			self.direction  = EAST
		end
	else
		if math.abs(y-top) < math.abs(y-bottom) then
			self.direction  = NORTH
		else
			self.direction  = SOUTH
		end
	end

	self.delta = (BACKPACK.settings.ui.iconSize + BACKPACK.settings.ui.group.padding) * BACKPACK.settings.ui.scale
end

function ResizeController:OnUpdate( ... )
	local window = self.window
	local control = self.window.control
	local scale = BACKPACK.settings.ui.scale

	--  already scaled by control:SetScale()
	local w, h = control:GetWidth(), control:GetHeight()
	--  unscaled
	local prefW, prefH = self.window:GetPrefDimensions()
	prefW = prefW * scale; prefH = prefH * scale

	local rows, columns = window.group.settings.rows, window.group.settings.columns

	local top, left = control:GetTop(), control:GetLeft()
	if self.direction == EAST or self.direction == WEST then
		local dw = w-prefW
		if dw > self.delta then
			while dw > self.delta and columns < #window.group.slots do
				dw = dw - self.delta
				columns = columns + 1
			end
			window:SetColumns(columns)
			local newWidth, newHeight = window:DoLayout()
			window.control:SetHeight(newHeight)
			if self.direction == EAST then
				control:ClearAnchors()
				control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
			end
		elseif dw < 0 and columns > 1 then
			while dw < 0 and columns > 1 do
				dw = dw + self.delta
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
		local dh = h-prefH
		if dh > self.delta then
			while dh > self.delta and rows < #window.group.slots do
				dh = dh - self.delta
				rows = rows + 1
			end
			window:SetRows(rows)
			local newWidth, newHeight = window:DoLayout()

			window.control:SetWidth(newWidth)
			if self.direction == SOUTH then
				control:ClearAnchors()
				control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
			end
		elseif dh < 0 and rows > 1 then
			while dh < 0 and rows > 1 do
				dh = dh + self.delta
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
	self.window.control:SetDimensions(self.window:DoLayout())
end




BackpackGroupWindow = BackpackWindow:Subclass()
BackpackGroupWindow.group = nil;
BackpackGroupWindow.control = nil;
BackpackGroupWindow.prefWidth = 0
BackpackGroupWindow.prefHeight = 0
BackpackGroupWindow.layoutDirty = true

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

function BackpackGroupWindow:Initialize( group )
	assert(group)
	assert(self.control)

	local control = self.control;
	local name    = control:GetName()

	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);
	control:SetHidden(true)
	
	control:SetResizeHandleSize(MOUSE_CURSOR_RESIZE_NS)
	control:SetHandler('OnResizeStart', function() Log:T("OnResizeStart"); 
		self.resizeController:OnResizeStart() 
	end)

	control:SetHandler('OnResizeStop', function() Log:T("OnResizeStop"); 
		self.resizeController:OnResizeStop()
	end)
	

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
	if columns > #self.group.slots then
		columns = #self.group.slots
	end

	if columns < 1 then
		columns = 1
	end
	self.group.settings.columns = columns

	local rows = math.ceil(#self.group.slots/columns)
	self.group.settings.rows = rows
	
	self.layoutDirty = true
end

function BackpackGroupWindow:SetRows( rows )
	local columns = math.ceil(#self.group.slots/rows)
	self:SetColumns(columns)
end

function BackpackGroupWindow:DoLayout()
	--Log:T("BackpackGroupWindow:DoLayout()")
	if self.layoutDirty then
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

		local row = 1;
		local col = 1;
		for  _, slot  in pairs(self.group.slots) do
			
			local top =  (row-1)*(iconSize+padding);
			local left = (col-1)*(iconSize+padding);

			slot.control.control:ClearAnchors()
			slot.control.control:SetAnchor(TOPLEFT, control.content, TOPLEFT, left, top);

			if(col == columns) then
				row = row + 1;
				col= 1;
			else
				col = col + 1;
			end
		end

		self.prefWidth = width
		self.prefHeight = windowHeight
		self.layoutDirty = false
	end

	return self.prefWidth, self.prefHeight
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

	for   _, slot in pairs(group.slots) do
		slot.control.control:SetParent(control.content)
		slot.control.control:SetHidden(false)
	end

	self.layoutDirty = true
	local width, height = self:DoLayout()
	self.control:SetDimensions(width, height)
end