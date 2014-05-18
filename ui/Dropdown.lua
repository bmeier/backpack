local BUTTON_NAME = "Button"
local TEXTFIELD_NAME = "Edit"
local Log = LOG_FACTORY:GetLog("Dropdown")

local Dropdown = ZO_CallbackObject:Subclass()
Dropdown.SELECTED_ITEM_CHANGED = "SELECTED_ITEM_CHANGED"

function Dropdown:New(control, options)
	local dropdown = ZO_CallbackObject.New(self)
	dropdown:Initialize(control, options)
	return dropdown
end

function Dropdown:Initialize(control, options)
	self.options = options or {}
	self.selectedItem = nil
	self.control = control

	local onClick = function()
		self:OnClick()
	end

	self.edit = GetControl(control, TEXTFIELD_NAME)
	
	--self.button = GetControl(control, BUTTON_NAME)
	--self.button:SetHandler("OnClicked", onClick)
	
--	if #self.options > 0 then
		self:SetSelectedItem(1)
--	end
end

function Dropdown:OnClick()
	if #self.options > 0 then
		ClearMenu()
		for k, option in pairs(self.options) do
			AddMenuItem(option, function() self:SetSelectedItem(k) end)
		end
		ShowMenu(self.control)
	end
end

function Dropdown:SetSelectedItem( luaindex )
	local selection = self.options[luaindex]
	if selection and selection ~= self.selectedItem then
		self.selectedItem = selection
		self.FireCallbacks(Dropdown.SELECTED_ITEM_CHANGED, selection)
	end
end

backpack.ui.Dropdown = Dropdown