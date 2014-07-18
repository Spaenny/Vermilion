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
local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Weapon Limits"
EXTENSION.ID = "weplimit"
EXTENSION.Description = "Limits player access to weapons"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"weplimit_management",
	"give_all_sweps"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"give_all_sweps"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VWeaponsList",
	"VRankWeaponsLoad",
	"VRankWeaponsSave"
}

EXTENSION.RankLimits = {}
EXTENSION.EditingRank = ""

function EXTENSION:InitServer()
	
	self:AddHook("VNET_VWeaponsList", function(vplayer)
		net.Start("VWeaponsList")
		local tab = {}
		for i,k in pairs(list.Get("Weapon")) do
			table.insert(tab, i)
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("VNET_VRankWeaponsSave", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "weplimit_management")) then
			return
		end
		local rnk = net.ReadString()
		local tab = net.ReadTable()
		EXTENSION.RankLimits[rnk] = tab
		EXTENSION:SaveSettings()
	end)
	
	self:AddHook("VNET_VRankWeaponsLoad", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "weplimit_management")) then
			return
		end
		local rnk = net.ReadString()
		
		local tab = EXTENSION.RankLimits[rnk]
		if(not tab) then
			tab = {}
		end
		net.Start("VRankWeaponsLoad")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("PlayerGiveSWEP", "SwepOverride", function(vplayer, weapon, swep)
		if(Vermilion:HasPermission(vplayer, "give_all_sweps")) then
			return true
		end
		local pRank = Vermilion:GetPlayer(vplayer)['rank']
		if(EXTENSION.RankLimits[pRank] == nil) then
			return
		end
		if(table.HasValue(EXTENSION.RankLimits[pRank], weapon)) then
			Vermilion:SendNotify(vplayer, "You cannot spawn this weapon!", 5, NOTIFY_ERROR)
			return false
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("wep_control", "weplimit_management")
	end)
	
	self:AddHook("ShutDown", "weaponlimit_save", function()
		EXTENSION:SaveSettings()
	end)
	
	EXTENSION:LoadSettings()
end

function EXTENSION:LoadSettings()
	if(not file.Exists(Vermilion.GetFileName("vermilion", "weapon_bans.txt"), "DATA")) then
		Vermilion.Log("Creating weapon_bans for the first time!")
		self:ResetSettings()
		self:SaveSettings()
	end
	local data = file.Read( Vermilion.GetFileName("vermilion", "weapon_bans.txt"), "DATA")
	local tab = von.deserialize(data)
	self.RankLimits = tab
end

function EXTENSION:SaveSettings()
	file.Write(Vermilion.GetFileName("vermilion", "weapon_bans.txt"), von.serialize(self.RankLimits))
end

function EXTENSION:ResetSettings()
	self.RankLimits = {}
end

function EXTENSION:InitClient()
	self:AddHook("Vermilion_RanksList", "RanksList", function(tab)
		if(not IsValid(EXTENSION.RanksList)) then
			return
		end
		EXTENSION.RanksList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RanksList:AddLine(k[1], tostring(i), k[2])
		end
	end)
	self:AddHook("VNET_VWeaponsList", function()
		if(not IsValid(EXTENSION.AllWeaponsList)) then
			return
		end
		EXTENSION.AllWeaponsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.AllWeaponsList:AddLine(k)
		end
	end)
	self:AddHook("VNET_VRankWeaponsLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.RankPermissionsList:AddLine(k)
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("wep_control", "Weapon Limits", "icon16/gun.png", "Weapon Control", function(TabHolder)
			local panel = vgui.Create("DPanel", TabHolder)
			panel:StretchToParent(5, 20, 20, 5)
			
			local ranksLabel = Crimson.CreateLabel("Ranks")
			ranksLabel:SetPos(110 - (ranksLabel:GetWide() / 2), 10)
			ranksLabel:SetParent(panel)
			
			local ranksList = vgui.Create("DListView")
			ranksList:SetMultiSelect(true)
			ranksList:AddColumn("Name")
			ranksList:AddColumn("Numerical ID")
			ranksList:AddColumn("Default")
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(200, 190)
			ranksList:SetSortable(false)
			function ranksList:SortByColumn(ColumnID, Desc) end
			EXTENSION.RanksList = ranksList
			
			local blockedWeaponsLabel = Crimson.CreateLabel("Blocked Weapons")
			blockedWeaponsLabel:SetPos(110 - (blockedWeaponsLabel:GetWide() / 2), 230)
			blockedWeaponsLabel:SetParent(panel)
			
			local guiRankPermissionsList = vgui.Create("DListView")
			guiRankPermissionsList:SetMultiSelect(true)
			guiRankPermissionsList:AddColumn("Name")
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(200, 280)
			
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local allWeaponsLabel = Crimson.CreateLabel("All Weapons")
			allWeaponsLabel:SetPos(475 - (allWeaponsLabel:GetWide() / 2), 230)
			allWeaponsLabel:SetParent(panel)
			
			local guiAllWeaponsList = vgui.Create("DListView")
			guiAllWeaponsList:SetMultiSelect(true)
			guiAllWeaponsList:AddColumn("Name")
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(375, 250)
			guiAllWeaponsList:SetSize(200, 280)
			
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Permissions", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load permissions for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the permissions for!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner" or ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot edit the permissions of this rank; it is a protected rank!")
					return
				end
				net.Start("VRankWeaponsLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Blocked Weapons - " .. ranksList:GetSelected()[1]:GetValue(1))
				blockedWeaponsLabel:SizeToContents()
				blockedWeaponsLabel:SetPos(110 - (blockedWeaponsLabel:GetWide() / 2), 230)
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(220, 250)
			loadRankPermissionsButton:SetSize(145, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Permissions", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank permissions before you can save them!")
					return
				end
				net.Start("VRankWeaponsSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k:GetValue(1))
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Blocked Weapons")
				blockedWeaponsLabel:SizeToContents()
				blockedWeaponsLabel:SetPos(110 - (blockedWeaponsLabel:GetWide() / 2), 230)
			end)
			saveRankPermissionsButton:SetPos(220, 500)
			saveRankPermissionsButton:SetSize(145, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			local giveRankPermissionButton = Crimson.CreateButton("Block Weapon", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to give it permissions!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one weapon to block for this rank!")
					return
				end
				for i,k in pairs(guiAllWeaponsList:GetSelected()) do
					guiRankPermissionsList:AddLine(k:GetValue(1))
				end
			end)
			giveRankPermissionButton:SetPos(220, 350)
			giveRankPermissionButton:SetSize(145, 30)
			giveRankPermissionButton:SetParent(panel)
			
			local removeRankPermissionButton = Crimson.CreateButton("Unblock Weapon", function(self)
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one weapon to unblock for this rank!")
					return
				end
				local tab = {}
				for i,k in ipairs(guiRankPermissionsList:GetLines()) do
					if(not k:IsSelected()) then
						table.insert(tab, k:GetValue(1))
					end
				end
				guiRankPermissionsList:Clear()
				for i,k in ipairs(tab) do
					guiRankPermissionsList:AddLine(k)
				end
			end)
			removeRankPermissionButton:SetPos(220, 390)
			removeRankPermissionButton:SetSize(145, 30)
			removeRankPermissionButton:SetParent(panel)
			
			net.Start("VWeaponsList")
			net.SendToServer()
			
			return panel		
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)