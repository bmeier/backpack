local Log = LOG_FACTORY:GetLog("GroupOptionsDialog")

local DIALOG_NAME = "BP_GROUP_OPTIONS_DIALOG"
local CONTROL_NAME = "BP_GROUP_OPTIONS_DIALOG_TOPLEVEL"
local MODE_CREATE = "create"
local MODE_EDIT = "edit"

local function InitializeGroupOptionsDialog( dialog )
	local control = dialog.control
	assert(control)
	dialog.deleteButton =  GetControl(control, "Delete")
	ZO_Dialogs_RegisterCustomDialog(DIALOG_NAME,
	{
		customControl = control,
		canQueue = true,
		title =
		{
			text = "<<1>>",
		},
		setup = function(self)  end,
		buttons =
		{
			{
				control =   GetControl(control, "Delete"),
				text =      "Delete",
				keybind =   "DIALOG_SECONDARY",
				noReleaseOnClick = true,
				callback =  function( control )
					dialog:Hide()
					BACKPACK:DeleteGroup(dialog.origName)
				end,
			},

			{
				control =   GetControl(control, "Create"),
				text =      "Ok",
				keybind =   "DIALOG_PRIMARY",
				noReleaseOnClick = true,
				callback =  function( control )
					local name = dialog:GetGroupName()
					if not name or name == "" then
						ZO_Alert(nil, nil, "Invalid group name")
						Log:W("Invalid group name")
						return
					end
					if dialog.mode == MODE_CREATE and BACKPACK.settings.groups[name] then
						ZO_Alert(nil, nil, "Group already exists")
						Log:W("Group already exists.")
						return
					elseif not dialog.filter then
						ZO_Alert(nil, nil, "Invalid filter")
						Log:W("No filter selected")
						return
					end

					if dialog.mode == MODE_EDIT then
						if  dialog.origName and dialog.origName ~= name then
							assert(false)
							BACKPACK.settings.groups[name] = BACKPACK.settings.groups[dialog.origName]
							BACKPACK.settings.groups[dialog.origName] = nil
						end
						local settings = BACKPACK.settings.groups[name]
						settings.name = name
						settings.filter = dialog.filter
						settings.weight = dialog.weight
						settings.hidden = false

						local group = BACKPACK:GetGroup(dialog.origName)
						assert(group)
						group.name = name
						group.filter = dialog.filter

					else
						BACKPACK:AddGroup({ name=name, filter=dialog.filter, weight=dialog.weight, hidden=false } )
					end
					BACKPACK:UpdateGroups()
					dialog:Hide()

				end,
			},

			{

				control =   GetControl(control, "Cancel"),
				text =      "Cancel",
				keybind =   "DIALOG_NEGATIVE",
				noReleaseOnClick = true,
				callback =  function( control )
					dialog:Hide()
					if dialog.callback then
						dialog.callback()
					end
				end,
			},
		}
	})
	
	dialog.cancelButton =  GetControl(control, "Cancel")
end


local function ResetDialog( dialog )
	dialog:SetGroupName("")
	dialog:SetWeight(0)
	dialog:SetFilter(nil)	
end

local function RefreshFilters( dialog )
	local control = dialog.control
	assert(control)

	dialog.combobox:ClearItems()
	dialog.combobox.entries = {}
	local selected = nil
	for k, v in pairs(BACKPACK.settings.filter) do
		local entry = dialog.combobox:CreateItemEntry(k, 
			function() 
				dialog.filter = k
			end)
		dialog.combobox:AddItem(entry)

		if dialog.filter and dialog.filter == k then
			selected = entry
		end
	end

	if selected then
		dialog.combobox:SelectItem(selected)
	end

end

local function InitializeCombobox( dialog )
	local comboboxCtrl  = GetControl(dialog.content, "FilterComboBox")
	local combobox = ZO_ComboBox:New(comboboxCtrl)

	dialog.combobox = combobox
end

