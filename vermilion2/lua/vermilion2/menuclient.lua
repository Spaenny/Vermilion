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

--[[
	HUD Components:
	1	=	NetGraph
	2	=	CHudDeathNotice
	3	=	CHudChat
	4	=	CHudWeaponSelection
	5	=	CHudHealth
	6	=	CHudSecondaryAmmo
	7	=	CHudAmmo
	8	=	CHudGMod
	9	=	CHudTrain
	10	=	CHudMessage
	11	=	CHudMenu
	12	=	CHudWeapon
	13	=	CHudHintDisplay
	14	=	CHudCrosshair

]]--

Vermilion.Menu = {}
Vermilion.Menu.Categories = {}
Vermilion.Menu.Pages = {}
Vermilion.Menu.Built = false

function Vermilion.Menu:AddCategory(id, order)
	local has = false
	for index,data in pairs(self.Categories) do
		if(data.ID == id) then
			has = true
			break
		end
	end
	if(has) then return end
	table.insert(self.Categories, { ID = id, Name = Vermilion:TranslateStr("category:" .. id), Order = order })
end

function Vermilion.Menu:AddPage(data)
	local mustHave = { "ID", "Name", "Order", "Category", "Size" }
	local shouldHave = { 
		{ "Conditional", function() return true end },
		{ "Builder", function() end },
		{ "Destroyer", function() end },
		{ "Updater", function() end }
	}
	for i,k in pairs(mustHave) do
		assert(data[k] != nil, "Page missing required component!")
	end
	for i,k in pairs(shouldHave) do
		if(data[k[1]] == nil) then data[k[1]] = k[2] end
	end
	local has = false
	for index,cat in pairs(self.Categories) do
		if(cat.ID == data.Category) then
			has = true
			break
		end
	end
	if(not has) then
		Vermilion.Log("Warning: no such category " .. data.Category .. " exists (registering page: " .. data.ID .. ")!")
		return
	end
	if(data.Size[1] > ScrW() - 200 or data.Size[2] > ScrH() - 10) then
		Vermilion.Log("Uh oh... It appears that your screen resolution is too small to display a tab on the menu...")
		Vermilion.Log("Recommended minimum resolution: 1366x768")
		Vermilion.Log("You have: " .. tostring(ScrW()) .. "x" .. tostring(ScrH()))
	end
	self.Pages[data.ID] = data
end

function Vermilion.Menu:GetActivePage()
	return self.Pages[self.ActiveTab]
end

function Vermilion.Menu:GetCategory(name)
	for index,cat in pairs(self.Categories) do
		if(cat.Name == name) then return cat end
	end
end

function Vermilion.Menu:GetCategoryID(id)
	for index,cat in pairs(self.Categories) do
		if(cat.ID == id) then return cat end
	end
end

local MENU = Vermilion.Menu
MENU.IsOpen = false
MENU.ActiveTab = "welcome"

MENU:AddCategory("basic", 1)

MENU:AddPage({
	ID = "welcome",
	Name = "Welcome",
	Order = -9000,
	Category = "basic",
	Size = { 580, 560 },
	Builder = function(panel)
		local welcomeLabel = VToolkit:CreateLabel("Welcome to Vermilion!")
		welcomeLabel:SetFont("DermaLarge")
		welcomeLabel:SizeToContents()
		welcomeLabel:SetPos((580 - welcomeLabel:GetWide()) / 2, 30)
		welcomeLabel:SetParent(panel)
		
		local message = vgui.Create("DTextEntry")
		message:SetDrawBackground(false)
		message:SetMultiline(true)
		message:SetPos(10, 90)
		message:SetSize(560, 400)
		message:SetParent(panel)
		message:SetValue([[
			Vermilion is currently in heavy development. Expect things to be broken!
			
			Changelog:
			
			- TBA
		]])
		message:SetEditable(false)
	end
})

