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
MODULE.Name = "Trouble in Terrorist Town"
MODULE.ID = "ttt"
MODULE.Description = "Integrates with TTT"
MODULE.Author = "Ned"
if(engine.ActiveGamemode() == "terrortown") then
	MODULE.Permissions = {
		"settraitor",
		"setdetective",
		"setinnocent",
		"setcredits",
		"restartround",
		"haste",
		"roundtime"
	}
	MODULE.PermissionDefinitions = {
		["settraitor"] = "This player can use the settraitor chat command in Trouble In Terrorist Town.",
		["setdetective"] = "This player can use the setdetective chat command in Trouble In Terrorist Town.",
		["setinnocent"] = "This player can use the setinnocent chat command in Trouble In Terrorist Town.",
		["setcredits"] = "This player can use the setcredits chat command in Trouble In Terrorist Town.",
		["restartround"] = "This player can use the restartround chat command in Trouble In Terrorist Town.",
		["haste"] = "This player can use the haste chat command in Trouble In Terrorist Town.",
		["roundtime"] = "This player can use the roundtime chat command in Trouble In Terrorist Town."
	}
end

function MODULE:InitServer()
	if(engine.ActiveGamemode() != "terrortown") then 
		Vermilion.Log("Not loading TTT Integration; not running TTT.")
		return
	end
	
	Vermilion:AddChatCommand({
		Name = "settraitor",
		Description = "Makes a player a traitor",
		Syntax = "<player>",
		Permissions = { "settraitor" },
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
				target:SetRole(ROLE_TRAITOR)
				SendFullStateUpdate()
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "setdetective",
		Description = "Makes a player a detective",
		Syntax = "<player>",
		Permissions = { "setdetective" },
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
				target:SetRole(ROLE_DETECTIVE)
				SendFullStateUpdate()
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "setinnocent",
		Description = "Makes a player a innocent",
		Syntax = "<player>",
		Permissions = { "setinnocent" },
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
				target:SetRole(ROLE_INNOCENT)
				SendFullStateUpdate()
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "setcredits",
		Description = "Set the player's credits",
		Syntax = "<player> <credits>",
		Permissions = { "setcredits" },
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
			local credits = tonumber(text[2])
			if(credits == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(not Vermilion:GetUser(target):IsImmune(sender)) then
				target:SetCredits(credits)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "restartround",
		Description = "Restart the round.",
		Syntax = "",
		Permissions = { "restartround" },
		Function = function(sender, text, log, glog)
			RunConsoleCommand("ttt_roundrestart")
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "haste",
		Description = "Change haste mode.",
		Syntax = "<true|false>",
		Permissions = { "haste" },
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local res = tobool(text[1])
			if(res == nil) then
				log(Vermilion:TranslateStr("not_bool", nil, sender), NOTIFY_ERROR)
				return
			end
			if(res) then
				RunConsoleCommand("ttt_haste", 1)
			else
				RunConsoleCommand("ttt_haste", 0)
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "roundtime",
		Description = "Change round time.",
		Syntax = "<minutes>",
		Permissions = { "roundtime" },
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local res = tonumber(text[1])
			if(res == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return
			end
			RunConsoleCommand("ttt_roundtime_minutes", res)
		end
	})
	
end

Vermilion:RegisterModule(MODULE)