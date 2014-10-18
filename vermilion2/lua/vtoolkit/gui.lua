--[[
 Copyright 2014 Ned Hyett

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 in compliance with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License
 is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 or implied. See the License for the specific language governing permissions and limitations under
 the License.
 
 The right to upload this project to the Steam Workshop (which is operated by Valve Corporation) 
 is reserved by the original copyright holder, regardless of any modifications made to the code,
 resources or related content. The original copyright holder is not affiliated with Valve Corporation
 in any way, nor claims to be so. 
]]

VToolkit.Dark = true
VToolkit.Skins = {}
VToolkit.ActiveSkin = "Basic"

function VToolkit:RegisterSkin(name, skin)
	self.Skins[name] = skin
end

function VToolkit:GetActiveSkin()
	assert(self.ActiveSkin != nil, "Bad active skin!")
	assert(self.Skins[self.ActiveSkin] != nil, "No active skin!")
	return self.Skins[self.ActiveSkin]
end

function VToolkit:GetSkinComponent(typ)
	return self:GetActiveSkin()[typ]
end

for i,k in pairs(file.Find("vtoolkit/skins/*.lua", "LUA")) do
	print("Loading skin: " .. k)
	local func = CompileFile("vtoolkit/skins/" .. k)
	if(isfunction(func)) then
		if(SERVER) then 
			AddCSLuaFile("vtoolkit/skins/" .. k)
		end
		func()
	end
end

function VToolkit:SetDark(dark)
	self.Dark = dark
end

function VToolkit:CreateLabel(text)
	local label = vgui.Create("DLabel")
	label:SetText(text)
	label:SizeToContents()
	label:SetDark(self.Dark)
	if(self:GetSkinComponent("Label") != nil) then
		if(self:GetSkinComponent("Label").Config != nil) then
			self:GetSkinComponent("Label").Config(label)
		end
		label.OldPaint = label.Paint
		if(self:GetSkinComponent("Label").Paint != nil) then
			label.Paint = self:GetSkinComponent("Label").Paint
		end
	end
	return label
end

function VToolkit:CreateHeaderLabel(object, text)
	local label = self:CreateLabel(text)
	local ox, oy = object:GetPos()
	local xpos = ((object:GetWide() / 2) + ox) - (label:GetWide() / 2)
	local ypos = oy - 20
	label:SetPos(xpos, ypos)
	label.OldSetText = label.SetText
	function label:SetText(text)
		label:OldSetText(text)
		label:SizeToContents()
		local xpos = ((object:GetWide() / 2) + ox) - (label:GetWide() / 2)
		local ypos = oy - 20
		label:SetPos(xpos, ypos)
		end
	return label
end

function VToolkit:CreateComboBox(options, selected)
	local cbox = vgui.Create("DComboBox")
	options = options or {}
	for i,k in pairs(options) do
		cbox:AddChoice(k)
	end
	if(isnumber(selected)) then
		cbox:ChooseOptionID(selected)
	end
	if(self:GetSkinComponent("ComboBox") != nil) then
		if(self:GetSkinComponent("ComboBox").Config != nil) then
			self:GetSkinComponent("ComboBox").Config(cbox)
		end
		cbox.OldPaint = cbox.Paint
		if(self:GetSkinComponent("ComboBox").Paint != nil) then
			cbox.Paint = self:GetSkinComponent("ComboBox").Paint
		end
	end
	return cbox
end

function VToolkit:CreateCheckBox(text, convar, initialValue)
	local checkbox = vgui.Create("DCheckBoxLabel")
	if(convar == nil) then
		checkbox:SetText(text)
		checkbox:SizeToContents()
		checkbox:SetDark(Crimson.Dark)
	else
		if(initialValue == nil) then
			initialValue = GetConVarNumber(convar)
		end
		checkbox:SetText(text)
		checkbox:SetConVar(convar)
		checkbox:SetValue(initialValue)
		checkbox:SizeToContents()
		checkbox:SetDark(Crimson.Dark)
	end
	if(self:GetSkinComponent("Checkbox") != nil) then
		if(self:GetSkinComponent("Checkbox").Config != nil) then
			self:GetSkinComponent("Checkbox").Config(checkbox)
		end
		checkbox.Button.OldPaint = checkbox.Button.Paint
		if(self:GetSkinComponent("Checkbox").Paint != nil) then
			checkbox.Button.Paint = self:GetSkinComponent("Checkbox").Paint
		end
	end
	checkbox.OldSetDisabled = checkbox.SetDisabled
	function checkbox:SetDisabled(mode)
		self:SetEnabled(not mode)
		self:OldSetDisabled(mode)
	end
	checkbox.Button.OldToggle = checkbox.Button.Toggle
	function checkbox.Button:Toggle()
		if(not checkbox:GetDisabled()) then
			self:OldToggle()
		end
	end
	return checkbox