MENU:AddPage({
	ID = "modules",
	Name = "Modules",
	Order = 1,
	Category = "basic",
	Size = { 700, 560 },
	Builder = function(panel, paneldata)
		local mlist = VToolkit:CreateList({
			cols = {
				"Name"
			}
		})
		mlist:Dock(LEFT)
		mlist:DockMargin(10, 10, 0, 10)
		mlist:SetParent(panel)
		mlist:SetWide(200)
		paneldata.ModuleList = mlist
		
		local infopanel = vgui.Create("DPanel")
		infopanel:SetDrawBackground(false)
		infopanel:Dock(FILL)
		infopanel:DockMargin(10, 10, 10, 10)
		infopanel:SetParent(panel)
		
		local title = VToolkit:CreateLabel("Click on a module...")
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:Dock(TOP)
		title:SetParent(infopanel)
		paneldata.TitleLabel = title
		
		local author = VToolkit:CreateLabel("")
		author:Dock(TOP)
		author:SetParent(infopanel)
		paneldata.AuthorLabel = author
		
		local enablerPanel = vgui.Create("DPanel")
		enablerPanel:SetParent(infopanel)
		enablerPanel:Dock(TOP)
		enablerPanel:SetTall(20)
		enablerPanel:DockMargin(0, 10, 0, 10)
		enablerPanel:SetDrawBackground(false)
		enablerPanel:SetVisible(false)

		paneldata.EnablerPanel = enablerPanel
		
		local enableCB = VToolkit:CreateCheckBox("Enabled")
		enableCB:Dock(FILL)
		enableCB:SetParent(enablerPanel)
		enableCB.CanUpdate = true
		function enableCB:OnChange(val)
			if(not self.CanUpdate) then return end
			net.Start("VModuleDataEnableChange")
			net.WriteString(self.ModuleID)
			net.WriteBoolean(val)
			net.SendToServer()
		end
		paneldata.EnableCB = enableCB
		
		
		local description = vgui.Create("DTextEntry")
		description:SetDrawBackground(false)
		description:SetMultiline(true)
		description:Dock(TOP)
		description:SetTall(50)
		description:DockMargin(0, 10, 0, 10)
		description:SetParent(infopanel)
		description:SetValue("")
		description:SetEditable(false)
		paneldata.Description = description
		
		
		
		
		local scrollp = vgui.Create("DScrollPanel")
		scrollp:SetParent(infopanel)
		scrollp:Dock(FILL)
		scrollp:DockMargin(0, 10, 0, 0)
		scrollp:SetVisible(false)
		
		net.Receive("VModuleDataUpdate", function()
			enableCB.CanUpdate = false
			enableCB:SetValue(net.ReadBoolean())
			enableCB.CanUpdate = true
		end)
		
	end,
	Updater = function(panel, paneldata)
		if(table.Count(paneldata.ModuleList:GetLines()) == 0) then
			for i,k in pairs(Vermilion.Modules) do
				local ln = paneldata.ModuleList:AddLine(k.Name)
				ln.OldClick = ln.OnMousePressed
				function ln:OnMousePressed(mc)
					paneldata.TitleLabel:SetText(k.Name)
					paneldata.TitleLabel:SizeToContents()
					
					paneldata.AuthorLabel:SetText("Author: " .. k.Author)
					paneldata.AuthorLabel:SizeToContents()
					
					paneldata.Description:SetValue(k.Description)
					paneldata.Description:SetEditable(false)
					
					paneldata.EnableCB.ModuleID = k.ID
					
					
					paneldata.EnablerPanel:SetVisible(Vermilion:HasPermission("*") and not k.PreventDisable)
					
					net.Start("VModuleDataUpdate")
					net.WriteString(k.ID)
					net.SendToServer()
					
					self:OldClick(mc)
				end
			end
			paneldata.ModuleList:SortByColumn(paneldata.ModuleList.Columns[1]:GetColumnID())
		end
	end
})

MENU:AddPage({
	ID = "api",
	Name = "API Documentation",
	Order = 10,
	Category = "basic",
	Size = { 600, 560 },
	Builder = function(panel)
		local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
		label:SetFont("DermaLarge")
		label:SizeToContents()
		label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
		label:SetParent(panel)
	end
})

