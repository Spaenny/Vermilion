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
MODULE.Name = "Skybox Protector"
MODULE.ID = "skybox_protect"
MODULE.Description = "Protects the skybox from trolling."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_skybox_protector",
	"immune_from_skybox_protector"
}

MODULE.Skyboxes = {}
MODULE.Point1 = {}

function MODULE:LoadSettings()
	local rawskyboxes = self:GetData("skyboxes", {})
	if(table.Count(rawskyboxes) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
	for i,k in pairs(rawskyboxes) do
		self.Skyboxes[i] = VToolkit.CBound(Vector(k[1], k[2], k[3]), Vector(k[4], k[5], k[6]))
	end
end

function MODULE:SaveSettings()
	local rawskyboxes = {}
	for i,k in pairs(self.Skyboxes) do
		rawskyboxes[i] = { k.Point1.x, k.Point1.y, k.Point1.z, k.Point2.x, k.Point2.y, k.Point2.z }
	end
	self:SetData("skyboxes", rawskyboxes)
end

function MODULE:ResetSettings()
	MODULE.Skyboxes = {}
end

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "skybox",
		Description = "Defines a skybox area.",
		Permissions = { "manage_skybox_protector" },
		Function = function(sender, text, log, glog)
			if(MODULE.Skyboxes[game.GetMap()] != nil) then
				log("A skybox has already been defined for this map! By continuing, you will overwrite the old definition.", NOTIFY_ERROR)
			end
			if(MODULE.Point1[sender:SteamID()] != nil) then
				local p1 = MODULE.Point1[sender:SteamID()]
				local p2 = sender:GetPos()
				local p1t = p1
				local p2t = p2
				if(p1.x < p2.x) then
					p1t = Vector(p2.x, p1t.y, p1t.z)
					p2t = Vector(p1.x, p2t.y, p2t.z)
				end
				if(p1.y < p2.y) then
					p1t = Vector(p1t.x, p2.y, p1t.z)
					p2t = Vector(p2t.x, p1.y, p2t.z)
				end
				if(p1.z < p2.z) then
					p1t = Vector(p1t.x, p1t.y, p2.z)
					p2t = Vector(p2t.x, p2t.y, p1.z)
				end
				MODULE.Skyboxes[game.GetMap()] = VToolkit.CBound(p1t, p2t)
				log("Defined skybox for " .. game.GetMap() .. "!")
				MODULE.Point1[sender:SteamID()] = nil
			else
				MODULE.Point1[sender:SteamID()] = sender:GetPos()
				log("Defined point 1!")
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "cancelskybox",
		Description = "Cancels the editing process.",
		Permissions = { "manage_skybox_protector" },
		Function = function(sender, text, log, glog)
			if(MODULE.Point1[sender:SteamID()] == nil) then
				log("You aren't editing the skybox region!", NOTIFY_ERROR)
				return
			end
			MODULE.Point1[sender:SteamID()] = nil
			log("Stopped editing the skybox region!")
		end
	})
end

function MODULE:InitShared()
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		local mod = Vermilion:GetModule("server_settings")
		if(mod != nil) then
			mod:AddOption("skybox_protect", "enabled", "Enable Skybox Protector", "Checkbox", "Misc", false, "manage_skybox_protector")
		end
	end)
end

function MODULE:InitServer()
	self:AddHook("PlayerInitialSpawn", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_skybox_protector") and MODULE.Skyboxes[game.GetMap()] == nil and MODULE:GetData("enabled", false, true)) then
			timer.Simple(2, function()
				Vermilion:AddNotification(vplayer, "No skybox area is defined for this map. Please define one or disable skybox protection!", NOTIFY_ERROR)
			end)
		end
	end)
	
	local badClasses = {
		"gmod_hands",
		"predicted_viewmodel",
		"physgun_beam"
	}
	
	local function buildTimer()
		timer.Create("Vermilion_Skyboxes", 1, 0, function()
			if(MODULE.Skyboxes[game.GetMap()] != nil) then
				local entsRemoved = 0
				for i,k in pairs(MODULE.Skyboxes[game.GetMap()]:GetEnts()) do
					if(k:IsPlayer()) then
						if(not Vermilion:HasPermission(k, "immune_from_skybox_protector")) then k:Spawn() Vermilion:AddNotification(k, "Please stay out of the skybox!", NOTIFY_ERROR) end
						continue
					end
					if(not k:CreatedByMap() and not k:IsPlayer() and (not k:IsWeapon() or k:GetOwner() == nil) and not table.HasValue(badClasses, k:GetClass())) then
						if(not Vermilion:GetUserBySteamID(k.Vermilion_Owner):HasPermission("immune_from_skybox_protector")) then
							k:Remove()
							entsRemoved = entsRemoved + 1
						end
					end
				end
				if(entsRemoved > 0) then Vermilion:AddNotification(Vermilion:GetUsersWithPermission("manage_skybox_protector"), "Removed " .. tostring(entsRemoved) .. " items from the skybox.") end
			end
		end)
	end
	
	if(MODULE:GetData("enabled", false)) then
		buildTimer()
	end
	
	self:AddDataChangeHook("enabled", "startprotect", function(val)
		if(val) then
			buildTimer()
		else
			timer.Destroy("Vermilion_Skyboxes")
		end
	end)
	
	self:AddHook(Vermilion.Event.ShuttingDown, "skybox_save", function()
		MODULE:SaveSettings()
	end)
end

function MODULE:InitClient()
	
end

Vermilion:RegisterModule(MODULE)