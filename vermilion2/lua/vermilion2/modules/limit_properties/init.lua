--[[
 Copyright 2014 Ned Hyett, 

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

local MODULE = Vermilion:CreateBaseModule()
MODULE.Name = "Property Limits"
MODULE.ID = "limit_properties"
MODULE.Description = "Prevent players from using certain right-click properties."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_property_limits"
}
MODULE.NetworkStrings = {
	"VGetPropertyLimits",
	"VBlockProperty",
	"VUnblockProperty",
	"VBuildEntityMenu"
}

function MODULE:InitServer()
	
	
	self:NetHook("VGetPropertyLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			MODULE:NetStart("VGetPropertyLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			MODULE:NetStart("VGetPropertyLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VBlockProperty", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_property_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), weapon)) then
				table.insert(MODULE:GetData(rnk, {}, true), weapon)
			end
		end
	end)
	
	self:NetHook("VUnblockProperty", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_property_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, {}, true), weapon)
		end
	end)
	
	self:NetHook("VBuildEntityMenu", function(vplayer)
		if(MODULE:GetData("enabled", 1, 3) == 1) then
			MODULE:NetStart("VBuildEntityMenu")
			net.WriteString(net.ReadString())
			net.WriteTable(table.GetKeys(properties.List))
			net.Send(vplayer)
			return
		end
		if(MODULE:GetData("enabled", 1, 3) == 2) then return end
		local tab = {}
		for i,k in pairs(properties.List) do
			if(not table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), k.InternalName)) then
				table.insert(tab, k.InternalName)
			end
		end
		MODULE:NetStart("VBuildEntityMenu")
		net.WriteString(net.ReadString()) -- send back the code to make sure that we really want to build this menu
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
end

function MODULE:InitClient()

	--[[
		These two functions are borrowed from the properties.lua file to facilitate building the contextual menu.
	]]--
	local function AddToggleOption( data, menu, ent, ply, tr )

		if ( !menu.ToggleSpacer ) then
			menu.ToggleSpacer = menu:AddSpacer()
			menu.ToggleSpacer:SetZPos( 500 )
		end

		local option = menu:AddOption( data.MenuLabel, function() data:Action( ent, tr ) end )
		option:SetChecked( data:Checked( ent, ply ) )
		option:SetZPos( 501 )
		return option

	end

	local function AddOption( data, menu, ent, ply, tr )

		if ( data.Type == "toggle" ) then return AddToggleOption( data, menu, ent, ply, tr ) end

		if ( data.PrependSpacer ) then 
			menu:AddSpacer()
		end

		local option = menu:AddOption( data.MenuLabel, function() data:Action( ent, tr ) end )

		if ( data.MenuIcon ) then
			option:SetImage( data.MenuIcon )
		end

		if ( data.MenuOpen ) then
			data.MenuOpen( data, option, ent, tr )
		end

		return option

	end
	
	local lent = nil
	local ltr = nil
	local code = nil
	
	self:NetHook("VBuildEntityMenu", function()
		local rcode = net.ReadString()
		if(rcode == code) then
			local menu = DermaMenu()
			local tab = net.ReadTable()
			for i,k in SortedPairsByMemberValue(properties.List, "Order") do
				if(not k.Filter) then continue end
				if(not k:Filter(lent, LocalPlayer())) then continue end
				if(not table.HasValue(tab, k.InternalName)) then continue end
				local option = AddOption(k, menu, lent, LocalPlayer(), ltr)
				if(k.OnCreate) then k:OnCreate(menu, option) end
			end
			menu:Open()
		end
	end)
	
	function properties.OpenEntityMenu(ent, tr)
		lent = ent
		ltr = tr
		code = tostring(math.Rand(0, 1000000))
		MODULE:NetStart("VBuildEntityMenu")
		net.WriteString(code)
		net.SendToServer()
	end

	self:NetHook("VGetPropertyLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_properties"].RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_properties"].RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_properties"].RankBlockList
		local props = Vermilion.Menu.Pages["limit_properties"].Properties
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(props) do
					if(k1.ClassName == k) then
						blocklist:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_properties",
			Name = "Properties",
			Order = 7,
			Category = "limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_property_limits")
			end,
			Builder = function(panel, paneldata)
				local blockProperty = nil
				local unblockProperty = nil
				local rankList = nil
				local allProperties = nil
				local rankBlockList = nil
			
				
				rankList = VToolkit:CreateList({
					cols = {
						"Name"
					},
					multiselect = false,
					sortable = false,
					centre = true
				})
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				paneldata.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					blockProperty:SetDisabled(not (self:GetSelected()[1] != nil and allProperties:GetSelected()[1] != nil))
					unblockProperty:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					MODULE:NetStart("VGetPropertyLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({
					cols = {
						"Name"
					}
				})
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(240, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				paneldata.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked Properties")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockProperty:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				
				allProperties = VToolkit:CreateList({
					cols = {
						"Name"
					}
				})
				allProperties:SetPos(panel:GetWide() - 250, 30)
				allProperties:SetSize(240, panel:GetTall() - 40)
				allProperties:SetParent(panel)
				paneldata.AllProperties = allProperties
				
				local allPropertiesHeader = VToolkit:CreateHeaderLabel(allProperties, "All Properties")
				allPropertiesHeader:SetParent(panel)
				
				function allProperties:OnRowSelected(index, line)
					blockProperty:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allProperties)
				
				
				blockProperty = VToolkit:CreateButton("Block Property", function()
					for i,k in pairs(allProperties:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankBlockList:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankBlockList:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						MODULE:NetStart("VBlockProperty")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				blockProperty:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 100)
				blockProperty:SetWide(panel:GetWide() - 20 - select(1, allProperties:GetWide()) - select(1, blockProperty:GetPos()))
				blockProperty:SetParent(panel)
				blockProperty:SetDisabled(true)
				
				unblockProperty = VToolkit:CreateButton("Unblock Property", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						MODULE:NetStart("VUnblockProperty")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockProperty:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 130)
				unblockProperty:SetWide(panel:GetWide() - 20 - select(1, allProperties:GetWide()) - select(1, unblockProperty:GetPos()))
				unblockProperty:SetParent(panel)
				unblockProperty:SetDisabled(true)
				
				paneldata.BlockProperty = blockProperty
				paneldata.UnblockProperty = unblockProperty
				
				
			end,
			Updater = function(panel, paneldata)
				if(paneldata.Properties == nil) then
					paneldata.Properties = {}
					for i,k in pairs(properties.List) do
						local printname = k.MenuLabel
						if(string.StartWith(printname, "#")) then
							printname = language.GetPhrase(string.Replace(printname, "#", ""))
						end
						table.insert(paneldata.Properties, { Name = printname, ClassName = k.InternalName })
					end
				end
				if(table.Count(paneldata.AllProperties:GetLines()) == 0) then
					for i,k in pairs(paneldata.Properties) do
						local ln = paneldata.AllProperties:AddLine(k.Name)
						ln.ClassName = k.ClassName
						
					end
				end
				Vermilion:PopulateRankTable(paneldata.RankList, false, true)
				paneldata.RankBlockList:Clear()
				paneldata.BlockProperty:SetDisabled(true)
				paneldata.UnblockProperty:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)