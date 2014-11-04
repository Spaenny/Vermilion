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
MODULE.Name = "Zones"
MODULE.ID = "zones"
MODULE.Description = "Add zones" // <-- add a better description
MODULE.Author = "Ned"
MODULE.Permissions = {
	"zone_manager",
	"create_zone",
	"remove_zone",
	"ignore_zones"
}
MODULE.PermissionDefintions = {
	["zone_manager"] = "This player is able to see the Zones tab on the Vermilion Menu and modify the settings within.",
	["create_zone"] = "This player is able to create new zones.",
	["remove_zone"] = "This player is able to remove zones.",
	["ignore_zones"] = "This player is not affected by any zones."
}
MODULE.NetworkStrings = {
	"VUpdateBlocks",
	"VDrawCreateBlocks"
}

MODULE.Zones = {}
MODULE.DrawEffect = Material("models/effects/comball_tape") -- what happens if the client/server doesn't have HL2?
--MODULE.DrawEffect = Material("models/props_combine/portalball001_sheet")

MODULE.Point1 = {}
MODULE.DrawingFrom = nil

MODULE.EffectDefinitions = {}

MODULE.BaseZone = {}
function MODULE.BaseZone:HasEffect(effect)
	return table.HasValue(table.GetKeys(self.Effects), effect)
end
function MODULE.BaseZone:AddEffect(effect, parameters)
	self.Effects[effect] = parameters
end
function MODULE.BaseZone:RemoveEffect(effect)
	self.Effects[effect] = nil
end
function MODULE.BaseZone:GetEffectProps(effect)
	return self.Effects[effect]
end

local effectMustHave = { "Name" }
local effectShouldHave = {
	{ "Handler", function() end },
	{ "Events", {} },
	{ "Predictor", nil },
	{ "PropValidator", nil }
}

function MODULE:RegisterEffect(data)
	for i,k in pairs(effectMustHave) do
		assert(data[k] != nil)
	end
	for i,k in pairs(effectShouldHave) do
		if(data[k[1]] == nil) then data[k[1]] = k[2] end
	end
	MODULE.EffectDefinitions[data.Name] = data
end

function MODULE:NewZone(c1, c2, name, owner)
	self.Zones[name] = { Bound = VToolkit.CBound(c1, c2), Effects = { }, Owner = owner, ActivePlayers = {}, ActiveObjects = {}, Map = game.GetMap() }
	setmetatable(self.Zones[name], { __index = MODULE.BaseZone })
	self:UpdateClients()
end

function MODULE:GetZonesWithEffect(effect)
	return VToolkit.FindInTable(self.Zones, function(k) return table.HasValue(table.GetKeys(k.Effects), effect) and k.Map == game.GetMap() end)
end

function MODULE:UpdateClients(client)
	print("Sending zone update!")
	MODULE:NetStart("VUpdateBlocks")
	local stab = {}
	for i,k in pairs(MODULE.Zones) do
		if(k.Map == game.GetMap()) then
			table.insert(stab, {k.Bound.Point1, k.Bound.Point2})
		end
	end
	net.WriteTable(stab)
	if(not client) then 
		net.Broadcast()
	else
		net.Send(client)
	end
end

