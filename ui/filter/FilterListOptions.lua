local TEMPLATE = "BackpackFilterListOptions"
local CONTROL_NAME = "BP_FILTER_LIST_FILTER_OPTIONS"

local List = ZO_SortFilterList:Subclass()

function List:New(control, parent)
	local obj = ZO_SortFilterList.New(self, control)
	obj:Initialize(parent)
	return obj
end

local LIST_DATA = 1
function List:Initialize(parent)
	self.parent = parent
	local function BuildRow(control, data)
		local label = GetControl(control, "Label")
		label:SetText(data.name)
		control:SetHandler("OnMouseEnter", function() self:EnterRow(control) end)
		control:SetHandler("OnMouseExit", function() self:ExitRow(control) end)
		control:SetHandler("OnMouseUp",
		function(clickedControl, button)
			if (button == 2) then
				ClearMenu()
				AddMenuItem(GetString(BP_REMOVE), function()
					local idx = -1
					for i, filter in pairs(parent.filter) do
						if( filter == data.name ) then
							idx = i
							break
						end
					end

					if idx > 0 then
						table.remove(parent.filter, idx)
						self:RefreshData()
					end


				end)
				ShowMenu(control)
			end
		end)
	end

	ZO_ScrollList_SetHeight(self.list,200)
	ZO_ScrollList_AddDataType(self.list, LIST_DATA, "BackpackFilterListOptionsRow", 24, BuildRow)
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
	self:RefreshData()
end


function List:BuildMasterList()

	local scrollData = ZO_ScrollList_GetDataList(self.list)
	ZO_ClearNumericallyIndexedTable(scrollData)

	for i, name in pairs(self.parent.filter)do
		local entryData = {index = i, name = name }
		entryData.height = 24
		scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(LIST_DATA, entryData)
	end
	return scrollData
end

local FilterListOptions = ZO_Object:Subclass()
function FilterListOptions:New()
	local options = ZO_Object.New(self)
	options:Initialize()
	return options
end

function FilterListOptions:Initialize( )
	local control = CreateControlFromVirtual(CONTROL_NAME, GuiRoot,TEMPLATE)
	assert(control)
	self.control = control
	self.filter = {}
	self.list = List:New(GetControl(control, "Filter"), self)
	GetControl(control, "Add"):SetHandler("OnClicked", function() self:ShowAddMenu() end)
	GetControl(control, "Remove"):SetHandler("OnClicked", function() self:ShowRemoveMenu() end)
	self.operator = ZO_ComboBox:New(GetControl(control, "OperatorDropDown"))
	local entries = {}
	for i, op in pairs(backpack.filter.FILTER_FACTORY.BOOLEAN_OPS) do
		local entry = self.operator:CreateItemEntry(i, function() self.op = op end)
		entries[op] = entry
		self.operator:AddItem(entry)
	end
	self.entries = entries
	self.operator:SelectItem(entries[backpack.filter.FILTER_FACTORY.BOOLEAN_OPS.AND])
end

function FilterListOptions:ShowAddMenu()
	ClearMenu()
	for name, data in pairs(BACKPACK.settings.filter) do
		if(name ~= self.filterName) then
			AddMenuItem(name,
			function()
				local exists = false
				for i, filter in pairs(self.filter) do
					if filter == name  then
						exists = true
						break
					end
				end

				if not exists then
					table.insert(self.filter, name)
					self.list:RefreshData()
				end
			end
			)

		end
	end

	ShowMenu()
end

function FilterListOptions:ShowRemoveMenu()
	ClearMenu()
	for i, filter in pairs(self.filter) do
		AddMenuItem(filter,
		function()
			self.filter[i] = nil
			self.list:RefreshData()
		end
		)
	end
	ShowMenu()
end
function FilterListOptions:SetOptions( options, dialog )
	self.filterName = dialog:GetFilterName()

	if(options) then
		if options.filter then
			self.filter = options.filter
			self.list:RefreshData()
		end

		if options.op then
			self.op = options.op
			local entry = self.entries[self.op]
			self.operator:SelectItem(entry)
		end
	end
end

function FilterListOptions:GetOptions()
	return {
		filter=self.filter,
		op = self.op
	}
end

backpack.ui.filter.FILTER_OPTIONS_FACTORY:Register(backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterList,  FilterListOptions:New())
assert(backpack.ui.filter.FILTER_OPTIONS_FACTORY:GetOptions(backpack.filter.FILTER_FACTORY.FILTER_TYPES.FilterList))