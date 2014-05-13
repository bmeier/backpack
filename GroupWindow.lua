----------------------------------------
--  BackpackGroupWindow
----------------------------------------
local Log = LOG_FACTORY:GetLog("BackpackGroupWindow")

local NORTH , EAST , SOUTH , WEST = 0, 1, 2, 3
local ResizeController = ZO_Object:Subclass()

function ResizeController:New( window )
	local controller = ZO_Object.New(self)
	controller.direction = NORTH
	controller.delta = 0
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




BackpackGroupWindow = ZO_Object:Subclass()

function BackpackGroupWindow:New( group )
	local obj = ZO_Object.New(self)
	obj:Initialize(group)	
	return obj;
end

function BackpackGroupWindow:Initialize( group )
	assert(group)
	
	
	self.group = group
	
	self.prefWidth = 0
	self.prefHeight = 0
	self.layoutDirty = true

	local control = CreateTopLevelWindow(group.name)
	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);
	control:SetHidden(true)
	
	control:SetMovable(true)
	control:SetMouseEnabled(true)
	control:SetResizeHandleSize(MOUSE_CURSOR_RESIZE_NS)

	control.backdrop = CreateControl(group.name.."Backdrop", control, CT_BACKDROP)
	control.backdrop:SetCenterColor(unpack(BACKPACK.settings.ui.group.backdrop.centerColor))
	control.backdrop:SetEdgeTexture(BACKPACK.settings.ui.group.backdrop.edgeTexture, BACKPACK.settings.ui.group.backdrop.edgeWidth, BACKPACK.settings.ui.group.backdrop.edgeHeight)
	control.backdrop:SetEdgeColor(unpack(BACKPACK.settings.ui.group.backdrop.edgeColor))
	control.backdrop:ClearAnchors()
	control.backdrop:SetAnchor(TOPLEFT, control, TOPLEFT, -BACKPACK.settings.ui.group.insets.left, -BACKPACK.settings.ui.group.insets.top)
	control.backdrop:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, BACKPACK.settings.ui.group.insets.right, BACKPACK.settings.ui.group.insets.bottom)

	control:SetHitInsets(-BACKPACK.settings.ui.group.insets.left, -BACKPACK.settings.ui.group.insets.top, BACKPACK.settings.ui.group.insets.right, BACKPACK.settings.ui.group.insets.bottom )
	
	control.backdrop:SetHidden(true)
	
	control.label = CreateControl(group.name ..  "Label", control, CT_LABEL)
	control.label:SetText(group.name);
	control.label:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
	control.label:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0);
	control.label:SetFont(BACKPACK.settings.ui.group.font);
	control.label:SetParent(control);

	control.content = CreateControl(group.name .. "ContentPanel", control, CT_CONTROL)
	control.content:SetParent(control);
	control.content:SetAnchor(TOPLEFT, control.label, BOTTOMLEFT, 0, 0);

	control:SetHandler('OnResizeStart', function() Log:T("OnResizeStart");
		self.resizeController:OnResizeStart()
	end)

	control:SetHandler('OnResizeStop', function() Log:T("OnResizeStop");
		self.resizeController:OnResizeStop()
		control.backdrop:SetHidden(true)
		self:SaveSettings()
	end)

	control:SetHandler('OnMouseUp', function() Log:T("OnMouseUp"); self:SaveSettings(); end);
	control:SetHandler('OnMoveStop', function() Log:T("OnMoveStop"); self:SaveSettings(); end)

	control:SetHandler("OnMouseEnter", function() control.backdrop:SetHidden(false) end)
	control:SetHandler("OnMouseExit",
	function()
		local x,y = GetUIMousePosition()
		local hidden = false
		if y < control:GetTop() or y > control:GetBottom() then
			hidden = true
		elseif x < control:GetLeft() or x > control:GetRight() then
			hidden = true
		end
		control.backdrop:SetHidden(hidden)
	end
	)
	
	self.control = control;
	self.resizeController = ResizeController:New(self)
	--self:Update()
end

function BackpackGroupWindow:SaveSettings()
	self.group.settings.top = self.control:GetTop()
	self.group.settings.left = self.control:GetLeft()
end


function BackpackGroupWindow:SetColumns( columns )
	if not columns then
		columns = #self.group.slots
	end
	
	if columns > #self.group.slots then
		if(#self.group.slots > 0) then
			columns = #self.group.slots
		end
	end
	
	if columns < 1 then
		columns = 1
	end

	--if self.group.settings.columns ~= columns then
		self.group.settings.columns = columns

		local rows = math.ceil(#self.group.slots/columns)
		self.group.settings.rows = rows

		self.layoutDirty = true
	--end
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


		local width  = self:GetPrefWidth(columns)
		local contentHeight = self:GetPrefWidth(rows) --wtf
		local windowHeight = contentHeight + self.control.label:GetFontHeight();

		self.control.content:SetDimensions(width, contentHeight)
		self.control.label:SetWidth(width)
		self.control.label:SetHeight(self.control.label:GetFontHeight())

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

function BackpackGroupWindow:GetPrefWidth( columns )
	local width = 0
	if columns then
		if columns > 0 then
			width = columns*BACKPACK.settings.ui.iconSize + (columns-1) * BACKPACK.settings.ui.group.padding
		end
	end
	return width
end

function BackpackGroupWindow:GetPrefHeight( rows )
	local height = self:GetPrefWidth( rows )
	height = height + self.control.label:GetFontHeight()
	return height
end

function BackpackGroupWindow:Update(  )
	local group   = self.group;
	local control = self.control;
	
	self:SetColumns(self.group.settings.columns)
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


	
	local width, height = self:DoLayout()
	self.control:SetDimensions(width, height)
	self.control:ClearAnchors()
	self.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.group.settings.left, self.group.settings.top)
	
end