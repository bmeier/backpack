local Log = LOG_FACTORY:GetLog("FilterOptionsDialog")

local DIALOG_NAME = "BP_FILTER_OPTIONS_DIALOG"
local CONTROL_NAME = "BP_FILTER_OPTIONS_TOPLEVEL"
local MODE_CREATE = "create"
local MODE_EDIT = "edit"

local function InitializeFilterOptionsDialog( dialog )
	local control = dialog.control
	assert(control)
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
				control =   GetControl(control, "Create"),
				text =      "Ok",
				keybind =   "DIALOG_PRIMARY",
				noReleaseOnClick = true,
				callback =  function( control )
					local name = dialog:GetFilterName()
					if not name or name == "" then
						ZO_Alert(nil,nil,"Invalid filter name")
						return
					end


					if dialog.mode == MODE_CREATE then
						for k,v in pairs(BACKPACK.settings.filter) do
							if name == v.name then
								ZO_Alert(nil,nil,"Filter '"..name.."' already exists")
								return
							end
						end
					end

					local type = dialog:GetFilterType()
					if not type then
						ZO_Alert(nil, nil, "Invalid filter type")
						return
					end

					local options = dialog:GetFilterOptions() 
					assert(options, "No options for filter "..name)
					local filter = {
						name = name,
						type = type,
						options = options
					}
					
					BACKPACK.settings.filter[name] = filter
					

					dialog:Hide()

					if dialog.callback then
						dialog.callback(filter)
					end
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
						zo_callLater(function() dialog.callback() end, 250)
					end
				end,
			},
		}
	})
end

local function IntializeFilterTypes( dialog )
	assert(dialog.control)

	local defaultOptions = GetControl(dialog.control, "DefaultOptions")

	local boxControl = GetControl(defaultOptions, "TypeComboBox")
	assert(boxControl)

	local comboBox = ZO_ComboBox:New(boxControl)
	assert(comboBox)

	local function OnFilterTypeChanged(type)
	end

	local availableTypes = backpack.filter.FILTER_FACTORY:GetFilterTypes()
	dialog.types = {}
	comboBox.entries = {}
	assert(#availableTypes ~= 0)
	for k, type in pairs(availableTypes)
	do
		-- check if an options panel for the filter has been registered
		local optionsControl = backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions( type )

		if optionsControl then
			local filter = backpack.filter.FILTER_FACTORY:GetFilter( type )

			local data = {}
			data.name = filter.name
			data.description = filter.description
			data.type = type
			data.options = optionsControl
			dialog.types[data.type] = data
			
			local entry = comboBox:CreateItemEntry(data.name, function() dialog:SetFilterType(type) end)
			comboBox:AddItem(entry)
			comboBox.entries[data.type] = entry
			
		end
	end
	dialog.combobox = comboBox
	comboBox:SelectItem(comboBox.entries[backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType])
end

local initialized = false
local FilterOptionsDialog = ZO_Object:Subclass()
FilterOptionsDialog.name = CONTROL_NAME

function FilterOptionsDialog:New( )
	local panel = ZO_Object.New(self)
	panel:Initialize( )
	return panel
end

function FilterOptionsDialog:OnFilterTypeChanged( type )
end

function FilterOptionsDialog:SetFilterType( type )
	Log:T("Filter type changed")

	self.type = type

	local optionsContainer = GetControl(self.control, "FilterOptions")
	assert(optionsContainer)

	if self.options then
		self.options.control:ClearAnchors()
		self.options.control:SetParent(nil)
		self.options.control:SetHidden(true)
	end
	
	-- table self.types created in IntitializeFilterTypes
	local data = self.types[type]
	
	assert(data.options)
	data.options.control:ClearAnchors()
	data.options.control:SetAnchor(TOPLEFT, optionsContainer, TOPLEFT)
	data.options.control:SetParent(optionsContainer)
	data.options.control:SetHidden(false)
	
	-- this is redundant information
	self.options = data.options
end




function FilterOptionsDialog:Initialize(  )
	if not initialized then
		self.control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot, "BP_FilterOptionsDialog")
		local control = self.control
		assert(control)

		local defaultOptions = GetControl(control, "DefaultOptions")
		self.name = GetControl(GetControl(defaultOptions, "Name"), "Edit")
		assert(self.name)

		assert(self.control)

		IntializeFilterTypes(self)
		InitializeFilterOptionsDialog( self )
		initialized = true
	end
end

function FilterOptionsDialog:SetFilter( filter )
	local data = BACKPACK.settings.filter[filter]
	self:SetFilterName(data.name)
	
	self.combobox:SelectItem(self.combobox.entries[data.type])
	
	self:SetFilterOptions(data.options)
end

function FilterOptionsDialog:SetFilterOptions ( options )
	if self.options then
		self.options:SetOptions(options, self)
	end
end

function FilterOptionsDialog:GetFilterOptions()
	local options

	if self.options then
		options = self.options:GetOptions()
	end

	return options
end

function FilterOptionsDialog:SetFilterName( name )
	self.name:SetText(name)
end

function FilterOptionsDialog:GetFilterName()
	return self.name:GetText()
end

function FilterOptionsDialog:GetFilterType()
	return self.type
end

function FilterOptionsDialog:GetOptions()
	return self.options:GetOptions()
end

function FilterOptionsDialog:Reset()
	self:SetFilterName("")
	
	self.combobox:SelectItem(self.combobox.entries[backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterType])
	
end
function FilterOptionsDialog:Show( callback )
	self.callback = callback
	ZO_Dialogs_ShowDialog(DIALOG_NAME, {},  {titleParams={self.title}})
end

function FilterOptionsDialog:Hide()
	ZO_Dialogs_ReleaseDialog(DIALOG_NAME, true)
end

function FilterOptionsDialog:Edit( filter, cb )
	self.mode = MODE_EDIT
	self.title = "Edit Filter"

	self:SetFilter( filter )
	self:Show(cb)
end

function FilterOptionsDialog:Create(cb)
	self.mode = MODE_CREATE
	self.title = "Create Filter"

	self:Reset()
	self:Show(cb)
end

backpack.ui.filter.FILTER_OPTIONS_DIALOG = FilterOptionsDialog:New()
