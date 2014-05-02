BackpackSearchbox = ZO_Object:Subclass();

function BackpackSearchbox:New()
	local obj = ZO_Object.New(self);
	obj.fragment = nil;
	obj.control = nil;
	obj:Initialize();
	return obj;
end

function BackpackSearchbox:Initialize(  )
	local name = "BackpackSearchbox"
	local control = CreateTopLevelWindow(name)
	control:SetDimensions(400, 150)
	control:SetAnchor(BOTTOM, GuiRoot, BOTTOM, 0, -100)
	control:SetMouseEnabled(true)
	control:SetMovable(true)

	local background = CreateControlFromVirtual(name.."Background", control, "ZO_DefaultBackdrop")
	--background:SetColor(0, 0, 0)
	background:SetAnchorFill(control)
	control.background = background
	
	control.title = CreateControl(name.."Title", control, CT_LABEL )
	control.title:SetFont("ZoFontWinH1")
	control.title:SetText("SEARCH");
	control.title:SetAnchor(TOP, control, TOP, 0, 10);

	control.divider = CreateControl(name.."Divider", control, CT_TEXTURE);
	control.divider:SetTexture("EsoUI/Art/Miscellaneous/horizontalDivider.dds")
	control.divider:SetHeight(6);
	control.divider:SetAnchor(LEFT, control, TOPLEFT, -10, 50);
	control.divider:SetAnchor(RIGHT, control, TOPRIGHT, 10, 50);

	local editboxContainer = CreateControl(name.."EditboxContainer", control, CT_CONTROL)
	editboxContainer:SetAnchor(TOPLEFT, control.divider, BOTTOMLEFT)
	editboxContainer:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT)
	local editbox = CreateControlFromVirtual(name.."Editbox", editboxContainer, "ZO_DefaultEditForBackdrop")
	editbox:SetWidth(300)

	editbox:SetFont("ZoFontWinH1")
	editbox:SetHeight(editbox:GetFontHeight())
	editbox:ClearAnchors();
	editbox:SetAnchor(CENTER);
	--editbox:SetText("Search");

	editbox.background = CreateControlFromVirtual(name.."EditboxBackground", editbox, "ZO_EditBackdrop")
	--editbox.background:SetColor(1, 0, 0, 1)
	editbox.background:SetAnchorFill(editbox);
	control.editbox = editbox;
	control:SetHidden(true);

	self.control = control
	self.fragment = ZO_FadeSceneFragment:New(control);
end

