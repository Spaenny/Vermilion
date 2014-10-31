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
MODULE.Name = "Prop Protection"
MODULE.ID = "prop_protect"
MODULE.Description = "Stops players from griefing props. Also implements CPPI v1.1."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_prop_protection",
	"grav_gun_pickup_all",
	"grav_gun_pickup_own",
	"grav_gun_pickup_others",
	"grav_gun_punt_all",
	"grav_gun_punt_own",
	"grav_gun_punt_others",
	"physgun_pickup_all",
	"physgun_pickup_own",
	"physgun_pickup_others",
	"physgun_pickup_players",
	--"physgun_persist",
	"toolgun_own",
	"toolgun_others",
	"toolgun_all",
	"use_own",
	"use_others",
	"use_all",
	"right_click_all",
	"right_click_others",
	"right_click_own"
}
MODULE.PermissionDefinitions = {
	["manage_prop_protection"] = "This player can see the Prop Protection Settings tab in the Vermilion menu and modify the settings within.",
	["grav_gun_pickup_all"] = "This player can pick up any prop with the gravity gun, regardless of who owns the prop. Same as giving the player grav_gun_pickup_own and grav_gun_pickup_others at the same time.",
	["grav_gun_pickup_own"] = "This player can only pick up their own props with the gravity gun.",
	["grav_gun_pickup_others"] = "This player can only pick up props with the gravity gun that they do not own.",
	["grav_gun_punt_all"] = "This player can punt any prop with the gravity gun, regardless of who owns the prop. Same as giving the player grav_gun_punt_own and grav_gun_punt_others at the same time.",
	["grav_gun_punt_own"] = "This player can only punt their own props with the gravity gun.",
	["grav_gun_punt_others"] = "This player can only punt props with the gravity gun that they do not own.",
	["physgun_pickup_all"] = "This player can pick up any prop with the physics gun, regardless of who owns the prop. Same as giving the player physgun_pickup_own and physgun_pickup_others at the same time.",
	["physgun_pickup_own"] = "This player can only pick up their own props with the physics gun.",
	["physgun_pickup_others"] = "This player can only pick up props with the physics gun that they do not own.",
	["physgun_pickup_players"] = "This player can pick up other players with the physics gun.",
	--["physgun_persist"] = "This player can pickup/freeze persistent props with the physics gun.",
	["toolgun_all"] = "This player can use the toolgun on any prop, regardless of who owns the prop. Same as giving the player toolgun_own and toolgun_others at the same time.",
	["toolgun_own"] = "This player can only use the toolgun on their own props.",
	["toolgun_others"] = "This player can only use the toolgun on props they do not own.",
	["use_all"] = "This player can USE any prop, regardless of who owns the prop. Same as giving the player use_own and use_others at the same time.",
	["use_own"] = "This player can only USE their own props.",
	["use_others"] = "This player can only USE props that they do not own.",
	["right_click_all"] = "This player can right click on any prop in the contextual menu regardless of who owns the prop. Same as giving the player right_click_own and right_click_others at the same time.",
	["right_click_own"] = "This player can only right click on their own props in the contextual menu.",
	["right_click_others"] = "This player can only right click on props in the contextual menu that they do not own."
}

MODULE.UiDCache = {}
CPPI = {}

function MODULE:CanTool(vplayer, ent, tool)
	if(tool == "vermilion2_owner") then return true end
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return true end
	if(ent:CreatedByMap() and MODULE:GetData("prop_protect_world", true)) then
		return false
	end
	if(not Vermilion:HasPermission(vplayer, "toolgun_all") and MODULE:GetData("prop_protect_toolgun", true)) then
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "toolgun_others")) then
			Vermilion:AddNotification(vplayer, "You can't use the toolgun on this prop!", NOTIFY_ERROR)
			return false
		end
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "toolgun_own")) then
			Vermilion:AddNotification(vplayer, "You can't use the toolgun on this prop!", NOTIFY_ERROR)
			return false
		end
	end
	return true
end

function MODULE:CanGravGunPickup( vplayer, ent )
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "grav_gun_pickup_all") and MODULE:GetData("prop_protect_gravgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_own")) then return false end
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_others")) then return false end
	end
	return true
end

function MODULE:CanGravGunPunt( vplayer, ent )
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "grav_gun_punt_all") and MODULE:GetData("prop_protect_gravgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_own")) then return false end
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_others")) then return false end
	end
	return true
end

function MODULE:CanPhysgun( vplayer, ent )
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(ent:CreatedByMap() and MODULE:GetData("prop_protect_world", true)) then 
		--Vermilion:SendNotify(vplayer, "You can't use the physgun on a map entity!", VERMILION_NOTIFY_ERROR)
		return false
	end
	if(ent:IsPlayer() and Vermilion:HasPermission(vplayer, "physgun_pickup_players") and not Vermilion:GetUser(ent):IsImmune(vplayer)) then return true end
	--if(ent:GetPersistent() and Vermilion:HasPermission(vplayer, "physgun_persist")) then return true end
	if(not Vermilion:HasPermission(vplayer, "physgun_pickup_all") and ent.Vermilion_Owner != nil and MODULE:GetData("prop_protect_physgun", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_own")) then
			return false
		elseif (ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_others")) then
			return false
		end
	end
end

function MODULE:CanUse(vplayer, ent)
	if(not MODULE:GetData("prop_protect_enabled", true, true)) then return true end
	if(not IsValid(vplayer) or not IsValid(ent)) then return false end
	if(not Vermilion:HasPermission(vplayer, "use_all") and MODULE:GetData("prop_protect_use", true)) then
		if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "use_own")) then return false end
		if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "use_others")) then return false end
	end
	return true