function MODULE:LoadSettings()
	local stab = self:GetData("zones", {})
	if(table.Count(stab) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
	for i,k in pairs(stab) do
		local v1 = Vector(k[1][1], k[1][2], k[1][3])
		local v2 = Vector(k[2][1], k[2][2], k[2][3])
		self.Zones[i] = { Bound = VToolkit.CBound(v1, v2), Effects = k[3], Owner = k[4], ActivePlayers = {}, ActiveObjects = {}, Map = k[5] }
		setmetatable(self.Zones[i], { __index = MODULE.BaseZone })
	end
end

function MODULE:SaveSettings()
	local stab = {}
	for i,k in pairs(self.Zones) do
		stab[i] = { { k.Bound.Point1.x, k.Bound.Point1.y, k.Bound.Point1.z }, { k.Bound.Point2.x, k.Bound.Point2.y, k.Bound.Point2.z }, k.Effects, k.Owner, k.Map }
	end
	self:SetData("zones", stab)
end

function MODULE:ResetSettings()
	self.Zones = {}
end

function MODULE:DistributeEvent(eventName, ...)
	for i,k in pairs(VToolkit.FindInTable(MODULE.EffectDefinitions, function(tentry) return tentry.Events[eventName] != nil end)) do
		local result = k.Events[eventName](...)
		if(result != nil) then
			return result
		end
	end
end

function MODULE:InitServer()
	self:NetHook("VUpdateBlocks", function(vplayer)
		MODULE:UpdateClients(vplayer)
	end)

	-- Effect Definitions --
	
	self:RegisterEffect({
		Name = "anti_pvp",
		Events = {
			["PlayerShouldTakeDamage"] = function( vplayer, attacker )
				if(not IsTableOfEntitiesValid({vplayer, attacker})) then return end
				if(not attacker:IsPlayer()) then return end
				for i,zone in pairs(MODULE:GetZonesWithEffect("anti_pvp")) do
					if(zone.Bound:IsInside(vplayer)) then return false end
				end
			end
		}
	})
	
	self:RegisterEffect({
		Name = "anti_noclip",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer()) then
				if(ent:GetMoveType() == MOVETYPE_NOCLIP) then
					ent:SetMoveType(MOVETYPE_WALK)
				end
			end
		end,
		Events = {
			["PlayerNoClip"] = function(vplayer, state)
				if(not IsValid(vplayer)) then return end
				for i,zone in pairs(MODULE:GetZonesWithEffect("anti_noclip")) do
					if(zone.Bound:IsInside(vplayer)) then return false end
				end
			end
		}
	})
	
	self:RegisterEffect({
		Name = "confiscate_weapons",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer()) then
				for i,weapon in pairs(ent:GetWeapons()) do
					if(not (weapon:GetClass() == "gmod_tool" or weapon:GetClass() == "weapon_physgun" or weapon:GetClass() == "weapon_physcannon" or weapon:GetClass() == "gmod_camera")) then
						if(not table.HasValue(zone.ActivePlayers[ent:SteamID()]["Confiscated_Weapons"], weapon:GetClass())) then
							table.insert(zone.ActivePlayers[ent:SteamID()]["Confiscated_Weapons"], weapon:GetClass())
						end
						ent:StripWeapon(weapon:GetClass())
					end
				end
			end
		end,
		Events = {
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasEffect("confiscate_weapons")) then return end
				local weps = {}
				for i,weapon in pairs(vplayer:GetWeapons()) do
					if(not (weapon:GetClass() == "gmod_tool" or weapon:GetClass() == "weapon_physgun" or weapon:GetClass() == "weapon_physcannon" or weapon:GetClass() == "gmod_camera")) then
						table.insert(weps, weapon:GetClass())
						vplayer:StripWeapon(weapon:GetClass())
					end
				end
				local entry = zone.ActivePlayers[vplayer:SteamID()]
				entry["Confiscated_Weapons"] = weps
			end,
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasEffect("confiscate_weapons")) then return end
				local entry = zone.ActivePlayers[vplayer:SteamID()]
				if(entry == nil) then
					return
				end
				for i,k in pairs(entry["Confiscated_Weapons"]) do
					vplayer:Give(k)
				end
				vplayer:SwitchToDefaultWeapon()
			end
		}
	})
	
	self:RegisterEffect({
		Name = "no_gravity",
		Events = {
			["Vermilion_Object_Entered_Zone"] = function(zone, ent)
				if(not zone:HasEffect("no_gravity") or ent:IsPlayer()) then return end
				local phys = ent:GetPhysicsObject()
				if(not IsValid(phys)) then 
					ent:SetGravity(-0.00000001)
					return
				end
				construct.SetPhysProp( ent:GetOwner(), ent, ent:EntIndex(), phys, { GravityToggle = false, Material = ent:GetMaterial() } )
			end,
			["Vermilion_Object_Left_Zone"] = function(zone, ent)
				if(not zone:HasEffect("no_gravity") or ent:IsPlayer()) then return end
				local phys = ent:GetPhysicsObject()
				if(not IsValid(phys)) then 
					ent:SetGravity(0)
					return
				end
				construct.SetPhysProp( ent:GetOwner(), ent, ent:EntIndex(), phys, { GravityToggle = true, Material = ent:GetMaterial() } )
			end,
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasEffect("no_gravity")) then return end
				local phys = vplayer:GetPhysicsObject()
				if(not IsValid(phys)) then 
					vplayer:SetGravity(-0.00000001)
					return
				end
				phys:EnableGravity(false)
				vplayer:SetGravity(-0.00000001)
			end,
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasEffect("no_gravity")) then return end
				local phys = vplayer:GetPhysicsObject()
				if(not IsValid(phys)) then 
					vplayer:SetGravity(0)
					return
				end
				phys:EnableGravity(true)
				vplayer:SetGravity(0)
			end
		}
	})
	
	self:RegisterEffect({
		Name = "speed",
		Events = {
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasEffect("speed")) then return end
				local speed = math.abs(200 * (tonumber(zone:GetEffectProps("speed")[1]) or 5))
				GAMEMODE:SetPlayerSpeed(vplayer, speed, speed * 2)
			end,
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasEffect("speed")) then return end
				local speed = math.abs(200)
				GAMEMODE:SetPlayerSpeed(vplayer, speed, speed * 2)
			end
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 3) then
				return { { Name = "", Syntax = "Speed multiplier..." } }
			end
		end,
		PropValidator = function(sender, text, log, glog)
			if(table.Count(text) == 2) then
				text[3] = "5"
				return
			end
			if(tonumber(text[3]) == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
		end
	})
	
	self:RegisterEffect({
		Name = "sudden_death",
		Events = {
			["PlayerShouldTakeDamage"] = function(target, attacker)
				if(not IsValid(target)) then return end
				if(target:IsPlayer() and IsValid(attacker)) then
					if(attacker:IsPlayer()) then
						local zones = MODULE:GetZonesWithEffect("sudden_death")
						local targetValid = false
						local attackerValid = false
						for i,zone in pairs(zones) do
							if(zone.Bound:IsInside(target)) then
								targetValid = true
							end
							if(zone.Bound:IsInside(attacker)) then
								attackerValid = true
							end
						end
						if(targetValid and attackerValid) then
							target:SetHealth(0)
							Vermilion:BroadcastNotification(attacker:GetName() .. " killed " .. target:GetName() .. " in a sudden death zone!")
						end
					end
				end
			end
		}
	})
	
	self:RegisterEffect({
		Name = "no_vehicles",
		Handler = function(zone, ent, properties)
			if(ent:IsVehicle()) then
				ent:SetSaveValue("VehicleLocked", true)
			end
		end,
		Events = {
			["Vermilion_Object_Entered_Zone"] = function(zone, ent)
				if(not zone:HasEffect("no_vehicles")) then return end
				if(ent:IsVehicle()) then
					if(IsValid(ent:GetDriver())) then
						ent:GetDriver():ExitVehicle()
					end
					ent:SetSaveValue("VehicleLocked", true)
				end
			end,
			["Vermilion_Object_Left_Zone"] = function(zone, ent)
				if(not zone:HasEffect("no_vehicles")) then return end
				if(ent:IsVehicle()) then
					ent:SetSaveValue("VehicleLocked", false)
				end
			end
		}
	})
	
	self:RegisterEffect({
		Name = "anti_propspawn",
		Events = {
			["PlayerSpawnedProp"] = function(ply, model, ent)
				local zones = MODULE:GetZonesWithEffect("anti_propspawn")
				for i,zone in pairs(zones) do
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetEffectProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedRagdoll"] = function(ply, model, ent)
				local zones = MODULE:GetZonesWithEffect("anti_propspawn")
				for i,zone in pairs(zones) do
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetEffectProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedSENT"] = function(ply, ent)
				local zones = MODULE:GetZonesWithEffect("anti_propspawn")
				for i,zone in pairs(zones) do
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetEffectProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedSWEP"] = function(ply, ent)
				local zones = MODULE:GetZonesWithEffect("anti_propspawn")
				for i,zone in pairs(zones) do
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetEffectProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedVehicle"] = function(ply, ent)
				local zones = MODULE:GetZonesWithEffect("anti_propspawn")
				for i,zone in pairs(zones) do
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetEffectProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedEffect"] = function(ply, model, ent)
				local zones = MODULE:GetZonesWithEffect("anti_propspawn")
				for i,zone in pairs(zones) do
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetEffectProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end
		},
		Predictor = function(pos, current, all, vplayer)
			local tab = { { Name = "", Syntax = "Players that can spawn props inside the zone..." } }
			for i,k in pairs(VToolkit.MatchPlayerPart(current)) do
				table.insert(tab, { Name = k, Syntax = "" })
			end
			return tab
		end,
		PropValidator = function(sender, text, log, glog)
			for i,k in pairs(text) do
				if(i < 3) then continue end
				if(not IsValid(VToolkit.LookupPlayer(k))) then
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
					return false
				end
			end
		end
	})
	
	self:RegisterEffect({
		Name = "anti_rank",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer()) then
				if(table.HasValue(properties, Vermilion:GetUser(ent):GetRankName())) then Vermilion:AddNotification(ent, "You cannot enter this zone!", NOTIFY_ERROR) ent:Spawn() end
			end
		end,
		Predictor = function(pos, current, all, vplayer)
			local tab = { { Name = "", Syntax = "Ranks that cannot enter the zone..." } }
			for i,k in pairs(Vermilion.Data.Ranks) do
				if(string.find(string.lower(k.Name), string.lower(current))) then
					table.insert(tab, { Name = k.Name, Syntax = "" })
				end
			end
			return tab
		end,
		PropValidator = function(sender, text, log, glog)
			for i,k in pairs(text) do
				if(i < 3) then continue end
				if(Vermilion:GetRank(k) == nil) then
					log(Vermilion:TranslateStr("no_rank", nil, sender), NOTIFY_ERROR)
					return false
				end
			end
		end
	})
	
	self:RegisterEffect({
		Name = "kill",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer() and ent:Alive()) then ent:Kill() end
		end
	})
	
	
	self:AddHook("Think", function()
		for i,zone in pairs(MODULE.Zones) do
			for ipl,ent in pairs(ents.FindInBox(zone.Bound.Point1, zone.Bound.Point2)) do
				if(ent:IsPlayer()) then
					if(zone.ActivePlayers[ent:SteamID()] == nil) then
						zone.ActivePlayers[ent:SteamID()] = {}
						hook.Call("Vermilion_Player_Entered_Zone", nil, zone, ent)
					end
				end
				if(zone.ActiveObjects[ent:EntIndex()] == nil) then
					zone.ActiveObjects[ent:EntIndex()] = {}
					hook.Call("Vermilion_Object_Entered_Zone", nil, zone, ent)
				end
				for effect,pars in pairs(zone.Effects) do
					MODULE.EffectDefinitions[effect].Handler(zone, ent, pars)
				end
			end
			for ipl,ent in pairs(zone.ActivePlayers) do
				local tplayer = VToolkit.LookupPlayerBySteamID(ipl)
				if(IsValid(tplayer)) then
					if(not zone.Bound:IsInside(tplayer)) then
						hook.Call("Vermilion_Player_Left_Zone", nil, zone, tplayer)
						zone.ActivePlayers[ipl] = nil
					end
				else
					zone.ActivePlayers[ipl] = nil
				end
			end
			for ipl,ent in pairs(zone.ActiveObjects) do
				local tEnt = ents.GetByIndex(ipl)
				if(IsValid(tEnt)) then
					if(not zone.Bound:IsInside(tEnt)) then
						hook.Call("Vermilion_Object_Left_Zone", nil, zone, tEnt)
						zone.ActiveObjects[ipl] = nil
					end
				else
					zone.ActiveObjects[ipl] = nil
				end
			end
		end
	end)
	
	self:AddHook("PlayerInitialSpawn", function( vplayer )
		timer.Simple(2, function() MODULE:UpdateClients(vplayer) end)
	end)
	
	self:AddHook(Vermilion.Event.ShuttingDown, function()
		MODULE:SaveSettings()
	end)
	
	MODULE:LoadSettings()
