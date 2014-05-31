local Log = LOG_FACTORY:GetLog("GroupDialog")

local DIALOG_NAME = "BP_GROUP_DIALOG"
local CONTROL_NAME = "BP_GROUP_DIALOG_TOPLEVEL"
local MODE_CREATE = "create"
local MODE_EDIT = "edit"

local function InitializeGroupDialog( dialog )
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

					local weight = dialog.weightTextField:GetText()
					if not weight or not tonumber(weight) then
						ZO_Alert(nil, nil, "Invalid weight")
						Log:W("Invalid weight")
						return
					end
					weight = tonumber(weight)

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
							BACKPACK.settings.groups[name] = BACKPACK.settings.groups[dialog.origName]
							BACKPACK.settings.groups[dialog.origName] = nil

							BACKPACK.settings.ui.groups[name] = BACKPACK.settings.ui.groups[dialog.origName]
							BACKPACK.settings.ui.groups[dialog.origName] = nil
						end
						local settings = BACKPACK.settings.groups[name]
						settings.name = name
						settings.filter = dialog.filter
						settings.weight = weight
						settings.hidden = ZO_CheckButton_IsChecked(dialog.checkbox)

						local group = BACKPACK:GetGroup(dialog.origName)
						assert(group)
						group.name = name
						group.filter = dialog.filter

					else
						BACKPACK:AddGroup({ name=name, filter=dialog.filter, weight=weight, hidden=ZO_CheckButton_IsChecked(dialog.checkbox) } )
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

local function Commit( dialog )

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
	dialog.weightTextField = backpack.ui.TextField:New(GetControl(GetControl(dialog.control, "Content"), "Weight"))
end

local initialized = false
local GroupDialog = ZO_Object:Subclass()
GroupDialog.name = CONTROL_NAME
function GroupDialog:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function GroupDialog:Initialize(...)
	-- create the dialog control
	if not initialized then
		self.filter = nil

		local control = CreateControlFromVirtual("BackpackGroupDialog", GuiRoot, "BackpackGroupDialog")
		self.control = control
		assert(control)

		self.content = GetControl(control, "Content")
		self.nameEdit = GetControl(GetControl(self.content, "Name"), "Edit")

		self.checkbox = GetControl(self.content, "Hidden")
		InitializeCombobox(self)
		InitializeButtons(self)
		--		IntializeCheckbox(self)
		InitializeWeight(self)
		InitializeGroupDialog( self )
		initialized = true
	end
end

function GroupDialog:SetWeight( weight )
	self.weightTextField:SetText(weight)
end

function GroupDialog:SetFilter( name )
	self.filter = name
	RefreshFilters(self)
end

function GroupDialog:SetGroupName(name)
	assert(name)
	self.name = name
	self.nameEdit:SetText(name)
end

function GroupDialog:SetGroup(group)
	self.filter = group.filter
	self:SetGroupName(group.name)
	self:SetWeight(group.weight)
	self.origName = group.name
	Log:T("SetGroup() group filter: ", group.filter)
	self.group = group
	ZO_CheckButton_SetCheckState(self.checkbox, group.hidden)
	RefreshFilters(self)
end


function GroupDialog:ShowEditGroupDialog(group, cb)
	self.title = "Edit Group"
	self.origName = group.name
	self.mode = MODE_EDIT
	self:SetGroup(group)
	self:Show(cb)
end


function GroupDialog:ShowCreateGroupDialog(cb)
	self.title = "Create Group"
	self.mode = MODE_CREATE
	self.hidden = false
	self.origName = nil
	ResetDialog(self)
	self:Show(cb)
end

function GroupDialog:GetGroupName()
	return self.nameEdit:GetText()
end

function GroupDialog:Show(cb)
	self.callback = cb
	RefreshFilters(self)
	local dialog = ZO_Dialogs_ShowDialog(DIALOG_NAME, {}, {titleParams={self.title}})
	if (self.mode == MODE_EDIT) then
		self.deleteButton:SetHidden(false)
		self.deleteButton:SetEnabled(true)
	else
		self.deleteButton:SetHidden(true)
		self.deleteButton:SetEnabled(false)
	end
end

function GroupDialog:Hide()
	ZO_Dialogs_ReleaseDialog(DIALOG_NAME, true)
end

backpack.ui.group.GROUP_DIALOG=GroupDialog:New()