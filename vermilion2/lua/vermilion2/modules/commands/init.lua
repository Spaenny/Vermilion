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
	"getpos"
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
					if(table.Count(target) == 1) then
						local targetPhrase = ""
						if(sender == eyeTarget) then
							targetPhrase = "their look position."
						else
							targetPhrase = eyeTarget:GetName() .. "'s look position."
						end
						glog(sender:GetName() .. " teleported " .. target:GetName() .. " to " .. targetPhrase)
					end
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
				glog(sender:GetName() .. " set their speed to " .. tostring(times) .. "x normal speed.")
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
				log("Your position is " .. table.concat({ pos.x, pos.y, pos.z }, ":"))
			else
				log(target:GetName() .. "'s position is " .. table.concat({ pos.x, pos.y, pos.z }, ":"))
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
	
	local bannedSpecClassses = {
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
		Function = function() end
	})
	
		
end

Vermilion:RegisterModule(MODULE)