end

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "addzone",
		Description = "Creates a new zone",
		Syntax = "[name] (only valid on second execution)",
		Permissions = { "zone_manager" },
		CanMute = true,
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(MODULE.Point1[sender:SteamID()] == nil) then
				MODULE.Point1[sender:SteamID()] = sender:GetPos()
				if(IsValid(sender)) then log("Set point 1. Use !cancelzone to stop drawing the zone and !addzone <name> to define the second point.") end
				MODULE:NetStart("VDrawCreateBlocks")
				net.WriteTable( { sender:GetPos().x, sender:GetPos().y, sender:GetPos().z } )
				net.Send(sender)
			else
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
				if(table.Count(text) < 1) then
					log("Must provide a name for this zone.")
					return
				end
				if(MODULE.Zones[text[1]] != nil) then
					log("This zone already exists! Enter a different name. (Note: you don't have to select the first point again!)")
					return
				end
				MODULE:NewZone(p1t, p2t, text[1], sender:SteamID())
				MODULE.Point1[sender:SteamID()] = nil
				glog(sender:GetName() .. " created a new zone called '" .. text[1] .. "'!")
				MODULE:NetStart("VDrawCreateBlocks")
				net.WriteTable( { nil, nil, nil } )
				net.Send(sender)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "cancelzone",
		Description = "Stops the zone definition process",
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(MODULE.Point1[sender:SteamID()] == nil) then
				log("You are not creating a zone.", NOTIFY_ERROR)
				return
			end
			MODULE.Point1[sender:SteamID()] = nil
			log("Zone creation cancelled!")
			MODULE:NetStart("VDrawCreateBlocks")
			net.WriteTable({ nil, nil, nil })
			net.Send(sender)
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "removezone",
		Description = "Removes a zone.",
		Syntax = "<zone>",
		Permissions = { "zone_manager" },
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(MODULE.Zones[text[1]] == nil) then
				log("Zone does not exist!", NOTIFY_ERROR)
				return false
			end
			MODULE.Zones[text[1]] = nil
			glog(sender:GetName() .. " has removed the zone '" .. text[1] .. "'")
			MODULE:UpdateClients()
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "listmodes",
		Description = "Lists the modes applied to the zone",
		Syntax = "<zone>",
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(MODULE.Zones[text[1]] == nil) then
				log("This zone does not exist!", NOTIFY_ERROR)
				return
			end
			local tab = {}
			for i,k in pairs(MODULE.Zones[text[1]].Effects) do
				table.insert(tab, i)
			end
			log("Active modes: " .. table.concat(tab, ", "))
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "setmode",
		Description = "Sets a mode on a zone",
		Syntax = "<zone> <mode> [parameters]",
		Permissions = { "zone_manager" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
			if(pos == 2) then
				if(MODULE.Zones[all[1]] == nil) then
					return { { Name = "", Syntax = "Parameter 1 is invalid!" } }
				end
				return VToolkit.FilterTable(VToolkit.MatchStringPart(table.GetKeys(MODULE.EffectDefinitions), current), function(k, v) return not MODULE.Zones[all[1]]:HasEffect(v) end)
			end
			if(pos >= 3) then
				if(MODULE.EffectDefinitions[all[2]] == nil) then
					return { { Name = "", Syntax = "Parameter 2 is invalid!" } }
				end
				if(MODULE.EffectDefinitions[all[2]].Predictor != nil) then
					return MODULE.EffectDefinitions[all[2]].Predictor(pos, current, all, vplayer)
				end
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.Zones[text[1]] == nil) then
				log("This zone does not exist!", NOTIFY_ERROR)
				return
			end
			if(MODULE.Zones[text[1]]:HasEffect(text[2])) then
				log("This zone already has this mode enabled!", NOTIFY_ERROR)
				return
			end
			if(MODULE.EffectDefinitions[text[2]] == nil) then
				log("This mode does not exist!", NOTIFY_ERROR)
				return
			end
			if(MODULE.EffectDefinitions[text[2]].PropValidator != nil) then
				if(MODULE.EffectDefinitions[text[2]].PropValidator(sender, text, log, glog) == false) then return false end
			end
			local props = table.Copy(text)
			table.remove(props, 1)
			table.remove(props, 1)
			MODULE.Zones[text[1]]:AddEffect(text[2], props)
			log("Zone updated!")
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "unsetmode",
		Description = "Removes a mode from a zone",
		Syntax = "<zone> <mode>",
		Permissions = { "zone_manager" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
			if(pos == 2) then
				local tab = {}
				if(MODULE.Zones[all[1]] == nil) then
					table.insert(tab, { Name = "", Syntax = "This zone doesn't exist." })
					return tab
				end
				for i,k in pairs(MODULE.Zones[all[1]].Effects) do
					if(string.find(string.lower(i), string.lower(current))) then
						table.insert(tab, i)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.Zones[text[1]] == nil) then
				log("This zone does not exist!", NOTIFY_ERROR)
				return
			end
			if(MODULE.EffectDefinitions[text[2]] == nil) then
				log("This mode does not exist!", NOTIFY_ERROR)
				return
			end
			if(not MODULE.Zones[text[1]]:HasEffect(text[2])) then
				log("This zone doesn't have this mode enabled!", NOTIFY_ERROR)
				return
			end
			MODULE.Zones[text[1]]:RemoveEffect(text[2])
			log("Zone updated!")
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "listzones",
		Description = "Lists all zones",
		Function = function(sender, text, log, glog)
			local tab = {}
			for i,k in pairs(MODULE.Zones) do
				if(k.Map == game.GetMap()) then
					table.insert(tab, i)
				else
					table.insert(tab, i .. " (not active in this map)")
				end
			end
			log("Active zones: " .. table.concat(tab, ", "))
		end
	})
	
	