local function InitializeButtons(dialog)
	local ctrl = GetControl(dialog.content, "AddFilter")
	assert(ctrl)
	ctrl:SetHandler("OnClicked",
	function(control, button)
		if button == 1 then
			dialog:Hide()
			backpack.ui.filter.FILTER_OPTIONS_DIALOG:Create(
			function(filter)
				if filter then
					dialog:SetFilter(filter.name)
				end
				dialog:Show()
			end
			)
		end
	end
	)


	ctrl = GetControl(dialog.content, "EditFilter")
	assert(ctrl)
	ctrl:SetHandler("OnClicked",
	function(control, button)
		if button == 1 then
			if(dialog.filter) then
				dialog:Hide()
				backpack.ui.filter.FILTER_OPTIONS_DIALOG:Edit(dialog.filter,
				function(filter)
					if filter then
						dialog:SetFilter(filter.name)
					end
					dialog:Show()
				end
				)
			end
		end
	end
	)


	ctrl = GetControl(dialog.content, "CopyFilter")
	assert(ctrl)
	ctrl:SetHandler("OnClicked",
	function(control, button)
		if button == 1 then
			if(dialog.filter) then
				local data = BACKPACK.settings.filter[dialog.filter]
				local copy = ZO_DeepTableCopy(data)
				local name = dialog.filter
				while BACKPACK.settings.filter[name] do
					name = "Copy of "..name
				end
				copy.name = name
				BACKPACK.settings.filter[copy.name] = copy
				dialog:SetFilter(copy.name)
			end
		end
	end
	)
	ctrl.tooltipText = "Not implemented"


	ctrl = GetControl(dialog.content, "DeleteFilter")
	assert(ctrl)
	ctrl:SetHandler("OnClicked",
	function(control, button)
		if button == 1 then
			if(dialog.filter) then
				BACKPACK:DeleteFilter(dialog.filter)
				for k,v in pairs(BACKPACK.groups) do
					repeat --wtf lua
						if dialog.mode == MODE_EDIT and dialog.origName == v.name then
							break
						end
						if(v.filter == dialog.filter) then
							BACKPACK:DeleteGroup(v.name)
						end
					until true
				end
				
				
				if dialog.mode == MODE_EDIT then
					local groupFilter = BACKPACK.settings.groups[dialog.origName].filter
					
					if groupFilter == dialog.filter then
						dialog.cancelButton:SetEnabled(false)
					end
				end
				dialog.filter = nil
				RefreshFilters(dialog)
			end
		end
	end
	)

end

local function InitializeWeight(dialog)
	local slider = GetControl(dialog.content, "WeightSlider")
	assert(slider)
	slider:SetMinMax(0, 100)
	slider:SetValueStep(1)
	slider:SetHandler("OnValueChanged", function(control) dialog:SetWeight(dialog.slider:GetValue()) end)

	dialog.slider = slider
	dialog.weightLabel = GetControl(dialog.content, "WeightValue")
end

local initialized = false
local GroupOptionsDialog = ZO_Object:Subclass()
GroupOptionsDialog.name = CONTROL_NAME
function GroupOptionsDialog:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function GroupOptionsDialog:Initialize(...)
	-- create the dialog control
	if not initialized then
		self.filter = nil

		local control = CreateControlFromVirtual("BP_GroupOptionsDialog", GuiRoot, "BP_GroupOptionsDialog")
		self.control = control
		assert(control)

		self.content = GetControl(control, "Content")
		self.nameEdit = GetControl(GetControl(self.content, "Name"), "Edit")
		InitializeCombobox(self)
		InitializeButtons(self)
		--		IntializeCheckbox(self)
		InitializeWeight(self)
		InitializeGroupOptionsDialog( self )
		initialized = true
	end
end

function GroupOptionsDialog:SetWeight( weight )
	weight = zo_min(weight, 100)
	weight = zo_max(weight, 0)

	self.weight = weight
	self.weightLabel:SetText(weight)
	self.slider:SetValue(weight)
end

function GroupOptionsDialog:SetFilter( name )
	self.filter = name
	RefreshFilters(self)
end

function GroupOptionsDialog:SetGroupName(name)
	assert(name)
	self.name = name
	self.nameEdit:SetText(name)
end

function GroupOptionsDialog:SetGroup(group)
	self.filter = group.filter
	self:SetGroupName(group.name)
	self:SetWeight(group.weight)
	self.origName = group.name
	Log:T("SetGroup() group filter: ", group.filter)
	self.group = group
	RefreshFilters(self)
end


function GroupOptionsDialog:EditGroup(group, cb)
	self.title = "Edit Group"
	self.origName = group.name
	self.mode = MODE_EDIT
	self:SetGroup(group)
	self:Show(cb)
end


function GroupOptionsDialog:CreateGroup(cb)
	self.title = "Create Group"
	self.mode = MODE_CREATE
	self.weight = 0
	self.hidden = false
	self.origName = nil
	ResetDialog(self)
	self:Show(cb)
end

function GroupOptionsDialog:GetGroupName()
	return self.nameEdit:GetText()
end

function GroupOptionsDialog:Show(cb)
	self.callback = cb
	RefreshFilters(self)
	local dialog = ZO_Dialogs_ShowDialog(DIALOG_NAME, {}, {titleParams={self.title}})
	local delete = GetControl(dialog, "")
	if (self.mode == MODE_EDIT) then
		self.deleteButton:SetHidden(false)
	else
		self.deleteButton:SetHidden(true)
	end
end

function GroupOptionsDialog:Hide()
	ZO_Dialogs_ReleaseDialog(DIALOG_NAME, true)
end
backpack.ui.group.GROUP_OPTIONS_DIALOG=GroupOptionsDialog:New()