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
MODULE.Name = "Weapon Limits"
MODULE.ID = "limit_weapons"
MODULE.Description = "Prevent players from spawning/using/picking up certain weapons."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_weapon_limits"
}
MODULE.NetworkStrings = {
	"VGetWeaponLimits",
	"VBlockWeapon",
	"VUnblockWeapon"
}

function MODULE:InitServer()

	self:AddHook("PlayerGiveSWEP", function(vplayer, weapon, swep)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), weapon)) then
			Vermilion:AddNotification(vplayer, "You cannot spawn this weapon!", NOTIFY_ERROR)
			return false
		end
	end)
	
	self:AddHook("PlayerCanPickupWeapon", function(vplayer, weapon)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), weapon:GetClass())) then
			return false
		end
	end)
	
	self:AddHook("Vermilion_IsEntityDuplicatable", function(vplayer, class)
		if(not IsValid(vplayer)) then return end
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), class)) then
			return false
		end
	end)
	
	self:AddHook("PlayerSpawnSENT", function(vplayer, class)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), class)) then
			return false
		end
	end)
	
	function MODULE:ScanForIllegalWeapons(vplayer)
		if(not IsValid(vplayer)) then return end
		if(not Vermilion:HasUser(vplayer)) then return end
		local rules = self:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true)
		for i,k in pairs(rules) do
			if(vplayer:HasWeapon(k)) then
				Vermilion.Log("Confiscating illegal weapon " .. k .. " on player " .. vplayer:GetName() .. "!")
				vplayer:StripWeapon(k)
			end
		end
	end
	
	self:AddHook("PlayerSpawn", function(vplayer)
		timer.Simple(1, function() 
			MODULE:ScanForIllegalWeapons(vplayer)
		end)
	end)
	
	self:AddHook("PlayerSwitchWeapon", function(vplayer, old, new)
		MODULE:ScanForIllegalWeapons(vplayer)
	end)
	
	
	
	
	self:NetHook("VGetWeaponLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			MODULE:NetStart("VGetWeaponLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			MODULE:NetStart("VGetWeaponLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VBlockWeapon", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_weapon_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), weapon)) then
				table.insert(MODULE:GetData(rnk, {}, true), weapon)
			end
		end
	end)
	
	self:NetHook("VUnblockWeapon", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_weapon_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, {}, true), weapon)
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetWeaponLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_weapons"].Panel.RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_weapons"].Panel.RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_weapons"].Panel.RankBlockList
		local weps = Vermilion.Menu.Pages["limit_weapons"].Panel.Weapons
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(weps) do
					if(k1.ClassName == k) then
						blocklist:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_weapons",
			Name = "Weapons",
			Order = 1,
			Category = "limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_weapon_limits")
			end,
			Builder = function(panel)
				local blockWeapon = nil
				local unblockWeapon = nil
				local rankList = nil
				local allWeapons = nil
				local rankBlockList = nil
			
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
					blockWeapon:SetDisabled(not (self:GetSelected()[1] != nil and allWeapons:GetSelected()[1] != nil))
					unblockWeapon:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					MODULE:NetStart("VGetWeaponLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({ "Name" })
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(240, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				panel.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked Weapons")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockWeapon:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				
				allWeapons = VToolkit:CreateList({"Name"})
				allWeapons:SetPos(panel:GetWide() - 250, 30)
				allWeapons:SetSize(240, panel:GetTall() - 40)
				allWeapons:SetParent(panel)
				panel.AllWeapons = allWeapons
				
				local allWeaponsHeader = VToolkit:CreateHeaderLabel(allWeapons, "All Weapons")
				allWeaponsHeader:SetParent(panel)
				
				function allWeapons:OnRowSelected(index, line)
					blockWeapon:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allWeapons)
				
				
				blockWeapon = VToolkit:CreateButton("Block Weapon", function()
					for i,k in pairs(allWeapons:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankBlockList:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankBlockList:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						MODULE:NetStart("VBlockWeapon")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				blockWeapon:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 100)
				blockWeapon:SetWide(panel:GetWide() - 20 - select(1, allWeapons:GetWide()) - select(1, blockWeapon:GetPos()))
				blockWeapon:SetParent(panel)
				blockWeapon:SetDisabled(true)
				
				unblockWeapon = VToolkit:CreateButton("Unblock Weapon", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						MODULE:NetStart("VUnblockWeapon")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockWeapon:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 130)
				unblockWeapon:SetWide(panel:GetWide() - 20 - select(1, allWeapons:GetWide()) - select(1, unblockWeapon:GetPos()))
				unblockWeapon:SetParent(panel)
				unblockWeapon:SetDisabled(true)
				
				panel.BlockWeapon = blockWeapon
				panel.UnblockWeapon = unblockWeapon
				
				
			end,
			Updater = function(panel)
				if(panel.Weapons == nil) then
					panel.Weapons = {}
					for i,k in pairs(list.Get("Weapon")) do
						local name = k.PrintName
						if(name == nil or name == "") then
							name = k.ClassName
						end
						table.insert(panel.Weapons, { Name = name, ClassName = k.ClassName })
					end
				end
				if(table.Count(panel.AllWeapons:GetLines()) == 0) then
					for i,k in pairs(panel.Weapons) do
						local ln = panel.AllWeapons:AddLine(k.Name)
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
				panel.RankBlockList:Clear()
				panel.BlockWeapon:SetDisabled(true)
				panel.UnblockWeapon:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)