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
MODULE.Name = "Commands"
MODULE.ID = "commands"
MODULE.Description = "Provides some basic commands."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"tplook",
	"tppos",
	"teleport",
	"goto",
	"bring",
	"conditional_teleport",
	"speed",
	"respawn",
	"private_message",
	"getpos",
	"sudo",
	"spectate",
	"vanish",
	"convar",
	"set_deaths",
	"set_frags",
	"set_armour",
	"clear_decals",
	"kickvehicle",
	"ignite",
	"extinguish",
	"suicide"
}

MODULE.TeleportRequests = {}
MODULE.PrivateMessageHistory = {}

function MODULE:RegisterChatCommands()
	
	Vermilion:AddChatCommand({
		Name = "tplook",
		Description = "Teleports players to a look position.",
		Syntax = "[player to move] [player reference]",
		CanMute = true,
		Permissions = { "tplook" },
		AllValid = { 
			{ Size = 1, Indexes = {} },
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1 or pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local eyeTarget = sender
			if(table.Count(text) > 0) then
				target = VToolkit.LookupPlayer(text[1])
				if(table.Count(text) > 1) then
					eyeTarget = VToolkit.LookupPlayer(text[2])
				end
			end
			if(not IsValid(target) or not IsValid(eyeTarget)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			local trace = eyeTarget:GetEyeTrace()
			if(trace.Hit) then
				if(not Vermilion:GetUser(target):IsImmune(sender)) then
					local targetPhrase = ""
					if(sender == eyeTarget) then
						targetPhrase = "his/her look position."
					else
						targetPhrase = eyeTarget:GetName() .. "'s look position."
					end
					glog(sender:GetName() .. " teleported " .. target:GetName() .. " to " .. targetPhrase)
					target:SetPos(trace.HitPos)
				end
			else
				return false
			end
		end,
		AllBroadcast = function(sender, text)
			local eyeTarget = sender
			if(table.Count(text) > 1) then
				eyeTarget = VToolkit.LookupPlayer(text[2])
			end
			if(IsValid(eyeTarget)) then
				return "All players were teleported to " .. eyeTarget:GetName() .. "'s look position."
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "tppos",
		Description = "Teleports players to exact coordinates.",
		Syntax = "[player] <x> <y> <z>",
		CanMute = true,
		Permissions = { "tppos" },
		AllValid = {
			{ Size = 4, Indexes = { 1 } },
			{ Size = nil, Indexes = {} }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local coordinates = { text[1], text[2], text[3] }
			if(table.Count(text) > 3) then
				target = VToolkit.LookupPlayer(text[1])
				coordinates = { text[2], text[3], text[4] }
			end
			for i,k in pairs(coordinates) do
				if(tonumber(k) == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return false
				end
			end
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			
			local vector = Vector(tonumber(coordinates[1]), tonumber(coordinates[2]), tonumber(coordinates[3]))
			if(not util.IsInWorld(vector)) then
				log("Cannot put player here; it is outside of the world.", NOTIFY_ERROR)
				return false
			end
			if(not Vermilion:GetUser(target):IsImmune(sender)) then
				glog(sender:GetName() .. " teleported " .. target:GetName() .. " to " .. table.concat(coordinates, ":"))
				target:SetPos(vector)
			end
		end,
		AllBroadcast = function(sender, text)
			coordinates = { text[2], text[3], text[4] }
			return sender:GetName() .. " teleported all players to " .. table.concat(coordinates, ":")
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "teleport",
		Description = "Teleports a player to another player",
		Syntax = "[player to move] <player to move to>",
		CanMute = true,
		Permissions = { "teleport" },
		AllValid = {
			{ Size = 2, Indexes = { 1 } },
			{ Size = nil, Indexes = { } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1 or pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local mtarget = nil
			local ptarget = nil
			
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			
			if(table.Count(text) == 1) then
				ptarget = VToolkit.LookupPlayer(text[1])
				mtarget = sender
			elseif(table.Count(text) > 1) then
				ptarget = VToolkit.LookupPlayer(text[2])
				mtarget = VToolkit.LookupPlayer(text[1])
			end
			
			local target = ptarget:GetPos() + Vector(0, 0, 100)
			
			if(not IsValid(mtarget) or not IsValid(ptarget)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return false
			end
			
			if(not Vermilion:GetUser(mtarget):IsImmune(sender)) then
				glog(sender:GetName() .. " teleported " .. mtarget:GetName() .. " to " .. ptarget:GetName())
				mtarget:SetPos(target)
			end
		end,
		AllBroadcast = function(sender, text)
			local target = VToolkit.LookupPlayer(text[2])
			if(IsValid(target)) then
				return sender:GetName() .. " teleported all players to " .. target:GetName()
			end
		end
	})
	
	Vermilion:AliasChatCommand("teleport", "tp")
	
	Vermilion:AddChatCommand({
		Name = "goto",
		Description = "Teleport yourself to a player",
		Syntax = "<player to go to>",
		CanMute = true,
		Permissions = { "goto" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			glog(sender:GetName() .. " teleported to " .. target:GetName())
			sender:SetPos(target:GetPos() + Vector(0, 0, 100))
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "bring",
		Description = "Bring a player to you",
		Syntax = "<player to bring>",
		CanMute = true,
		Permissions = { "bring" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(not Vermilion:GetUser(target):IsImmune(sender)) then
				glog(sender:GetName() .. " brought " .. target:GetName() .. " to him/herself.")
				target:SetPos(sender:GetPos() + Vector(0, 0, 100))
			end
		end,
		AllBroadcast = function(sender, text)
			return sender:GetName() .. " brought all players to him/herself."
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "tpquery",
		Description = "Asks a player if you can teleport to them.",
		Syntax = "<player>",
		CanRunOnDS = false,
		Permissions = { "conditional_teleport" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, self), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, self), NOTIFY_ERROR)
				return
			end
			if(not Vermilion:HasPermission(target, "conditional_teleport")) then
				log("This player doesn't have the permission to respond to teleport requests.", NOTIFY_ERROR)
				return
			end
			log("Sent request!")
			MODULE.TeleportRequests[sender:SteamID() .. target:SteamID()] = false
			Vermilion:AddNotification(target, sender:GetName() .. " is requesting to teleport to you...", NOTIFY_HINT)
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "tpaccept",
		Description = "Accept a teleport request",
		Syntax = "<player>",
		CanRunOnDS = false,
		Permissions = { "conditional_teleport" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE.TeleportRequests) do
					if(string.StartWith(i, vplayer:SteamID()) and not k) then
						local tplayer = VToolkit.LookupPlayerBySteamID(string.Replace(i, vplayer:SteamID(), ""))
						if(IsValid(tplayer)) then
							if(string.find(string.lower(tplayer:GetName()), string.lower(current))) then
								table.insert(tab, tplayer:GetName())
							end
						end
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == nil) then
				log("This player has not asked to teleport to you.", NOTIFY_ERROR)
				return false
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == true) then
				log("This player has already teleported to you and the ticket has been cancelled!", NOTIFY_ERROR)
				return false
			end
			Vermilion:AddNotification({sender, target}, "Request accepted! Teleporting in 10 seconds.")
			local sPos = sender:GetPos()
			local tPos = target:GetPos()
			timer.Simple(10, function()
				if(sPos != sender:GetPos() or tPos != target:GetPos()) then
					Vermilion:AddNotification({sender, target}, "Someone moved. Teleportation cancelled!", NOTIFY_ERROR)
					MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] = true
					return
				end
				Vermilion:AddNotification({sender, target}, "Teleporting...")
				target:SetPos(sender:GetPos() + Vector(0, 0, 90))
				MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] = true
			end)
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "tpdeny",
		Description = "Denies a teleport request",
		Syntax = "<player>",
		CanRunOnDS = false,
		Permissions = { "conditional_teleport" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE.TeleportRequests) do
					if(string.StartWith(i, vplayer:SteamID()) and not k) then
						local tplayer = VToolkit.LookupPlayerBySteamID(string.Replace(i, vplayer:SteamID(), ""))
						if(IsValid(tplayer)) then
							if(string.find(string.lower(tplayer:GetName()), string.lower(current))) then
								table.insert(tab, tplayer:GetName())
							end
						end
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == nil) then
				log("This player has not asked to teleport to you.", NOTIFY_ERROR)
				return
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == true) then
				log("This player has already teleported to you and the ticket has been cancelled!", NOTIFY_ERROR)
				return
			end
			Vermilion:AddNotification({sender, target}, "Request denied!")
			MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] = true
		end
	})
	
	Vermilion:AliasChatCommand("tpquery", "tpq")
	Vermilion:AliasChatCommand("tpaccept", "tpa")
	Vermilion:AliasChatCommand("tpdeny", "tpd")
	
	Vermilion:AddChatCommand({
		Name = "speed",
		Description = "Changes player speed",
		Syntax = "<speed multiplier> [player]",
		CanMute = true,
		Permissions = { "speed" },
		AllValid = {
			{ Size = 2, Indexes = { 2 } },
			{ Size = nil, Indexes = { } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local times = tonumber(text[1])
			if(times == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = sender
			if(table.Count(text) > 1) then
				local tplayer = VToolkit.LookupPlayer(text[2])
				if(tplayer == nil or not IsValid(tplayer)) then
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			local speed = math.abs(200 * times)
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			GAMEMODE:SetPlayerSpeed(target, speed, speed * 2)
			if(sender == target) then
				glog(sender:GetName() .. " set his/her speed to " .. tostring(times) .. "x normal speed.")
			else
				glog(sender:GetName() .. " set the speed of " .. target:GetName() .. " to " .. tostring(times) .. "x normal speed.")
			end
		end,
		AllBroadcast = function(sender, text)
			return sender:GetName() .. " set the speed of all players to " .. tostring(text[1]) .. "x normal speed."
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "respawn",
		Description = "Forces a player to respawn",
		Syntax = "[player]",
		CanMute = true,
		Permissions = { "respawn" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			if(table.Count(text) > 0) then
				local tplayer = VToolkit.LookupPlayer(text[1])
				if(tplayer == nil or not IsValid(tplayer)) then
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			if(IsValid(target)) then
				if(Vermilion:GetUser(target):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				glog(sender:GetName() .. " forced " .. target:GetName() .. " to respawn.")
				target:Spawn()
			end
		end,
		AllBroadcast = function(sender, text)
			return sender:GetName() .. " forced all players to respawn."
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "pm",
		Description = "Sends a private message",
		Syntax = "<target> <message>",
		Permissions = { "private_message" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = VToolkit.MatchPlayerPart(current)
				table.RemoveByValue(tab, vplayer:GetName())
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			target:ChatPrint("[Private] " .. sender:GetName() .. ": " .. table.concat(text, " ", 2))
			MODULE.PrivateMessageHistory[target:SteamID()] = sender:SteamID()
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "r",
		Description = "Replies to the last pm you were sent.",
		Syntax = "<message>",
		Permissions = { "private_message" },
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayerBySteamID(MODULE.PrivateMessageHistory[sender:SteamID()])
			if(not IsValid(target)) then
				log("You haven't received a private message yet or the player has left the server!", NOTIFY_ERROR)
				return
			end
			target:ChatPrint("[Private]" .. sender:GetName() .. ": " .. table.concat(text, " "))
			MODULE.PrivateMessageHistory[target:SteamID()] = sender:SteamID()
			
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "time",
		Description = "Prints the server time.",
		Function = function(sender, text, log, glog)
			log("The server time is: " .. os.date("%I:%M:%S %p on %d/%m/%Y"))
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "getpos",
		Description = "Get the position of a player",
		Syntax = "[player]",
		Permissions = { "getpos" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			if(table.Count(text) > 0) then
				target = VToolkit.LookupPlayer(text[1])
			end
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			local pos = target:GetPos()
			if(target == sender) then
				log("Your position is " .. table.concat({ math.Round(pos.x), math.Round(pos.y), math.Round(pos.z) }, ":"))
			else
				log(target:GetName() .. "'s position is " .. table.concat({ math.Round(pos.x), math.Round(pos.y), math.Round(pos.z) }, ":"))
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "sudo",
		Description = "Makes another player run a chat command.",
		Syntax = "<player> <command>",
		Permissions = { "sudo" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = VToolkit.MatchPlayerPart(current)
				table.RemoveByValue(tab, vplayer:GetName())
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			local cmd = table.concat(text, " ", 2)
			if(not string.StartWith(cmd, Vermilion:GetData("chat_prefix", "!", true))) then
				cmd = Vermilion:GetData("chat_prefix", "!", true) .. cmd
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			Vermilion:HandleChat(target, cmd, log, false)
		end
	})
	
	local bannedSpecClassses = { -- these should not be spectateable from the command. Yes. I can make up words. "spectateable" is now a new word by order of me. Because I obviously have the authority to do that.
		"filter_",
		"worldspawn",
		"soundent",
		"player_",
		"bodyque",
		"network",
		"sky_camera",
		"info_",
		"env_",
		"predicted_",
		"scene_",
		"gmod_gamerules",
		"shadow_",
		"weapon_",
		"gmod_tool",
		"gmod_camera",
		"gmod_hands",
		"physgun_beam",
		"phys_",
		"hint",
		"spotlight_",
		"path_",
		"lua_",
		"func_brush",
		"light",
		"point_"
	}
	
	Vermilion:AddChatCommand({
		Name = "spectate",
		Description = "Allows you to spectate stuff",
		Syntax = "[-entity <entityid>] [-player <name>]",
		CanMute = true,
		CanRunOnDS = false,
		Permissions = { "spectate" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return { "-entity", "-player" }
			end
			if(pos == 2 and all[1] == "-entity") then
				local tab = {}
				for i,k in pairs(ents.GetAll()) do
					local banned = false
					for i1,k1 in pairs(bannedSpecClassses) do
						if(string.StartWith(k:GetClass(), k1)) then
							banned = true
							break
						end
					end
					if(banned) then continue end
					if(string.StartWith(tostring(k:EntIndex()), current)) then
						table.insert(tab, {Name = tostring(k:EntIndex()), Syntax = "(" .. k:GetClass() .. ")"})
					end
				end
				return tab
			end
			if(pos == 2 and all[1] == "-player") then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)		
			if(text[1] == "-entity") then
				if(tonumber(text[2]) == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				local tent = ents.GetByIndex(tonumber(text[2]))
				if(IsValid(tent)) then
					for i,k in pairs(bannedSpecClassses) do
						if(string.StartWith(tent:GetClass(), k)) then
							log("You cannot spectate this entity!", NOTIFY_ERROR)
							return
						end
					end
					sender.SpectateOriginalPos = sender:GetPos()
					log("You are now spectating " .. tent:GetClass())
					sender:Spectate( OBS_MODE_CHASE )
					sender:SpectateEntity( tent )
					sender:StripWeapons()
					sender.VSpectating = true
				else
					log("That isn't a valid entity.", NOTIFY_ERROR)
				end
			elseif(text[1] == "-player") then
				local tplayer = VToolkit.LookupPlayer(text[2])
				if(tplayer == sender) then
					log("You cannot spectate yourself!", NOTIFY_ERROR)
					return
				end
				if(IsValid(tplayer)) then
					sender.SpectateOriginalPos = sender:GetPos()
					sender:Spectate( OBS_MODE_CHASE )
					sender:SpectateEntity( tplayer )
					sender:StripWeapons()
					sender.VSpectating = true
				else
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				end
			else
				log("Invalid type!")
			end
		end
	})
	
	self:AddHook("EntityRemoved", function(ent)
		for i,k in pairs(player.GetAll()) do
			if(k.VSpectating == true and k:GetObserverTarget() == ent) then
				k:UnSpectate()
				k:Spawn()
				k:SetPos(k.SpectateOriginalPos)
				k.VSpectating = false
				Vermilion:AddNotification(k, "The entity you were spectating was removed.")
			end
		end
	end)
	
	Vermilion:AddChatCommand({
		Name = "unspectate",
		Description = "Stops spectating an entity",
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(not sender.VSpectating) then
				log("You aren't spectating anything...")
				return
			end
			sender:UnSpectate()
			sender:Spawn()
			sender:SetPos(sender.SpectateOriginalPos)
			sender.VSpectating = false
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "vanish",
		Description = "Makes you invisible to other players.",
		CanRunOnDS = false,
		Permissions = { "vanish" },
		Function = function(sender, text, log, glog)
			if(sender:GetRenderMode() == RENDERMODE_NORMAL) then
				sender:SetRenderMode(RENDERMODE_NONE)
				for i,k in pairs(player.GetAll()) do
					sender:SetPreventTransmit(k, true)
				end
			else
				sender:SetRenderMode(RENDERMODE_NORMAL)
				for i,k in pairs(player.GetAll()) do
					sender:SetPreventTransmit(k, false)
				end
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "steamid",
		Description = "Gets the steamid of a player",
		Syntax = "[player]",
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) == 0) then
				log("Your SteamID is " .. tostring(sender:SteamID()))
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				log(tplayer:GetName() .. "'s SteamID is " .. tostring(tplayer:SteamID()))
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "ping",
		Description = "Gets the ping of a player.",
		Syntax = "[player]",
		CanRunOnDS = false,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) == 0) then
				log("Your ping is " .. tostring(sender:Ping()) .. "ms")
			else
				local tplayer = VToolkit.LookupPlayer(text[1])
				if(IsValid(tplayer)) then
					log(tplayer:GetName() .. "'s ping is " .. tostring(tplayer:Ping()) .. "ms")
				else
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				end
			end
		end
	})
	
	local allowed = {
		"gm_",
		"sbox_",
		"sv_"
	}
	
	Vermilion:AddChatCommand({
		Name = "convar",
		Description = "Modifies server convars",
		Syntax = "<cvar> [value]",
		Permissions = { "convar" },
		CanMute = true,
		Function = function(sender, text, log, glog)
			if(table.Count(text) == 1) then
				if(not ConVarExists(text[1])) then
					log("This convar doesn't exist!", NOTIFY_ERROR)
				else
					log(text[1] .. " is set to " .. cvars.String(text[1]))
				end
			elseif(table.Count(text) > 1) then
				if(ConVarExists(text[1])) then
					local allowed = false
					for i,k in pairs(allowed) do
						if(string.StartWith(text[1], k)) then
							allowed = true
							break
						end
					end
					if(not allowed) then
						log("Cannot set the value of this convar.", NOTIFY_ERROR)
						return
					end
					RunConsoleCommand(text[1], text[2])
					glog(sender:GetName() .. " set " .. text[1] .. " to " .. text[2])
				else
					log("This convar doesn't exist!", NOTIFY_ERROR)
				end
			else
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "deaths",
		Description = "Set the deaths for a player.",
		Syntax = "<player> <deaths>",
		Permissions = { "set_deaths" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				local result = tonumber(text[2])
				if(result == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:SetDeaths(result)
				glog(sender:GetName() .. " set " .. text[1] .. "'s death count to " .. text[2])
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "frags",
		Description = "Set the frags for a player.",
		Syntax = "<player> <frags>",
		Permissions = { "set_frags" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				local result = tonumber(text[2])
				if(result == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:SetFrags(result)
				glog(sender:GetName() .. " set " .. text[1] .. "'s frag count to " .. text[2])
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "armour",
		Description = "Set the armour for a player.",
		Syntax = "<player> <armour>",
		Permissions = { "set_armour" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				local result = tonumber(text[2])
				if(result == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:SetArmor(result)
				glog(sender:GetName() .. " set " .. text[1] .. "'s armour to " .. text[2])
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "decals",
		Description = "Clears the decals",
		Permissions = { "clear_decals" },
		CanMute = true,
		Function = function(sender, text, log, glog)
			for i,k in pairs(VToolkit.GetValidPlayers()) do
				k:ConCommand("r_cleardecals")
			end
			glog(sender:GetName() .. " cleared up the decals.")
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "kickvehicle",
		Description = "Kicks a player from their vehicle.",
		Syntax = "<player>",
		Permissions = { "kickvehicle" },
		CanMute = true,
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current, function(p) return p:InVehicle() end)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				if(not tplayer:InVehicle()) then
					log("This player isn't in a vehicle!", NOTIFY_ERROR)
					return
				end
				tplayer:ExitVehicle()
				glog(sender:GetName() .. " kicked " .. sender:GetName() .. " from his/her vehicle.")
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "ignite",
		Description = "Set a player on fire.",
		Syntax = "<player> <time:seconds>",
		Permissions = { "ignite" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current, function(p) return not p:IsOnFire() end)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local result = tonumber(text[2])
			if(result == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				tplayer:Ignite(result, 5)
				glog(sender:GetName() .. " set " .. tplayer:GetName() .. " on fire for " .. tostring(result) .. " seconds.")
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "extinguish",
		Description = "Stops a player from being on fire.",
		Syntax = "<player>",
		CanMute = true,
		Permissions = { "extinguish" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current, function(p) return p:IsOnFire() end)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				tplayer:Extinguish()
				glog(sender:GetName() .. " extinguished " .. tplayer:GetName())
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "random",
		Description = "Generates a pseudo-random number.",
		Syntax = "[min] <max>",
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local min = 0
			local max = 0
			if(table.Count(text) == 1) then
				max = tonumber(text[1])
			else
				min = tonumber(text[1])
				max = tonumber(text[2])
			end
			
			if(min == nil or max == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
			
			log("Number: " .. tostring(math.random(min, max)))
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "suicide",
		Description = "Kills the player that sends the command.",
		Permissions = { "suicide" },
		CanMute = true,
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			sender:ConCommand("kill")
			glog(sender:GetName() .. " killed him/herself.")
		end
	})
end

function MODULE:InitClient()
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		local mod = Vermilion:GetModule("playermanagement")
		if(mod == nil) then return end
		
		mod:AddDefinition("getpos", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local button = VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!getpos \"" .. k:GetValue(1) .. "\"")
					end
				end)
				panel:Add(button)
			end
		})
		
		mod:AddDefinition("time", "Utils", {
			Stage1 = function(panel)
				local button = VToolkit:CreateButton("Run", function()
					mod:SendChat("!time")
				end)
				panel:Add(button)
			end
		})
		
		mod:AddDefinition("pm", "Chat", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local text = VToolkit:CreateTextbox()
				panel:Add(text)
				
				panel:Add(VToolkit:CreateButton("Send", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!pm \"" .. k:GetValue(1) .. "\" " .. text:GetValue())
					end
				end))
			end
		})
		
		mod:AddDefinition("spectate", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					if(IsValid(playerlist:GetSelected()[1])) then
						mod:SendChat("!spectate -player \"" .. playerlist:GetSelected()[1]:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("tplook", "Teleport", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local tplayerCB = VToolkit:CreateComboBox(VToolkit.GetPlayerNames(), 1)
				panel:Add(tplayerCB)
				
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!tplook \"" .. k:GetValue(1) .. "\" \"" .. tplayerCB:GetValue() .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("tppos", "Teleport", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local coordinatepanel = vgui.Create("DPanel")
				coordinatepanel:SetDrawBackground(false)
				panel:Add(coordinatepanel)
				
				local xpos = VToolkit:CreateNumberWang()
				coordinatepanel:Add(xpos)
				xpos:Dock(LEFT)
				xpos:DockMargin(5, 0, 5, 0)
				
				local ypos = VToolkit:CreateNumberWang()
				coordinatepanel:Add(ypos)
				ypos:DockMargin(5, 0, 5, 0)
				ypos:Dock(LEFT)
				
				local zpos = VToolkit:CreateNumberWang()
				coordinatepanel:Add(zpos)
				zpos:Dock(LEFT)
				zpos:DockMargin(5, 0, 5, 0)
				
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!tppos \"" .. k:GetValue(1) .. "\" " .. table.concat({ xpos:GetValue(), ypos:GetValue(), zpos:GetValue() }, " "))
					end
				end))
			end
		})
		
		mod:AddDefinition("teleport", "Teleport", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local tplayerCB = VToolkit:CreateComboBox(VToolkit.GetPlayerNames(), 1)
				panel:Add(tplayerCB)
				
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!tp \"" .. k:GetValue(1) .. "\" \"" .. tplayerCB:GetValue() .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("goto", "Teleport", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					if(IsValid(playerlist:GetSelected()[1])) then
						mod:SendChat("!goto \"" .. playerlist:GetSelected()[1]:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("bring", "Teleport", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!bring \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("speed", "Fun", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local multiplier = VToolkit:CreateSlider("Multiplier", 0.1, 20, 2)
				panel:Add(multiplier)
				
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!speed " .. tostring(multiplier:GetValue()) .. " \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("respawn", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!respawn \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("steamid", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!steamid \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("ping", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!ping \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("deaths", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local deathcount = VToolkit:CreateNumberWang(0)
				panel:Add(deathcount)
			
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!deaths \"" .. k:GetValue(1) .. "\" " .. tostring(deathcount:GetValue()))
					end
				end))
			end
		})
		
		mod:AddDefinition("frags", "Utils", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local fragcount = VToolkit:CreateNumberWang(0)
				panel:Add(fragcount)
			
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!frags \"" .. k:GetValue(1) .. "\" " .. tostring(fragcount:GetValue()))
					end
				end))
			end
		})
		
		mod:AddDefinition("armour", "Fun", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local armour = VToolkit:CreateSlider("Armour", 0, 200, 0)
				panel:Add(armour)
			
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!armour \"" .. k:GetValue(1) .. "\" " .. tostring(armour:GetValue()))
					end
				end))
			end
		})
		
		mod:AddDefinition("decals", "Utils", {
			Stage1 = function(panel)
				local button = VToolkit:CreateButton("Run", function()
					mod:SendChat("!decals")
				end)
				panel:Add(button)
			end
		})
		
		mod:AddDefinition("kickvehicle", "Fun", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!kickvehicle \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		mod:AddDefinition("ignite", "Fun", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				local time = VToolkit:CreateSlider("Time", 0, 200, 1)
				panel:Add(time)
			
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!ignite \"" .. k:GetValue(1) .. "\" " .. tostring(time:GetValue()))
					end
				end))
			end
		})
		
		mod:AddDefinition("extinguish", "Fun", {
			Stage1 = "PLAYERLIST",
			Stage2 = function(panel, playerlist)
				panel:Add(VToolkit:CreateButton("Run", function()
					for i,k in pairs(playerlist:GetSelected()) do
						mod:SendChat("!extinguish \"" .. k:GetValue(1) .. "\"")
					end
				end))
			end
		})
		
		
		
	end)
end

Vermilion:RegisterModule(MODULE)