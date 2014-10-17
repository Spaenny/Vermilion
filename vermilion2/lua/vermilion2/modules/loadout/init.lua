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
MODULE.Name = "Loadouts"
MODULE.ID = "loadout"
MODULE.Description = "Set the weapons that players spawn with."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_loadout"
}
MODULE.NetworkStrings = {
	"VGetLoadout",
	"VGiveLoadoutWeapons",
	"VTakeLoadoutWeapons"
}

local defaultLoadout = {
	"weapon_crowbar",
	"weapon_pistol",
	"weapon_smg1",
	"weapon_frag",
	"weapon_physcannon",
	"weapon_crossbow",
	"weapon_shotgun",
	"weapon_357",
	"weapon_rpg",
	"weapon_ar2",
	"gmod_tool",
	"gmod_camera",
	"weapon_physgun"
}

function MODULE:InitServer()

	self:AddHook("PlayerLoadout", function(vplayer)
		local data = MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), defaultLoadout, true)
		if(data != nil) then
			vplayer:RemoveAllAmmo()
			if (cvars.Bool("sbox_weapons", true)) then
				vplayer:GiveAmmo(256, "Pistol", true)
				vplayer:GiveAmmo(256, "SMG1", true)
				vplayer:GiveAmmo(5, "grenade", true)
				vplayer:GiveAmmo(64, "Buckshot", true)
				vplayer:GiveAmmo(32, "357", true)
				vplayer:GiveAmmo(32, "XBowBolt", true)
				vplayer:GiveAmmo(6, "AR2AltFire", true)
				vplayer:GiveAmmo(100, "AR2", true)
			end
			
			for i,weapon in pairs(data) do
				vplayer:Give(weapon)
			end
			vplayer:SwitchToDefaultWeapon()
			return true
		end
	end)
	
	self:NetHook("VGetLoadout", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, defaultLoadout, true)
		if(data != nil) then
			net.Start("VGetLoadout")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			net.Start("VGetLoadout")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VGiveLoadoutWeapons", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_loadout")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, defaultLoadout, true), weapon)) then
				table.insert(MODULE:GetData(rnk, defaultLoadout, true), weapon)
			end
		end
	end)
	
	self:NetHook("VTakeLoadoutWeapons", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_loadout")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, defaultLoadout, true), weapon)
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetLoadout", function()
		if(not IsValid(Vermilion.Menu.Pages["loadout"].Panel.RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["loadout"].Panel.RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local loadout_list = Vermilion.Menu.Pages["loadout"].Panel.RankPermissions
		local weps = Vermilion.Menu.Pages["loadout"].Panel.Weapons
		if(IsValid(loadout_list)) then
			loadout_list:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(weps) do
					if(k1.ClassName == k) then
						loadout_list:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("Player Editors", 4)
	
	Vermilion.Menu:AddPage({
			ID = "loadout",
			Name = "Loadouts",
			Order = 6,
			Category = "Player Editors",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_loadout")
			end,
			Builder = function(panel)
				local giveDefault = nil
				local giveWeapon = nil
				local takeWeapon = nil
				local rankList = nil
				local allPermissions = nil
				local rankPermissions = nil
			
				local default = {
					["weapon_crowbar"] = "models/weapons/w_crowbar.mdl",
					["weapon_pistol"] = "models/weapons/w_pistol.mdl",
					["weapon_smg1"] = "models/weapons/w_smg1.mdl",
					["weapon_frag"] = "models/weapons/w_grenade.mdl",
					["weapon_physcannon"] = "models/weapons/w_Physics.mdl",
					["weapon_crossbow"] = "models/weapons/w_crossbow.mdl",
					["weapon_shotgun"] = "models/weapons/w_shotgun.mdl",
					["weapon_357"] = "models/weapons/w_357.mdl",
					["weapon_rpg"] = "models/weapons/w_rocket_launcher.mdl",
					["weapon_ar2"] = "models/weapons/w_irifle.mdl",
					["weapon_bugbait"] = "models/weapons/w_bugbait.mdl",
					["weapon_slam"] = "models/weapons/w_slam.mdl",
					["weapon_stunstick"] = "models/weapons/w_stunbaton.mdl",
					["weapon_physgun"] = "models/weapons/w_Physics.mdl"
				}
				function panel.getMdl(class)
					if(default[class] != nil) then return default[class] end
					return weapons.Get(class).WorldModel
				end
				
				panel.PreviewPanel = VToolkit:CreatePreviewPanel("model", panel, function(ent)
					ent:SetPos(Vector(20, 20, 45))
				end)
			
				
				rankList = VToolkit:CreateList({ "Name" }, false, false)
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					giveWeapon:SetDisabled(not (self:GetSelected()[1] != nil and allPermissions:GetSelected()[1] != nil))
					takeWeapon:SetDisabled(not (self:GetSelected()[1] != nil and rankPermissions:GetSelected()[1] != nil))
					giveDefault:SetDisabled(self:GetSelected()[1] == nil)
					net.Start("VGetLoadout")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankPermissions = VToolkit:CreateList({ "Name" })
				rankPermissions:SetPos(220, 30)
				rankPermissions:SetSize(240, panel:GetTall() - 40)
				rankPermissions:SetParent(panel)
				panel.RankPermissions = rankPermissions
				
				local rankPermissionsHeader = VToolkit:CreateHeaderLabel(rankPermissions, "Rank Loadout")
				rankPermissionsHeader:SetParent(panel)
				
				function rankPermissions:OnRowSelected(index, line)
					takeWeapon:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankPermissions)
				
				
				allPermissions = VToolkit:CreateList({"Name"})
				allPermissions:SetPos(panel:GetWide() - 250, 30)
				allPermissions:SetSize(240, panel:GetTall() - 40)
				allPermissions:SetParent(panel)
				panel.AllPermissions = allPermissions
				
				local allPermissionsHeader = VToolkit:CreateHeaderLabel(allPermissions, "All Weapons")
				allPermissionsHeader:SetParent(panel)
				
				function allPermissions:OnRowSelected(index, line)
					giveWeapon:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allPermissions)
				
				
				
				giveDefault = VToolkit:CreateButton("Give Default Loadout", function()
					for i,k in pairs(rankPermissions:GetLines()) do
						net.Start("VTakeLoadoutWeapons")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankPermissions:RemoveLine(k:GetID())
					end
					
					for i,k in pairs(defaultLoadout) do
						rankPermissions:AddLine(list.Get("Weapon")[k].PrintName).ClassName = k
						
						net.Start("VGiveLoadoutWeapons")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k)
						net.SendToServer()
					end
				end)
				giveDefault:SetPos(select(1, rankPermissions:GetPos()) + rankPermissions:GetWide() + 10, 480)
				giveDefault:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, giveDefault:GetPos()))
				giveDefault:SetParent(panel)
				giveDefault:SetDisabled(true)
				
				
				giveWeapon = VToolkit:CreateButton("Give Weapon", function()
					for i,k in pairs(allPermissions:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankPermissions:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankPermissions:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						net.Start("VGiveLoadoutWeapons")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				giveWeapon:SetPos(select(1, rankPermissions:GetPos()) + rankPermissions:GetWide() + 10, 100)
				giveWeapon:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, giveWeapon:GetPos()))
				giveWeapon:SetParent(panel)
				giveWeapon:SetDisabled(true)
				
				takeWeapon = VToolkit:CreateButton("Take Weapon", function()
					for i,k in pairs(rankPermissions:GetSelected()) do
						net.Start("VTakeLoadoutWeapons")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankPermissions:RemoveLine(k:GetID())
					end
				end)
				takeWeapon:SetPos(select(1, rankPermissions:GetPos()) + rankPermissions:GetWide() + 10, 130)
				takeWeapon:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, takeWeapon:GetPos()))
				takeWeapon:SetParent(panel)
				takeWeapon:SetDisabled(true)
				
				panel.GiveDefault = giveDefault
				panel.GiveWeapon = giveWeapon
				panel.TakeWeapon = takeWeapon
				
				
			end,
			Updater = function(panel)
				if(panel.Weapons == nil) then
					panel.Weapons = {}
					for i,k in pairs(list.Get("Weapon")) do
						table.insert(panel.Weapons, { Name = k.PrintName, ClassName = k.ClassName })
					end
				end
				if(table.Count(panel.AllPermissions:GetLines()) == 0) then
					for i,k in pairs(panel.Weapons) do
						local ln = panel.AllPermissions:AddLine(k.Name)
						ln.ClassName = k.ClassName
						
						ln.ModelPath = panel.getMdl(k.ClassName)
						
						ln.OldCursorMoved = ln.OnCursorMoved
						ln.OldCursorEntered = ln.OnCursorEntered
						ln.OldCursorExited = ln.OnCursorExited
						
						function ln:OnCursorEntered()
							panel.PreviewPanel:SetVisible(true)
							panel.PreviewPanel.ModelView:SetModel(ln.ModelPath)
							
							if(self.OldCursorEntered) then self:OldCursorEntered() end
						end
						
						function ln:OnCursorExited()
							panel.PreviewPanel:SetVisible(false)
							
							if(self.OldCursorExited) then self:OldCursorExited() end
						end
						
						function ln:OnCursorMoved(x,y)
							if(IsValid(panel.PreviewPanel)) then
								local x, y = input.GetCursorPos()
								panel.PreviewPanel:SetPos(x - 180, y - 117)
							end
							
							if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
						end
					end
				end
				Vermilion:PopulateRankTable(panel.RankList, false, true)
				panel.RankPermissions:Clear()
				panel.GiveWeapon:SetDisabled(true)
				panel.TakeWeapon:SetDisabled(true)
				panel.GiveDefault:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)