end

function MODULE:InitShared()
	
	CPPI.CPPI_DEFER = -666888
	CPPI.CPPI_NOTIMPLEMENTED = -999333
	
	function CPPI.GetName()
		return "Vermilion CPPI Module"
	end
	
	function CPPI.GetVersion()
		return Vermilion.GetVersion()
	end
	
	function CPPI.GetInterfaceVersion()
		return 1.1
	end
	
	function CPPI.GetNameFromUID( uid )
		if(MODULE.UidCache[uid] != nil) then return MODULE.UidCache[uid] end
		for i,k in pairs(player.GetAll()) do
			if(IsValid(k)) then
				if(not table.HasValue(MODULE.UidCache, k:GetName())) then
					MODULE.UidCache[k:UniqueID()] = k:GetName()
				end
			end
		end
		if(MODULE.UidCache[uid] != nil) then return MODULE.UidCache[uid] end
		return nil
	end
	
	local pMeta = FindMetaTable("Player")
	function pMeta:CPPIGetFriends()
		return CPPI.CPPI_NOTIMPLEMENTED
	end
	
	self:AddHook(Vermilion.Event.MOD_LOADED, "AddGui", function()
		if(Vermilion:GetModule("server_settings") != nil) then
			local mgr = Vermilion:GetModule("server_settings")
			mgr:AddCategory("Prop Protection", 2)
			mgr:AddOption("prop_protect", "prop_protect_enabled", "Enable Prop Protection", "Checkbox", "Prop Protection", true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_use", "Block unpermitted players from \"using\" other player's props", "Checkbox", "Prop Protection", true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_physgun", "Block unpermitted players from using the physics gun on other player's props", "Checkbox", "Prop Protection", true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_gravgun", "Block unpermitted players from using the gravity gun on other player's props", "Checkbox", "Prop Protection", true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_toolgun", "Block unpermitted players from using the toolgun on other player's props", "Checkbox", "Prop Protection", true, "manage_prop_protection")
			mgr:AddOption("prop_protect", "prop_protect_world", "Blanket ban all physgun/toolgun interaction on map spawned props", "Checkbox", "Prop Protection", true, "manage_prop_protection")
		end
	end)
end

function MODULE:InitServer()
	self:AddHook("GravGunPickupAllowed", function(vplayer, ent)
		if(not MODULE:CanGravGunPickup( vplayer, ent )) then return false end
	end)
	
	self:AddHook("GravGunPunt", function(vplayer, ent)
		if(not MODULE:CanGravGunPunt( vplayer, ent )) then return false end
	end)
	
	self:AddHook("PhysgunPickup", function(vplayer, ent)
		return MODULE:CanPhysgun( vplayer, ent )
	end)
	
	self:AddHook("CanTool", function(vplayer, tr, tool)
		if(tr.Hit and tr.Entity != nil and not MODULE:CanTool(vplayer, tr.Entity, tool)) then return false end
	end)
	
	self:AddHook("PlayerUse", function(vplayer, ent)
		if(not MODULE:CanUse(vplayer, ent)) then return false end
	end)
	
	local eMeta = FindMetaTable("Entity")
	function eMeta:CPPIGetOwner()
		if(self.Vermilion_Owner == nil) then return nil, nil end
		local oPlayer = VToolkit:LookupPlayerBySteamID(self.Vermilion_Owner)
		return oPlayer, CPPI.CPPI_NOTIMPLEMENTED
	end
	
	
	function eMeta:CPPISetOwner(vplayer)
		if(IsValid(vplayer)) then
			if(hook.Call("CPPIAssignOwnership", nil, vplayer, self) == nil) then
				Vermilion.Log("Warning (" .. tostring(self) .. "): prop owner was overwritten by CPPI!")
				self.Vermilion_Owner = vplayer:SteamID()
				self:SetNWString("Vermilion_Owner", vplayer:SteamID())
				return true
			end
		end
		return false
	end
	
	function eMeta:CPPISetOwnerUID( uid )
		local vplayer = VToolkit:LookupPlayerByName(CPPI.GetNameFromUID(uid))
		if(IsValid(vplayer)) then
			if(hook.Call("CPPIAssignOwnership", nil, vplayer, self) == nil) then
				self.Vermilion_Owner = vplayer:SteamID()
				self:SetNWString("Vermilion_Owner", vplayer:SteamID())
				return true
			end
		end
		return false
	end
	
	function eMeta:CPPICanTool( vplayer, tool )
		return MODULE:CanTool(vplayer, self, tool) == nil
	end
	
	function eMeta:CPPICanPhysgun( vplayer )
		return MODULE:CanPhysgun( vplayer, self )
	end
	
	function eMeta:CPPICanPickup( vplayer )
		return MODULE:CanGravGunPickup( vplayer, self )
	end
	
	function eMeta:CPPICanPunt( vplayer )
		return MODULE:CanGravGunPunt( vplayer, self )
	end
	
end

function MODULE:InitClient()		
	local eMeta = FindMetaTable("Entity")
	function eMeta:CPPIGetOwner()
		return CPPI.CPPI_NOTIMPLEMENTED
	end
end

Vermilion:RegisterModule(MODULE)