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

VToolkit.Skins = {}

function VToolkit:RegisterSkin(name, skin)
	self.Skins[name] = skin
end

for i,k in pairs(file.Find("vtoolkit/skins/*.lua", "LUA")) do
	Vermilion.Log("Loading skin: " .. k)
	local func = CompileFile("vtoolkit/skins/" .. k)
	if(isfunction(func)) then
		if(SERVER) then 
			AddCSLuaFile("vtoolkit/skins/" .. k)
		else
			func()
		end
	end
end

if(SERVER) then return end

-- Patches
local PanelMeta = FindMetaTable("Panel")

function PanelMeta:GetX()
	return select(1, self:GetPos())
end

function PanelMeta:GetY()
	return select(2, self:GetPos())
end


local function newNotifyFormula(x)
	if(x < 0) then
		return math.pow(2, 5 * x)
	else
		return 1 + ((10 * math.sin(2 * (x + 1) * math.pi)) / (math.exp(3 * (x + 1))))
	end
end

VToolkit.NotificationAnim = Derma_Anim("VToolkit_SizeBounce", nil, function(panel, anim, delta, data)
	if((data.Done or data.Pos >= 2.1) and not data.FinishedN or anim.Finished) then
		panel:SetSize(panel.MaxW, panel.MaxH)
		if(isfunction(data.Callback)) then data.Callback(panel, anim, data) end
		data.FinishedN = true
		return
	elseif(data.FinishedN) then
		return
	end
	local change = 0
	if(data.Pos < 0) then
		change = delta / anim.Length
	else
		change = delta / (anim.Length * 4)
	end
	data.Pos = data.Pos + change
	local pos = data.Pos
	
	local num,finished = newNotifyFormula(pos, anim.Length)
	
	panel:SetSize(panel.MaxW * num, panel.MaxH * num)
	local addition = 5
	if(data.OnlyOne) then addition = 0 end
	panel:SetPos(150 - (panel:GetWide() / 2) , panel.IntendedY - (panel:GetTall() / 2) + addition )
	
	if(finished) then data.Done = true end
end)

function VToolkit:CreateNotificationAnimForPanel(panel)
	local copy = table.Copy(self.NotificationAnim)
	copy.Panel = panel
	return copy
end

VToolkit.Dark = true
CreateClientConVar("vtoolkit_skin", "Basic", true, false)



function VToolkit:GetActiveSkin()
	assert(GetConVarString("vtoolkit_skin") != nil, "Bad active skin!")
	assert(self.Skins[GetConVarString("vtoolkit_skin")] != nil, "No active skin!")
	return self.Skins[GetConVarString("vtoolkit_skin")]
end

function VToolkit:GetSkinComponent(typ)
	return self:GetActiveSkin()[typ]
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
		checkbox:SetDark(self.Dark)
	else
		if(initialValue == nil) then
			initialValue = GetConVarNumber(convar)
		end
		checkbox:SetText(text)
		checkbox:SetConVar(convar)
		checkbox:SetValue(initialValue)
		checkbox:SizeToContents()
		checkbox:SetDark(self.Dark)
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
		Vermilion.Log("Invalid size (" .. tostring(size) .. ") for AvatarImage!")
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

function VToolkit:CreateTextbox(text)
	text = text or ""
	local textbox = vgui.Create("DTextEntry")
	textbox.PlaceholderText = nil
	function textbox:SetPlaceholderText(text)
		self.PlaceholderText = text
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

function VToolkit:CreatePanel(props)
	local panel = vgui.Create("DPanel")
	if(props['size'] != nil) then
		panel:SetSize(props['size'][1], props['size'][2])
	end
	if(props['pos'] != nil) then
		panel:SetPos(props['pos'][1], props['pos'][2])
	end
	if(self:GetSkinComponent("WindowPanel") != nil) then
		if(self:GetSkinComponent("WindowPanel").Config != nil) then
			self:GetSkinComponent("WindowPanel").Config(panel)
		end
		panel.OldPaint = panel.Paint
		if(self:GetSkinComponent("WindowPanel").Paint != nil) then
			panel.Paint = self:GetSkinComponent("WindowPanel").Paint
		end
	end
	return panel
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
	
	return panel
