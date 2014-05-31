---
-- TitleBar
local TitleBar = ZO_Object:Subclass()

function TitleBar:New(control)
	local obj = ZO_Object.New(self)
	obj:Initialize(control)
	return obj
end

function TitleBar:Initialize( control )
	self.control = control
	self.titleLabel = GetControl(control, "TitleLabel")
end

function TitleBar:SetTitle( title )
	self.titleLabel:SetText( title )
end

---
-- ContentPanel
local ContentPanel = ZO_Object:Subclass()

function ContentPanel:New(control)
	local obj = ZO_Object.New(self)
	obj:Initialize(control)
	return obj
end

function ContentPanel:Initialize(control)
end


---
-- Window
-- 
local Window = backpack.ui.Window:Subclass()
function Window:New(control)
	local obj = ZO_Object.New(self)
	obj:Initialize(control)
	return obj
end

function Window:Initialize(control)
	backpack.ui.Window.Initialize(self, control)

	self.titleBar = TitleBar:New(GetControl(control, "TitleBar"))
	self.contentPanel = ContentPanel:New(GetControl(control, "ContentPanel"))
end

function Window:SetTitle( title )
	self.titleBar:SetTitle(title)
end

--backpack.ui.group.Window = Window
--local control = CreateControlFromVirtual("GWTestWindow", GuiRoot, "GroupWindow")
--control:SetDimensions(300, 200)
--local bg = CreateControl("GWTestTexture", control, CT_TEXTURE)
--bg:SetColor(1, 1, 0, 1)
--bg:SetAnchorFill()
--backpack.GWTest = Window:New(control)
 