MENU:AddPage({
	ID = "credits",
	Name = "Credits",
	Order = 50,
	Category = "basic",
	Size = { 600, 560 },
	Builder = function(panel)
		local title = VToolkit:CreateLabel("Vermilion Credits")
		title:SetFont("DermaLarge")
		title:SizeToContents()
		title:SetParent(panel)
		title:Dock(TOP)
		title:DockMargin((600 - title:GetWide()) / 2, 10, 0, 10)
		
		local scrollPanel = vgui.Create("DScrollPanel")
		scrollPanel:SetParent(panel)
		scrollPanel:Dock(FILL)
		
		local contributors = {
			{
				Name = "Ned",
				SteamID = "STEAM_0:0:44370296",
				Role = "Project Lead - Coding",
			},
			{
				Name = "Wheatley",
				SteamID = "STEAM_0:0:44277237",
				Role = "GUI Skin Designer"
			},
			{
				Name = "TehAngel",
				SteamID = "STEAM_0:1:79012222",
				Role = "Ideas, Persuasion and General Help"
			}
		}
		
		local size = 64
		
		for i,k in pairs(contributors) do
			local contributorPanel = vgui.Create("DPanel")
			contributorPanel:SetDrawBackground(false)
			contributorPanel:Dock(TOP)
			contributorPanel:DockPadding(10, 2, 10, 2)
			contributorPanel:SetParent(scrollPanel)
			contributorPanel:SetTall(68)
			
			local avb = vgui.Create("DButton")
			avb:SetSize(size, size)
			avb:SetParent(contributorPanel)
			avb:Dock(LEFT)
			avb:DockMargin(0, 0, 10, 0)
			
			local av = VToolkit:CreateAvatarImage(k.SteamID, size)
			av:SetParent(avb)
			av:SetMouseInputEnabled(false)
			
			function avb:DoClick(mc)
				gui.OpenURL("http://steamcommunity.com/profiles/" .. util.SteamIDTo64(k.SteamID))
			end
			
			av:SetCursor("hand")
			
			local dataPanel = vgui.Create("DPanel")
			dataPanel:SetTall(64)
			dataPanel:Dock(LEFT)
			dataPanel:DockPadding(0, 10, 0, 0)
			dataPanel:SetWide(300)
			dataPanel:SetParent(contributorPanel)
			dataPanel:SetDrawBackground(false)
			
			local name = vgui.Create("DLabel")
			steamworks.RequestPlayerInfo(util.SteamIDTo64(k.SteamID))
			timer.Simple(3, function()
				if(not IsValid(name)) then return end
				name:SetText(steamworks.GetPlayerName(util.SteamIDTo64(k.SteamID)))
				name:SizeToContents()
			end)
			name:SetText(k.Name)
			name:SetFont("DermaDefaultBold")
			name:SizeToContents()
			name:Dock(TOP)
			name:SetDark(true)
			name:SetParent(dataPanel)
			
			local role = vgui.Create("DLabel")
			role:SetText(k.Role)
			role:SizeToContents()
			role:Dock(TOP)
			role:SetDark(true)
			role:SetParent(dataPanel)
		end
		
		local thanks = VToolkit:CreateLabel("Thank you to anyone else who has contributed ideas and has supported Vermilion throughout development!")
		thanks:Dock(TOP)
		thanks:DockMargin(10, 10, 10, 10)
		thanks:SetParent(scrollPanel)
		thanks:SetDark(true)
		
		local poweredBySoundCloud = VToolkit:CreateLabel("Vermilion uses resources from the SoundCloud API. Use of the services provided by Vermilion that use the SoundCloud API constitutes acceptance of the SoundCloud API terms of use.")
		poweredBySoundCloud:Dock(TOP)
		poweredBySoundCloud:SetWrap(true)
		poweredBySoundCloud:SetTall(poweredBySoundCloud:GetTall() * 2)
		poweredBySoundCloud:DockMargin(10, 10, 10, 10)
		poweredBySoundCloud:SetParent(scrollPanel)
		poweredBySoundCloud:SetDark(true)
		
		local poweredByFGIP = VToolkit:CreateLabel("The GeoIP services in Vermilion are powered by freegeoip.net. freegeoip.net includes GeoLite data created by MaxMind, available from maxmind.com.")
		poweredByFGIP:Dock(TOP)
		poweredByFGIP:SetWrap(true)
		poweredByFGIP:SetTall(poweredByFGIP:GetTall() * 2)
		poweredByFGIP:DockMargin(10, 10, 10, 10)
		poweredByFGIP:SetParent(scrollPanel)
		poweredByFGIP:SetDark(true)
		
		
		local buttonBar = vgui.Create("DPanel")
		buttonBar:Dock(TOP)
		buttonBar:DockMargin(10, 10, 10, 10)
		buttonBar:SetParent(scrollPanel)
		buttonBar:SetTall(25)
		buttonBar:SetDrawBackground(false)
		
		local gotoWorkshop = VToolkit:CreateButton("Vermilion Workshop Page", function()
			steamworks.ViewFile("295053419")
		end)
		gotoWorkshop:Dock(LEFT)
		gotoWorkshop:SetSize(200, 25)
		gotoWorkshop:SetParent(buttonBar)
		
		local openGithub = VToolkit:CreateButton("GitHub Repository", function()
			gui.OpenURL("http://github.com/nedhyett/Vermilion")
		end)
		openGithub:Dock(RIGHT)
		openGithub:SetSize(200, 25)
		openGithub:SetParent(buttonBar)
		
		local openSteamGroup = VToolkit:CreateButton("Steam Group", function()
			gui.OpenURL("http://steamcommunity.com/groups/VSM-GMOD")
		end)
		openSteamGroup:Dock(TOP)
		openSteamGroup:SetSize(scrollPanel:GetWide(), 25)
		openSteamGroup:DockMargin(5, 0, 5, 0)
		openSteamGroup:SetParent(buttonBar)
		
	end
})