end

function VToolkit:CreateErrorDialog(text)
	return self:CreateDialog("Error", text)
end

function VToolkit:CreateComboboxPanel(text, choices, selected, completeFunc) // This can sometimes fall behind the VMenu and get lost... Fix it!
	local panel = self:CreateFrame(
		{
			['size'] = { 500, 115 },
			['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 50 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Select an Option",
			['bgBlur'] = true
		}
	)
	panel:MakePopup()
	--panel:DoModal()
	--panel:SetDrawOnTop(true)
	panel:SetAutoDelete(true)
	
	self:SetDark(false)
	local textLabel = self:CreateLabel(text)
	textLabel:SizeToContents()
	textLabel:SetPos(250 - (textLabel:GetWide() / 2), 30)
	textLabel:SetParent(panel)
	textLabel:SetBright(true)
	
	local combo = VToolkit:CreateComboBox(choices, selected)
	combo:SetPos(10, 55)
	combo:SetSize(panel:GetWide() - 20, 25)
	combo:SetParent(panel)

	local confirmButton = self:CreateButton("OK", function(self)
		completeFunc(combo:GetValue())
		panel:Close()
	end)
	confirmButton:SetPos(255, 90)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	
	local cancelButton = self:CreateButton("Cancel", function(self)
		panel:Close()
	end)
	cancelButton:SetPos(145, 90)
	cancelButton:SetSize(100, 20)
	cancelButton:SetParent(panel)
	
	return panel
end

function VToolkit:CreateConfirmDialog(text, completeFunc, options)
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
	
	local confirmText = "OK"
	local denyText = "Cancel"
	
	if(istable(options)) then
		confirmText = options.Confirm or confirmText
		denyText = options.Deny or denyText
	end
	
	local confirmButton = self:CreateButton(confirmText, function(self)
		completeFunc()
		panel:Close()
	end)
	confirmButton:SetPos(255, 75)
	confirmButton:SetSize(100, 20)
	confirmButton:SetParent(panel)
	
	local cancelButton = self:CreateButton(denyText, function(self)
		panel:Close()
	end)
	cancelButton:SetPos(145, 75)
	cancelButton:SetSize(100, 20)
	cancelButton:SetParent(panel)
	
	panel.OldThink = panel.Think
	function panel:Think()
		if(istable(options)) then
			if(options.Default != nil) then
				if(options.Default) then
					confirmButton:SetAlpha(255 * (0.5 + math.Clamp(math.sqrt(math.pow(math.sin(CurTime() * 2.5), 2)), 0, 0.5)))
				else
					cancelButton:SetAlpha(255 * (0.5 + math.Clamp(math.sqrt(math.pow(math.sin(CurTime() * 2.5), 2)), 0, 0.5)))
				end
			end
		end
		if(isfunction(self.OldThink)) then self:OldThink() end
	end
	
	self:SetDark(true)
	
	return panel
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
	return panel
end

function VToolkit:CreateList(cols, multiselect, sortable, colrunner)
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
		local colimpl = lst:AddColumn(col)
		if(isfunction(colrunner)) then
			colrunner(i, colimpl)
		end
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
	
	listView.OldAddLine = listView.AddLine
	function listView:AddLine(...)
		local ln = self:OldAddLine(...)
		for i1,k1 in pairs(listView.Columns) do
			if(string.find(string.lower(ln:GetValue(i1)), string.lower(box:GetValue()), 0, true)) then
				ln:SetVisible(true)
				break
			else
				ln:SetVisible(false)
				break
			end
		end
		return ln
	end
	
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
					if(string.find(string.lower(k:GetValue(i1)), string.lower(val), 0, true)) then
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