end

function VToolkit:CreateAvatarImage(vplayer, size)
	local sizes = { 16, 32, 64, 84, 128, 184 }
	if(not table.HasValue(sizes, size)) then
		print("Invalid size (" .. tostring(size) .. ") for AvatarImage!")
		return
	end
	local aimg = vgui.Create("AvatarImage")
	aimg:SetSize(size, size)
	if(not isstring(vplayer)) then
		aimg:SetPlayer(vplayer, size)
	else
		aimg:SetSteamID(util.SteamIDTo64(vplayer), size)
	end
	return aimg
end

function VToolkit:CreateColourMixer(palette, alpha, wangs, defaultColour, valueChangedFunc)
	local mixer = vgui.Create("DColorMixer")
	mixer:SetPalette(palette)
	mixer:SetAlphaBar(alpha)
	mixer:SetWangs(wangs)
	mixer:SetColor(defaultColour)
	mixer.ValueChanged = valueChangedFunc
	if(self:GetSkinComponent("ColourMixer") != nil) then
		if(self:GetSkinComponent("ColourMixer").Config != nil) then
			self:GetSkinComponent("ColourMixer").Config(mixer)
		end
		mixer.OldPaint = mixer.Paint
		if(self:GetSkinComponent("ColourMixer").Paint != nil) then
			mixer.Paint = self:GetSkinComponent("ColourMixer").Paint
		end
	end
	return mixer
end

function VToolkit:CreateButton(text, onClick)
	local button = vgui.Create("DButton")
	button:SetText(text)
	button:SetDark(self.Dark)
	button.DoClick = function()
		if(not button:GetDisabled()) then onClick() end
	end
	button.OldDisabled = button.SetDisabled
	function button:SetDisabled(is)
		self:SetEnabled(not is)
		self:OldDisabled(is)
	end
	if(self:GetSkinComponent("Button") != nil) then
		if(self:GetSkinComponent("Button").Config != nil) then
			self:GetSkinComponent("Button").Config(button)
		end
		button.OldPaint = button.Paint
		if(self:GetSkinComponent("Button").Paint != nil) then
			button.Paint = self:GetSkinComponent("Button").Paint
		end
	end
	return button 
end

function VToolkit:CreateBinder()
	return vgui.Create("DBinder")
end

function VToolkit:CreateNumberWang(min, max)
	local wang = vgui.Create("DNumberWang")
	wang:SetMinMax(min, max)
	if(self:GetSkinComponent("NumberWang") != nil) then
		if(self:GetSkinComponent("NumberWang").Config != nil) then
			self:GetSkinComponent("NumberWang").Config(wang)
		end
		wang.OldPaint = wang.Paint
		if(self:GetSkinComponent("NumberWang").Paint != nil) then
			wang.Paint = self:GetSkinComponent("NumberWang").Paint
		end
	end
	return wang
end

function VToolkit:CreateSlider(text, min, max, decimals, convar)
	local slider = vgui.Create("DNumSlider")
	slider:SetText(text)
	slider:SetMin(min)
	slider:SetMax(max)
	slider:SetDecimals(decimals)
	slider:SetConVar(convar)
	slider:SetDark(self.Dark)
	return slider
end

function VToolkit:CreateTextbox(text, panel, convar)
	text = text or ""
	local textbox = vgui.Create("DTextEntry")
	if(panel == nil) then
		panel = {}
		function panel:GetWide()
			return 0
		end
	end
	if(convar == nil) then
		textbox:SetSize(panel:GetWide(), 35)
		textbox:SetText(text)
		return textbox
	else
		textbox:SetSize( panel:GetWide(), 35 )
		textbox:SetText( text )
		textbox.OnEnter = function( self )
			RunConsoleCommand(convar, self:GetValue())
		end
	end
	textbox.OldPaint = textbox.Paint
	if(self:GetSkinComponent("Textbox") != nil) then
		if(self:GetSkinComponent("Textbox").Config != nil) then
			self:GetSkinComponent("Textbox").Config(textbox)
		end
		textbox.OldPaint = textbox.Paint
		if(self:GetSkinComponent("Textbox").Paint != nil) then
			textbox.Paint = self:GetSkinComponent("Textbox").Paint
		end
	end
	return textbox
end