-- stop drawing netgraph or the ammo count if the menu is open
Vermilion:AddHook("HUDShouldDraw", "MenuClientHudDraw", false, function(name)
	if(name == "NetGraph" or name == "CHudAmmo") then
		if(MENU.IsOpen) then return false end
	end
end)

-- switch the menu tab
function MENU:ChangeTab(to, quiet)
	if(to == self.ActiveTab) then return end
	quiet = quiet or false
	if(not quiet) then
		if(hook.Run(Vermilion.Event.MENU_TAB, self.ActiveTab, to) == false) then return end
	end
	local oldName = self.ActiveTab
	assert(self.Pages[to] != nil)
	if(quiet) then
		self:GetActiveTab().Panel:SetVisible(false)
		self.Pages[to].Panel:SetVisible(true)
		self.ActiveTab = to
		self.CatList:UnselectAll()
		self:GetActivePage().TabButton:SetSelected(true)
		self.ContentPanel:SetSize(self:GetActivePage().Size[1] + 20, self:GetActivePage().Size[2] + 40)
	else
		local oldPage = self:GetActivePage()
		local newPage = self.Pages[to]
		oldPage.Panel:AlphaTo(0, 0.25, 0, function()
			oldPage.Panel:SetVisible(false)
			oldPage.Panel:SetAlpha(255)
			self.ActiveTab = to
			self.ContentPanel:SizeTo(newPage.Size[1] + 20, newPage.Size[2] + 40, 0.5, 0, -3, function()
				if(self.ActiveTab != to) then return end
				newPage.Panel:SetAlpha(0)
				newPage.Panel:SetVisible(true)
				newPage.Panel:AlphaTo(255, 0.25, 0, function()
					if(self.ActiveTab != to) then
						newPage.Panel:SetAlpha(255)
						newPage.Panel:SetVisible(false)
					end
				end)
			end)
		end)
	end
end

Vermilion:AddHook(Vermilion.Event.MOD_POST, "MenuClientBuild", true, function()
	-- assume that all modules have run their code to register their pages
	
	local categories = {}
	for index,catData in SortedPairsByMemberValue(MENU.Categories, "Order", false) do
		categories[catData.ID] = MENU.CatList:Add(catData.Name)
		catData.Impl = categories[catData.ID]
	end
	
	for index,pageData in SortedPairsByMemberValue(MENU.Pages, "Order", false) do
		local cat = categories[pageData.Category]
		local btn = cat:Add(pageData.Name)
		btn.OldDCI = btn.DoClickInternal
		btn.DoClickInternal = function()
			MENU:ChangeTab(pageData.ID)
			btn.OldDCI()
		end
		btn.TabID = pageData.ID
		MENU.Pages[pageData.ID].TabButton = btn
		
		local panel = vgui.Create("DPanel")
		panel:SetParent(MENU.ContentPanel)
		panel:SetSize(pageData.Size[1], pageData.Size[2])
		panel:SetPos(10, 30)
		if(pageData.ID != "welcome") then 
			panel:SetVisible(false)
		end
		
		MENU.Pages[pageData.ID].Panel = panel
		
		--pageData.Builder(panel)
		xpcall(pageData.Builder, function(err)
			Vermilion.Log("Error building page: " .. err)
			debug.Trace()
		end, panel, pageData)
		
		btn:SetVisible(pageData.Conditional(LocalPlayer()))
		
	end
	
	for i,k in pairs(categories) do		
		local visibleChildren = 0
		for i1,k1 in pairs(k:GetChildren()) do
			if(k1:IsVisible()) then visibleChildren = visibleChildren + 1 end
		end
		k:SetVisible(visibleChildren > 1)
	end
	
	MENU.Pages["welcome"].TabButton:SetSelected(true)
	MENU.Built = true
end)

