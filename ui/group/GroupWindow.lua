----------------------------------------
--  GroupWindow
----------------------------------------
local Log = LOG_FACTORY:GetLog("GroupWindow")

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



local nextId = 0
local GroupWindow = ZO_Object:Subclass()
local CONTENT_PANEL_Y_OFFSET = 10
function GroupWindow:New( group )
	local obj = ZO_Object.New(self)
	obj:Initialize(group)
	return obj;
end

function GroupWindow:Initialize( group )
	assert(group)

	self.group = group

	self.prefWidth = 0
	self.prefHeight = 0
	self.minColumnCount = 1
	self.maxColumnCount = 1
	self.layoutDirty = true

	local name = "GroupWindow"..nextId
	nextId = nextId + 1

	local control = CreateControlFromVirtual(name, GuiRoot, "GroupWindow")
	assert(control, "Failed to create group window.")
	control:SetHidden(true)

	control.backdrop = GetControl(control, "Backdrop")
	control.backdrop:SetHidden(true)

	control.label = GetControl(control, "Label")
	control.content = GetControl(control, "ContentPanel")

	control.manager = self
	self.control = control;
	self.resizeController = ResizeController:New(self)
end

function GroupWindow:OnResizeStart()
	self.resizeController:OnResizeStart()
end

function GroupWindow:OnResizeStop()
	self.resizeController:OnResizeStop()
	self.control.backdrop:SetHidden(true)
	self:SaveSettings()
end

function GroupWindow:SaveSettings()
	self.group.settings.top = self.control:GetTop()
	self.group.settings.left = self.control:GetLeft()
end


function GroupWindow:SetColumns( columns )
	if not columns then
		columns = #self.group.slots
	end

	if columns > #self.group.slots then
		if(#self.group.slots > 0) then
			columns = #self.group.slots
		end
	end

	if columns < self.minColumnCount then
		columns = self.minColumnCount
	end

	if columns < 1 then
		columns = 1
	end

	if columns > self.maxColumnCount then
		columns = self.maxColumnCount
	end

	--if self.group.settings.columns ~= columns then
	self.group.settings.columns = columns

	local rows = math.ceil(#self.group.slots/columns)
	self.group.settings.rows = rows

	self.layoutDirty = true
	--end
end

function GroupWindow:SetRows( rows )
	local columns = math.ceil(#self.group.slots/rows)
	self:SetColumns(columns)
end

function GroupWindow:DoLayout()
	--Log:T("GroupWindow:DoLayout()")
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
		self.control.label:SetWidth(width)
		self.control.label:SetHeight(self.control.label:GetFontHeight())
		local contentHeight = self:GetPrefWidth(rows) --wtf
		local windowHeight = contentHeight + self.control.content:GetTop() - self.control:GetTop() + CONTENT_PANEL_Y_OFFSET

		self.control.content:SetDimensions(width, contentHeight)

		local row = 1;
		local col = 1;
		for  _, slot  in pairs(self.group.slots) do
			local top =  (row-1)*(iconSize+padding);
			local left = (col-1)*(iconSize+padding);

			slot.control.control:ClearAnchors()
			slot.control.control:SetAnchor(TOPLEFT, control.content, TOPLEFT, left, top);
			slot.control.control:SetHidden(false)
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

function GroupWindow:GetPrefDimensions()
	return self.prefWidth, self.prefHeight
end

function GroupWindow:GetPrefWidth( columns )
	local width = 0
	if columns then
		if columns > 0 then
			width = columns*BACKPACK.settings.ui.iconSize + (columns-1) * BACKPACK.settings.ui.group.padding
		end
	end
	return width
end

function GroupWindow:Update(  )
	local group   = self.group;
	local control = self.control;

	local availHeight = GuiRoot:GetHeight()/BACKPACK.settings.ui.scale
	local availWidth = GuiRoot:GetWidth()/BACKPACK.settings.ui.scale
	local maxRows = math.floor((availHeight + BACKPACK.settings.ui.group.padding) / (BACKPACK.settings.ui.iconSize + BACKPACK.settings.ui.group.padding ))
	maxRows = maxRows - 2
	if(maxRows < 1) then
		maxRows = 1
	end

	self.minColumnCount = math.ceil(#self.group.slots / maxRows)
	self.maxColumnCount = math.floor((availWidth + BACKPACK.settings.ui.group.padding) / (BACKPACK.settings.ui.iconSize + BACKPACK.settings.ui.group.padding )) -1

	self:SetColumns(self.group.settings.columns)
	control:SetScale(BACKPACK.settings.ui.scale);
	control:SetClampedToScreen(BACKPACK.settings.ui.group.clampToScreen);

	for   _, slot in pairs(group.slots) do
		slot.control.control:SetParent(control.content)
	end

	local width, height = self:DoLayout()
	self.control:SetDimensions(width, height)
	self.control:ClearAnchors()
	self.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.group.settings.left, self.group.settings.top)
	self.control.label:SetText(group.name)
end

function GroupWindow:ShowPopupMenu()
	ClearMenu()
	AddMenuItem(GetString(BP_ADD), function() backpack.ui.group.GROUP_OPTIONS_DIALOG:CreateGroup() end)
	AddMenuItem(GetString(BP_HIDE), function()  end)
	AddMenuItem(GetString(BP_EDIT), function() BACKPACK:EditGroup(self.group) end)
	AddMenuItem(GetString(BP_DELETE), function() BACKPACK:DeleteGroup(self.group.name)  end)
	ShowMenu(self.window)
end

function GroupWindow:OnResizeStart()
	self.resizing = true
	self.resizeController:OnResizeStart()
end

function GroupWindow:OnResizeStop()
	self.resizeController:OnResizeStop()
	self.control.backdrop:SetHidden(true)
	self:SaveSettings()
	self.resizing = nil
end

function GroupWindow:OnMouseUp(control, button, ...)
	Log:T("OnMouseUp: ", ...);
	if button == 2 then
		self:ShowPopupMenu()
	end
	self:SaveSettings()
end

function GroupWindow:OnMoveStop(control, button, ...)
	self:SaveSettings()
end

function GroupWindow:OnMouseEnter(control, button, ...)
	control.backdrop:SetHidden(false)
end
function GroupWindow:OnMouseExit(control, button, ...)
	self:SaveSettings()
	if not self.resizing then
		control.backdrop:SetHidden(true)
	end
end


backpack.ui.group.GroupWindow = GroupWindow