function VToolkit:CreateFrame(props)
	local panel = vgui.Create("DFrame")
	if(props['size'] != nil) then
		panel:SetSize(props['size'][1], props['size'][2])
	end
	if(props['pos'] != nil) then
		panel:SetPos(props['pos'][1], props['pos'][2])
	end
	if(props['closeBtn'] != nil) then
		panel:ShowCloseButton(props['closeBtn'])
	end
	if(props['draggable'] != nil) then
		panel:SetDraggable(props['draggable'])
	end
	panel:SetTitle(props['title'])
	if(props['bgBlur'] != nil) then
		panel:SetBackgroundBlur(props['bgBlur'])
	end
	if(self:GetSkinComponent("Frame") != nil) then
		if(self:GetSkinComponent("Frame").Config != nil) then
			self:GetSkinComponent("Frame").Config(panel)
		end
		panel.OldPaint = panel.Paint
		if(self:GetSkinComponent("Frame").Paint != nil) then
			panel.Paint = self:GetSkinComponent("Frame").Paint
		end
	end
	return panel
end

function VToolkit:CreateDialog(title, text)
	local panel = self:CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - " .. title,
			['bgBlur'] = true
		}
	)
	panel:MakePopup()
	panel:DoModal()
	panel:SetAutoDelete(true)
	
	
	
	self:SetDark(false)
	local textLabel = self:CreateLabel(text)
	textLabel:SizeToContents()
	textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
	textLabel:SetParent(panel)
	textLabel:SetBright(true)
	
	local confirmButton = self:CreateButton("OK", function(self)
		panel:Close()
	end)
	confirmButton:SetPos(200, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	self:SetDark(true)
end

function VToolkit:CreateErrorDialog(text)
	self:CreateDialog("Error", text)
end

function VToolkit:CreateConfirmDialog(text, completeFunc)
	local panel = self:CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Confirm",
			['bgBlur'] = true
		}
	)
	panel:MakePopup()
	panel:DoModal()
	panel:SetAutoDelete(true)
	
	self:SetDark(false)
	local textLabel = self:CreateLabel(text)
	textLabel:SizeToContents()
	textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
	textLabel:SetParent(panel)
	textLabel:SetBright(true)
	
	local confirmButton = self:CreateButton("OK", function(self)
		completeFunc()
		panel:Close()
	end)
	confirmButton:SetPos(255, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	
	local cancelButton = self:CreateButton("Cancel", function(self)
		panel:Close()
	end)
	cancelButton:SetPos(145, 75)
	cancelButton:SetSize(100, 20)
	cancelButton:SetParent(panel)
	
	self:SetDark(true)
end

function VToolkit:CreateTextInput(text, completeFunc)
	local panel = self:CreateFrame(
		{
			['size'] = { 500, 100 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Text Entry Required",
			['bgBlur'] = true
		}
	)
	panel:MakePopup()
	panel:DoModal()
	panel:SetAutoDelete(true)
	
	self:SetDark(false)
	local textLabel = self:CreateLabel(text)
	textLabel:SizeToContents()
	textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
	textLabel:SetParent(panel)
	textLabel:SetBright(true)
	
	local textbox = self:CreateTextbox("", panel)
	textbox:SetPos( 10, 50 )
	textbox:SetSize( panel:GetWide() - 20, 20 )
	textbox:SetParent(panel)
	textbox.OnEnter = function(self)
		completeFunc(self:GetValue())
		panel:Close()
	end
	
	local confirmButton = self:CreateButton("OK", function(self)
		completeFunc(textbox:GetValue())
		panel:Close()
	end)
	confirmButton:SetPos(255, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	
	local cancelButton = self:CreateButton("Cancel", function(self)
		panel:Close()
	end)
	cancelButton:SetPos(145, 75)
	cancelButton:SetSize(100, 20)
	cancelButton:SetParent(panel)
	
	self:SetDark(true)
end

function VToolkit:CreateList(cols, multiselect, sortable)
	if(sortable == nil) then sortable = true end
	if(multiselect == nil) then multiselect = true end
	local lst = vgui.Create("DListView")
	function lst:DataLayout()
		local y = 0
		local h = self.m_iDataHeight
		local counter = 1
		for k,ln in ipairs(self.Sorted) do
			if(not ln:IsVisible()) then continue end
			ln:SetPos(1, y)
			ln:SetSize(self:GetWide() - 2, h)
			ln:DataLayout(self)
			ln:SetAltLine(counter % 2 == 1)
			y = y + ln:GetTall()
			counter = counter + 1
		end
		return y
	end
	lst:SetMultiSelect(multiselect)
	for i,col in pairs(cols) do
		lst:AddColumn(col)
	end
	if(not sortable) then
		lst:SetSortable(false)
		function lst:SortByColumn(ColumnID, Desc) end
	end
	if(self:GetSkinComponent("ListView") != nil) then
		if(self:GetSkinComponent("ListView").Config != nil) then
			self:GetSkinComponent("ListView").Config(lst)
		end
		lst.OldPaint = lst.Paint
		if(self:GetSkinComponent("ListView").Paint != nil) then
			lst.Paint = self:GetSkinComponent("ListView").Paint
		end
	end
	return lst
end

function VToolkit:CreatePropertySheet()
	local sheet = vgui.Create("DPropertySheet")
	if(self:GetSkinComponent("PropertySheet") != nil) then
		if(self:GetSkinComponent("PropertySheet").Config != nil) then
			self:GetSkinComponent("PropertySheet").Config(sheet)
		end
		sheet.OldPaint = sheet.Paint
		if(self:GetSkinComponent("PropertySheet").Paint != nil) then
			sheet.Paint = self:GetSkinComponent("PropertySheet").Paint
		end
	end
	return sheet
end

function VToolkit:CreateCategoryList()
	local lst = vgui.Create("DCategoryList")
	lst.OldAdd = lst.Add
	function lst:Add(str) -- allows the headers to be re-skinned
		local btn = self:OldAdd(str)
		if(VToolkit:GetSkinComponent("CollapsibleCateogryHeader") != nil) then
			if(VToolkit:GetSkinComponent("CollapsibleCateogryHeader").Config != nil) then
				VToolkit:GetSkinComponent("CollapsibleCateogryHeader").Config(btn)
			end
			btn.OldPaint = btn.Paint
			if(VToolkit:GetSkinComponent("CollapsibleCateogryHeader").Paint != nil) then
				btn.Paint = VToolkit:GetSkinComponent("CollapsibleCateogryHeader").Paint
			end
		end
		return btn
	end
	if(self:GetSkinComponent("CategoryList") != nil) then
		if(self:GetSkinComponent("CategoryList").Config != nil) then
			self:GetSkinComponent("CategoryList").Config(lst)
		end
		lst.OldPaint = lst.Paint
		if(self:GetSkinComponent("CategoryList").Paint != nil) then
			lst.Paint = self:GetSkinComponent("CategoryList").Paint
		end
	end
	return lst
end

function VToolkit:CreateSearchBox(listView, changelogic)
	local box = self:CreateTextbox()
	box:SetUpdateOnType(true)
	box:SetTall(25)
	
	changelogic = changelogic or function()
		local val = box:GetValue()
		if(val == "" or val == nil) then
			for i,k in pairs(listView:GetLines()) do
				k:SetVisible(true)
			end
			listView:SetDirty( true )
			listView:InvalidateLayout()
		else
			for i,k in pairs(listView:GetLines()) do
				local visible = false
				for i1,k1 in pairs(listView.Columns) do
					if(string.find(string.lower(k:GetValue(i1)), string.lower(val))) then
						k:SetVisible(true)
						visible = true
						break
					end
				end
				if(not visible) then
					k:SetVisible(false)
				end
			end
			listView:SetDirty( true )
			listView:InvalidateLayout()
		end
	end
	
	box.OnChange = changelogic
	
	
	local searchLogo = vgui.Create("DImage")
	searchLogo:SetParent(box)
	searchLogo:SetPos(box:GetWide() - 25, 5)
	searchLogo:SetImage("icon16/magnifier.png")
	searchLogo:SizeToContents()
	
	box.OldSetWide = box.SetWide
	function box:SetWide(val)
		box:OldSetWide(val)
		searchLogo:SetPos(box:GetWide() - 25, 5)
	end
	
	listView:SetTall(listView:GetTall() - 35)

	box:SetParent(listView:GetParent())
	box:SetPos(select(1, listView:GetPos()), select(2, listView:GetPos()) + listView:GetTall() + 10)
	box:SetWide(listView:GetWide())
	
	return box
end

function VToolkit:CreatePreviewPanel(typ, parent, move)
	local PreviewPanel = vgui.Create("DPanel")
	local x,y = input.GetCursorPos()
	PreviewPanel:SetPos(x - 250, y - 64)
	PreviewPanel:SetSize(148, 148)
	PreviewPanel:SetParent(parent)
	PreviewPanel:SetDrawOnTop(true)
	PreviewPanel:SetVisible(false)
	
	if(typ == "model") then
		move = move or function() end
		local dmodel = vgui.Create("DModelPanel")
		dmodel:SetPos(10, 10)
		dmodel:SetSize(128, 128)
		dmodel:SetParent(PreviewPanel)
		function dmodel:LayoutEntity(ent)
			ent:SetAngles(Angle(0, RealTime() * 80, 0))
			move(ent)
		end
					
		PreviewPanel.ModelView = dmodel
	elseif(typ == "html") then
		local dhtml = vgui.Create("DHTML")
		dhtml:SetPos(10, 10)
		dhtml:SetSize(128, 128)
		dhtml:SetParent(PreviewPanel)
		
		PreviewPanel.HtmlView = dhtml
	end
	
	
	return PreviewPanel
end