Vermilion:AddHook(Vermilion.Event.CLIENT_GOT_RANKS, "UpdateMenuAccess", true, function()
	if(table.Count(MENU.Pages) == 0) then return end
	if(MENU.Pages["welcome"].TabButton == nil) then return end
	for i,k in pairs(MENU.Pages) do
		k.TabButton:SetVisible(k.Conditional(LocalPlayer()))
	end
	
	for i,k in pairs(MENU.Categories) do
		local visibleChildren = 0
		for i1,k1 in pairs(k.Impl:GetChildren()) do
			if(k1:IsVisible()) then visibleChildren = visibleChildren + 1 end
		end
		k.Impl:SetVisible(visibleChildren > 1)
	end
	if(not MENU:GetActivePage().TabButton:IsVisible()) then MENU:ChangeTab("welcome") end
end)



-- Build the base menu
timer.Simple(1, function()
	MENU.TabPanel = VToolkit:CreateFrame({
		size = { 170, 600 },
		pos = { -170, 10 },
		closeBtn = false,
		draggable = false,
		title = "",
		bgBlur = false
	})
	
	MENU.ContentPanel = VToolkit:CreateFrame({
		size = { 600, 600 },
		pos = { 200, ScrH() },
		closeBtn = true,
		draggable = false,
		title = "Vermilion Menu",
		bgBlur = false
	})
	
	MENU.ContentPanel.lblTitle.UpdateColours = function() end
	
	
	-- add a list thingy
	local catList = VToolkit:CreateCategoryList()
	catList:SetPos(5, 5)
	catList:SetSize(160, 590)
	catList:SetParent(MENU.TabPanel)
	
	MENU.CatList = catList
	
	MENU.TabPanel:SetVisible(false)
	MENU.ContentPanel:SetVisible(false)
	MENU.TabPanel:MakePopup()
	MENU.ContentPanel:MakePopup()

	function MENU.ContentPanel:Close()
		MENU:Close()
	end

	function MENU:Open()
		if(hook.Run(Vermilion.Event.MENU_OPENING) == false or MENU.IsOpen or not MENU.Built) then return end
		
		for i,k in pairs(MENU.Pages) do
			if(k.Conditional(LocalPlayer())) then
				xpcall(k.Updater, function(err)
					Vermilion.Log("Failed to update panel (" .. k.ID .. "): " .. err)
					debug.Trace()
				end, k.Panel, k)
			end
		end
		
		MENU.IsOpen = true
		MENU.TabPanel:SetVisible(true)
		MENU.ContentPanel:SetVisible(true)
		MENU.TabPanel:MoveTo(10, 10, 0.5, 0, -3)
		MENU.ContentPanel:MoveTo(200, 10, 0.5, 0, -3, function()
			MENU.TabPanel:SetKeyboardInputEnabled(true)
			MENU.ContentPanel:SetKeyboardInputEnabled(true)
			hook.Run(Vermilion.Event.MENU_OPEN)
		end)
	end

	function MENU:Close(force)
		if(not force and (hook.Run(Vermilion.Event.MENU_CLOSING) == false or not MENU.IsOpen)) then return end
		
		MENU.TabPanel:MoveTo(-170, 10, 0.5, 0, -3)
		MENU.ContentPanel:MoveTo(200, ScrH(), 0.5, 0, -3, function()
			MENU.TabPanel:SetVisible(false)
			MENU.ContentPanel:SetVisible(false)
			MENU.TabPanel:SetKeyboardInputEnabled(false)
			MENU.ContentPanel:SetKeyboardInputEnabled(false)
			MENU.IsOpen = false
			for i,k in pairs(MENU.Pages) do
				local suc, err = pcall(k.Destroyer, k.Panel, k)
				if(not suc) then print(err) end
			end
			hook.Run(Vermilion.Event.MENU_CLOSED)
		end)
	end

	concommand.Add("vermilion_menu", function()
		MENU:Open()
	end)
end)