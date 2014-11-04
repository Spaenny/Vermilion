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
MODULE.Name = "Warps"
MODULE.ID = "warps"
MODULE.Description = "Create destinations that can be travelled to using commands."
MODULE.Author = "Ned (based on code written by Foxworrior)"
MODULE.Permissions = {
	"create_warp",
	"remove_warp",
	"warp",
	"warp_others"
}
MODULE.PermissionDefinitions = {
	["create_warp"] = "This player is able to create a warp.",
	["remove_warp"] = "This player is able to remove a warp.",
	["warp"] = "This player is able to use the warp command.",
	["warp_others"] = "This player is able to use the warp command on other players."
}

function MODULE:InitServer()
	Vermilion:AddChatCommand({
		Name = "addwarp",
		Description = "Add a new warp",
		Syntax = "<name>",
		Permissions = { "create_warp" },
		CanMute = true,
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(MODULE:GetData("warps", {}, true)[text[1]] != nil) then
				log("A warp with that name already exists.", NOTIFY_ERROR)
				return false
			end
			glog(sender:GetName() .. " added new warp '" .. text[1] .. "' at " .. table.concat({math.Round(sender:GetPos().x), math.Round(sender:GetPos().y), math.Round(sender:GetPos().z) }, ":"))
			MODULE:GetData("warps", {}, true)[text[1]] = { sender:GetPos().x, sender:GetPos().y, sender:GetPos().z }
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "removewarp",
		Description = "Remove a warp",
		Syntax = "<name>",
		Permissions = { "remove_warp" },
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE:GetData("warps", {}, true)), current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(MODULE:GetData("warps", {}, true)[text[1]] == nil) then
				log("That warp doesn't exist.", NOTIFY_ERROR)
				return false
			end
			log("Removed warp '" .. text[1] .. "'")
			MODULE:GetData("warps", {}, true)[text[1]] = nil
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "warp",
		Description = "Warps a player to a position",
		Syntax = "<warp> [player]",
		Permissions = { "warp" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 2 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE:GetData("warps", {}, true)), current)
			end
			if(pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = sender
			if(table.Count(text) > 1) then
				if(not Vermilion:HasPermission(sender, "warp_others")) then
					log("You cannot warp other players!", NOTIFY_ERROR)
					return false
				end
				target = VToolkit.LookupPlayer(text[2])
			end
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE:GetData("warps", {}, true)[text[1]] == nil) then
				log("No such warp!", NOTIFY_ERROR)
				return false
			end
			if(sender == target) then
				glog(sender:GetName() .. " warped to " .. text[1])
			else
				glog(sender:GetName() .. " warped " .. target:GetName() .. " to " .. text[1])
			end
			target:SetPos(Vector(unpack(MODULE:GetData("warps", {}, true)[text[1]])))
		end
	})
end

function MODULE:InitClient()
	
end

Vermilion:RegisterModule(MODULE)