end

function MODULE:InitClient()
	CreateClientConVar("vermilion_render_zones", 1, true, false)
	
	self:NetHook("VUpdateBlocks", function()
		print("Got zone update!")
		local stab = {}
		for i,k in pairs(net.ReadTable()) do
			table.insert(stab, VToolkit.CBound(k[1], k[2]))
		end
		MODULE.Zones = stab
	end)
	
	self:NetHook("VDrawCreateBlocks", function()
		local vec = net.ReadTable()
		if(vec[1] == nil and vec[2] == nil and vec[3] == nil) then
			MODULE.DrawingFrom = nil
		else
			MODULE.DrawingFrom = Vector(vec[1], vec[2], vec[3])
		end
	end)
	
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		if(Vermilion:GetModule("client_settings") != nil) then
			Vermilion:GetModule("client_settings"):AddOption("vermilion_render_zones", "Render Zones in the world", "Checkbox", "Features")
		end
	end)
	
	self:AddHook("PostDrawOpaqueRenderables", function(bDrawingDepth, bDrawingSkybox)
		if(bDrawingSkybox or bDrawingDepth or GetConVarNumber("vermilion_render_zones") == 0) then return end
		for i,k in pairs(MODULE.Zones) do
			cam.Start3D2D(k.Point1, Angle(0, 0, 0), 1)
				render.SetMaterial(MODULE.DrawEffect)
				render.DrawBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), (k.Point2 - k.Point1) * Vector(1, -1, 1), Color(0, 0, 0, 255), false)
			cam.End3D2D()
		end
		if(MODULE.DrawingFrom != nil) then
			cam.Start3D2D(MODULE.DrawingFrom, Angle(0, 0, 0), 1)
				local colour = Color(0, 0, 0, 255)
				local p1 = MODULE.DrawingFrom
				local p2 = LocalPlayer():GetPos()
				render.DrawWireframeBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), (p2 - p1) * Vector(1, -1, 1), colour, false)
			cam.End3D2D()
		end
	end)
	
	self:NetCommand("VUpdateBlocks")
end

Vermilion:RegisterModule(MODULE)