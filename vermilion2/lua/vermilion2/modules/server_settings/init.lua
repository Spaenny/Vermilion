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

local MODULE = Vermilion:CreateBaseModule()
MODULE.Name = "Server Settings"
MODULE.ID = "server_settings"
MODULE.Description = "Provides a collection of basic options for administrating the server."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_server",
	"no_fall_damage",
	"reduced_fall_damage",
	"ignore_pvp_state",
	"no_damage",
	"unlimited_ammo",
	"enable_flashlight",
	"noclip",
	"can_spray",
	"chat",
	"use_voip",
	"hear_voip",
	
	"setnoclip",
	"setnoclip_others",
	"setfalldamage",
	"setfalldamage_others",
	"setdamage",
	"setdamage_others",
	"setflashlight",
	"setflashlight_others",
	"setuammo",
	"setuammo_others",
	
	
	
	"change_motd"
}
MODULE.NetworkStrings = {
	"VServerGetProperties", -- used to build the settings page
	"VServerUpdate",
	"VRequestMOTD",
	"VUpdateMOTD",
	"VUpdateMOTDSettings",
	"VGetMOTDProperties",
	"VGetCommandMuting",
	"VSetCommandMuting"
}
MODULE.DefaultPermissions = {
	{ Name = "admin", Permissions = {
			"no_fall_damage",
			"no_damage",
			"unlimited_ammo",
			"enable_flashlight",
			"noclip",
			"can_spray",
			"chat",
			"use_voip",
			"hear_voip",
			"setnoclip",
			"setnoclip_others",
			"setfalldamage",
			"setfalldamage_others",
			"setdamage",
			"setdamage_others",
			"setflashlight",
			"setflashlight_others",
			"setuammo",
			"setuammo_others"			
		}
	},
	{ Name = "player", Permissions = {
			"reduced_fall_damage",
			"enable_flashlight",
			"noclip",
			"can_spray",
			"chat",
			"use_voip",
			"hear_voip",
			"setnoclip",
			"setfalldamage",
			"setdamage",
			"setflashlight",
			"setuammo"
		}
	}
}



local categories = {
	{ Name = "Limits", Order = 0 },
	{ Name = "Immunity", Order = 1 },
	{ Name = "Misc", Order = 50 }
}

local options = {
	{ Name = "unlimited_ammo", GuiText = "Unlimited ammunition:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", Default = 3 },
	{ Module = "limit_spawn", Name = "enable_limit_remover", GuiText = "Spawn Limit Remover:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", Default = 3 },
	{ Name = "enable_no_damage", GuiText = "Disable Damage:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", Default = 3 },
	{ Name = "flashlight_control", GuiText = "Flashlight Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", Default = 4 },
	{ Name = "noclip_control", GuiText = "Noclip Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", Default = 4 },
	{ Name = "spray_control", GuiText = "Spray Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", Default = 4 },
	{ Name = "voip_control", GuiText = "VoIP Control:", Type = "Combobox", Options = {
			"Do not limit",
			"Globally Disable VoIP",
			"Globally Enable VoIP",
			"Permissions Based"
		}, Category = "Limits", Default = 4 },
	{ Name = "limit_chat", GuiText = "Chat Blocker:", Type = "Combobox", Options = {
			"Off",
			"Globally Disable Chat",
			"Permissions Based"
		}, Category = "Limits", Default = 3 },
	{ Name = "enable_lock_immunity", GuiText = "Lua Lock Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", Default = 3, Incomplete = true },
	{ Name = "enable_kill_immunity", GuiText = "Lua Kill Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", Default = 3, Incomplete = true },
	{ Name = "enable_kick_immunity", GuiText = "Lua Kick Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", Default = 3, Incomplete = true },
	{ Name = "disable_fall_damage", GuiText = "Fall Damage Modifier:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"All Players suffer reduced damage",
			"Permissions Based"
		}, Category = "Limits", Default = 4 },
	{ Name = "disable_owner_nag", GuiText = "Disable 'No owner detected' nag at startup", Type = "Checkbox", Category = "Misc", Default = false, Incomplete = true },
	{ Name = "player_collision_mode", GuiText = "Player Collisions Mode (experimental):", Type = "Combobox", Options = {
			"No change",
			"Always disable collisions",
			"Permissions Based"
		}, Category = "Misc", Default = 3, Incomplete = true },
	{ Name = "pvp_mode", GuiText = "PVP Mode: ", Type = "Combobox", Options = {
			"Allow all PvP",
			"Disable all PvP",
			"Permissions Based"
		}, Category = "Limits", Default = 3 }
}

function MODULE:AddCategory(name, order)
	for i,k in pairs(categories) do
		if(k.Name == name) then return end
	end
	table.insert(categories, { Name = name, Order = order })
end

function MODULE:AddOption(mod, name, guitext, typ, category, defaultval, permission, otherdat)
	otherdat = otherdat or {}
	table.insert(options, table.Merge({ Module = mod, Name = name, GuiText = guitext, Type = typ, Category = category, Default = defaultval, Permission = permission}, otherdat))
end


function MODULE:RegisterChatCommands()
	
	Vermilion:AddChatCommand({
		Name = "motd",
		Description = "Request the MOTD again.",
		Function = function(sender, text, log, glog)
			MODULE:NetStart("VRequestMOTD")
			net.WriteString(MODULE:GetData("motd", "", true))
			net.WriteInt(MODULE:GetData("motd_type", 1, true), 32)
			net.Send(sender)
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "noclip",
		Description = "Toggles noclip for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setnoclip" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil
			
			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setnoclip_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end
			
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("NoclipPerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched noclip on for him/herself.")
				else
					glog(sender:GetName() .. " switched noclip on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched noclip off for him/herself.")
				else
					glog(sender:GetName() .. " switched noclip off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched noclip " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the noclip state for all players!"
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "falldamage",
		Description = "Toggles falldamage for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setfalldamage" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil
			
			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setfalldamage_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end
			
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("FallDamagePerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched falldamage on for him/herself.")
				else
					glog(sender:GetName() .. " switched falldamage on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched falldamage off for him/herself.")
				else
					glog(sender:GetName() .. " switched falldamage off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched falldamage " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the falldamage state for all players!"
		end
	})
	
	
	Vermilion:AddChatCommand({
		Name = "damagemode",
		Description = "Toggles damage for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setdamage" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil
			
			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setdamage_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end
			
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("DisableDamagePerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched damage on for him/herself.")
				else
					glog(sender:GetName() .. " switched damage on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched damage off for him/herself.")
				else
					glog(sender:GetName() .. " switched damage off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched damage " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the damage state for all players!"
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "flashlight",
		Description = "Toggles flashlight for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setflashlight" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil
			
			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setflashlight_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end
			
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("FlashlightPerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched the flashlight on for him/herself.")
				else
					glog(sender:GetName() .. " switched the flashlight on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched the flashlight off for him/herself.")
				else
					glog(sender:GetName() .. " switched the flashlight off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched the flashlight " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the flashlight state for all players!"
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "uammo",
		Description = "Toggles unlimited ammo for the player",
		Syntax = "[player] => [value]",
		CanMute = true,
		Permissions = { "setuammo" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = sender
			local state = nil
			
			if(table.Count(text) > 0) then
				if(Vermilion:HasPermission(sender, "setuammo_others")) then
					target = VToolkit.LookupPlayer(text[1])
				end
				if(table.Count(text) > 1) then
					state = tobool(text[2])
				end
			end
			
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(state == nil) then
				if(MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] == nil) then MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] = false end
				MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] = not MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()]
			else
				MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()] = state
			end
			if(MODULE:GetData("AmmoPerPlayer", {}, true)[target:SteamID()]) then
				if(sender == target) then
					glog(sender:GetName() .. " switched unlimited ammo on for him/herself.")
				else
					glog(sender:GetName() .. " switched unlimited ammo on for " .. target:GetName())
				end
			else
				if(sender == target) then
					glog(sender:GetName() .. " switched unlimited ammo off for him/herself.")
				else
					glog(sender:GetName() .. " switched unlimited ammo off for " .. target:GetName())
				end
			end
		end,
		AllBroadcast = function(sender, text)
			if(table.Count(text) > 1 and tobool(text[2]) != nil) then
				local val = nil
				if(tobool(text[2])) then
					val = "on"
				else
					val = "off"
				end
				return sender:GetName() .. " switched unlimited ammo " .. val .. " for all players!"
			end
			return sender:GetName() .. " toggled the unlimited ammo state for all players!"
		end
	})
	
end

function MODULE:InitServer()

	self:NetHook("VServerGetProperties", function(vplayer)
		local tab = {}
		for i,k in pairs(options) do
			local val = nil
			if(k.Module != nil) then
				if(k.Module == "Vermilion") then
					val = Vermilion:GetData(k.Name, k.Default)
				else
					val = Vermilion:GetModuleData(k.Module, k.Name, k.Default)
				end
			else
				val = MODULE:GetData(k.Name, k.Default, false)
			end
			tab[tostring(k.Module) .. k.Name] = val
		end
		MODULE:NetStart("VServerGetProperties")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)

	self:NetHook("VServerUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_server")) then
			local data = net.ReadTable()
			for i,k in pairs(data) do
				if(k.Module != nil) then
					if(k.Module == "Vermilion") then
						Vermilion:SetData(k.Name, k.Value)
					else
						Vermilion:SetModuleData(k.Module, k.Name, k.Value)
					end
				else
					self:SetData(k.Name, k.Value)
				end
			end
		end
	end)
	
	self:NetHook("VUpdateMOTD", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "change_motd")) then
			MODULE:SetData("motd", net.ReadString())
		end
	end)
	
	self:NetHook("VUpdateMOTDSettings", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "change_motd")) then
			MODULE:SetData("motd_type", net.ReadInt(32))
		end
	end)
	
	self:NetHook("VGetMOTDProperties", function(vplayer)
		MODULE:NetStart("VGetMOTDProperties")
		net.WriteString(MODULE:GetData("motd", "", true))
		net.WriteInt(MODULE:GetData("motd_type", 1, true), 32)
		net.Send(vplayer)
	end)
	
	self:NetHook("VRequestMOTD", function(vplayer)
		MODULE:NetStart("VRequestMOTD")
		net.WriteString(MODULE:GetData("motd", "", true))
		net.WriteInt(MODULE:GetData("motd_type", 1, true), 32)
		net.Send(vplayer)
	end)
	
	self:NetHook("VGetCommandMuting", function(vplayer)
		MODULE:NetStart("VGetCommandMuting")
		local tab = {}
		for i,k in pairs(Vermilion.ChatCommands) do
			if(not k.CanMute) then continue end
			table.insert(tab, { Name = i, Value = Vermilion:GetData("muted_commands", {}, true)[i] != false })
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VSetCommandMuting", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_server")) then
			local typ = net.ReadString()
			local enabled = net.ReadBoolean()
			print("Setting " .. typ .. " to " .. tostring(enabled))
			Vermilion:GetData("muted_commands", {}, true)[typ] = enabled
		end
	end)
	
	self:AddHook("PlayerSay", function(ply)
		local mode = MODULE:GetData("limit_chat", 3)
		if(mode > 1) then
			if(mode == 2) then
				return ""
			end
			if(mode == 3) then
				if(not Vermilion:HasPermission(ply, "chat")) then return "" end
			end
		end
	end)
	
	self:AddHook("PlayerSpray", function(ply)
		local mode = MODULE:GetData("spray_control", 4)
		if(mode > 1) then
			if(mode == 2) then
				return false
			end
			if(mode == 3) then
				return true
			end
			if(mode == 4) then
				return Vermilion:HasPermission(ply, "can_spray")
			end
		end
	end)
	
	self:AddHook("PlayerNoClip", function(ply, enabled)
		if(enabled) then
			local mode = MODULE:GetData("noclip_control", 4)
			if(mode > 1) then
				if(mode == 2) then
					return false
				end
				if(mode == 3) then
					return true
				end
				if(mode == 4) then
					return Vermilion:HasPermission(ply, "noclip") and MODULE:GetData("NoclipPerPlayer", {}, true)[ply:SteamID()] != false
				end
			end
		end
	end)
	
	self:AddHook("PlayerSwitchFlashlight", function(ply, enabled)
		if(enabled) then
			local mode = MODULE:GetData("flashlight_control", 4)
			if(mode > 1) then
				if(mode == 2) then
					return false
				end
				if(mode == 3) then
					return true
				end
				if(mode == 4) then
					return Vermilion:HasPermission(ply, "enable_flashlight") and MODULE:GetData("FlashlightPerPlayer", {}, true)[ply:SteamID()] != false
				end
			end
		end
	end)
	
	self:AddHook("GetFallDamage", function(ply, speed)
		local mode = MODULE:GetData("disable_fall_damage", 4)
		if(mode > 1) then
			if(mode == 2) then
				return 0
			elseif(mode == 3) then
				return 5 -- TODO: make this customisable
			elseif(mode == 4) then
				if(Vermilion:HasPermission(ply, "no_fall_damage") and MODULE:GetData("FallDamagePerPlayer", {}, true)[ply:SteamID()] != false) then return 0 end
				if(Vermilion:HasPermission(ply, "reduced_fall_damage") and MODULE:GetData("FallDamagePerPlayer", {}, true)[ply:SteamID()] != false) then return 5 end
			end
		end
	end)
	
	self:AddHook("EntityTakeDamage", function(victim, dmg)
		local attacker = dmg:GetAttacker()
		if(IsValid(victim) and victim:IsPlayer()) then
			local damageMode = MODULE:GetData("enable_no_damage", 3)
			local pvpMode = MODULE:GetData("pvp_mode", 3)
			if(damageMode > 1 and not (pvpMode > 1 and attacker:IsPlayer() and attacker != victim)) then
				if(damageMode == 2) then
					dmg:ScaleDamage(0)
					return dmg
				elseif(damageMode == 3) then
					if(Vermilion:HasPermission(victim, "no_damage") and MODULE:GetData("DisableDamagePerPlayer", {}, true)[victim:SteamID()] != false) then
						dmg:ScaleDamage(0)
						return dmg
					end
				end
			end
			if(attacker == victim) then return end
			if(not attacker:IsPlayer()) then return end
			if(pvpMode > 1) then
				if(pvpMode == 2) then
					dmg:ScaleDamage(0)
					return dmg
				elseif(pvpMode == 3) then
					if(IsValid(attacker) and attacker:IsPlayer()) then
						if(Vermilion:HasPermission(attacker, "ignore_pvp_state")) then
							return dmg
						end
					end
					dmg:ScaleDamage(0)
					return dmg
				end
			end
		end
	end)
	
	-- refill ammo every .5 seconds to save processing time.
	timer.Create("Vermilion_UnlimitedAmmo", 1/2, 0, function()
		if(MODULE:GetData("unlimited_ammo", 3) == 1) then return end
		for i,ply in pairs(VToolkit.GetValidPlayers()) do
			if((Vermilion:HasPermission(ply, "unlimited_ammo") and MODULE:GetData("AmmoPerPlayer", {}, true)[ply:SteamID()] != false) or MODULE:GetData("unlimited_ammo", 3) == 2) then
				if(IsValid(ply:GetActiveWeapon())) then
					local twep = ply:GetActiveWeapon()
					if(twep:Clip1() < 500) then twep:SetClip1(500) end
					if(twep:Clip2() < 500) then twep:SetClip2(500) end
					if(twep:GetPrimaryAmmoType() == 10 or twep:GetPrimaryAmmoType() == 8) then
						ply:GiveAmmo(1, twep:GetPrimaryAmmoType(), true)
					elseif(twep:GetSecondaryAmmoType() == 9 or twep:GetSecondaryAmmoType() == 2) then
						ply:GiveAmmo(1, twep:GetSecondaryAmmoType(), true)
					end
				end
			end
		end
	end)
	
	self:AddHook("PlayerCanHearPlayersVoice", function(listener, talker)
		local mode = MODULE:GetData("voip_control", 4, true)
		if(mode > 1) then
			if(mode == 2) then
				return false
			elseif(mode == 3) then
				return MODULE:CalcVoIPChannels(listener, talker, true)
			elseif(mode == 4) then
				if(not Vermilion:HasPermission(talker, "use_voip")) then return false end
				if(not Vermilion:HasPermission(listener, "hear_voip")) then return false end
			end
		end
	end)
	
end

function MODULE:InitClient()

	self:AddHook("PlayerNoClip", function(vplayer, enabled)
		if(enabled) then
			return Vermilion:HasPermission("noclip")
		end
	end)

	self:NetHook("VServerGetProperties", function()
		MODULE.UpdatingGUI = true
		for i,k in pairs(net.ReadTable()) do
			for i1,k1 in pairs(options) do
				if(i == tostring(k1.Module) .. k1.Name) then
					if(k1.Type == "Combobox") then k1.Impl:ChooseOptionID(k) end
					if(k1.Type == "Checkbox") then k1.Impl:SetValue(k) end
					if(k1.Type == "Slider") then k1.Impl:SetValue(k) end
				end
			end
		end
		MODULE.UpdatingGUI = false
	end)
	
	self:NetHook("VGetMOTDProperties", function()
		local panel = Vermilion.Menu.Pages["motd"].Panel
		local text = net.ReadString()
		local typ = net.ReadInt(32)
		
		panel.TypeCombo.Updating = true
		panel.TypeCombo:ChooseOptionID(typ)
		panel.TypeCombo.Updating = false
		
		panel.MOTDText:SetValue(text)
		panel.UnsavedChanges = false
	end)
	
	self:NetHook("VGetCommandMuting", function()
		local data = net.ReadTable()
		local panel = Vermilion.Menu.Pages["command_muting"].Panel
		
		if(table.Count(panel.Controls) > 0) then
			for i,k in pairs(data) do
				local control = panel.Controls[k.Name]
				control.AllowUpdate = false
				control:SetValue(k.Value)
				control.AllowUpdate = true
			end
			return
		end
		
		for i,k in pairs(data) do
			local cb = VToolkit:CreateCheckBox(k.Name)
			cb:SetParent(panel)
			cb:Dock(TOP)
			cb:DockMargin(10, 0, 10, 10)
			
			cb:SetParent(panel.Scroll)
			cb:SetValue(k.Value)
			panel.Controls[k.Name] = cb
			cb.AllowUpdate = true
			
			function cb:OnChange()
				if(not self.AllowUpdate) then return end
				MODULE:NetStart("VSetCommandMuting")
				net.WriteString(k.Name)
				net.WriteBoolean(cb:GetChecked())
				net.SendToServer()
			end
		end
	end)
	
	self:AddHook(Vermilion.Event.CLIENT_GOT_RANKS, function()
		for i,k in pairs(options) do
			if(k.Permission != nil) then
				k.Impl:SetEnabled(Vermilion:HasPermission(k.Permission))
			end
		end
	end)
	
	function MODULE:DisplayMOTD(typ, text)
		if(text == nil or text == "") then return end
		if(typ == 1) then
			for i,k in pairs(string.Split(text, "\n")) do
				Vermilion:AddNotification(k)
			end
		elseif(typ == 2) then
			local panel = VToolkit:CreateFrame(
				{
					['size'] = { 800, 600 },
					['pos'] = { (ScrW() / 2) - 400, (ScrH() / 2) - 300 },
					['closeBtn'] = true,
					['draggable'] = true,
					['title'] = "Vermilion - MOTD",
					['bgBlur'] = true
				}
			)
			local dhtml = vgui.Create("DHTML")
			dhtml:SetHTML(text)
			dhtml:Dock(FILL)
			dhtml:SetParent(panel)
			
			panel:MakePopup()
			panel:SetAutoDelete(true)
		elseif(typ == 3) then
			local panel = VToolkit:CreateFrame(
				{
					['size'] = { 800, 600 },
					['pos'] = { (ScrW() / 2) - 400, (ScrH() / 2) - 300 },
					['closeBtn'] = true,
					['draggable'] = true,
					['title'] = "Vermilion - MOTD",
					['bgBlur'] = true
				}
			)
			local dhtml = vgui.Create("DHTML")
			dhtml:OpenURL(text)
			dhtml:Dock(FILL)
			dhtml:SetParent(panel)
			
			panel:MakePopup()
			panel:SetAutoDelete(true)
		end
	end
	
	self:NetHook("VRequestMOTD", function()
		local text = net.ReadString()
		local typ = net.ReadInt(32)
		
		MODULE:DisplayMOTD(typ, text)
	end)
	
	self:AddHook(Vermilion.Event.MOD_LOADED, function()		
		timer.Simple(2, function()
			MODULE:NetCommand("VRequestMOTD")
		end)
	end)

		
	Vermilion.Menu:AddCategory("server", 2)
	
	Vermilion.Menu:AddPage({
		ID = "server_settings",
		Name = "Basic Settings",
		Order = 0,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel)
			MODULE.UpdatingGUI = true
			MODULE.SettingsList = VToolkit:CreateCategoryList()
			MODULE.SettingsList:SetParent(panel)
			MODULE.SettingsList:SetPos(0, 0)
			MODULE.SettingsList:SetSize(600, 560)
			local sl = MODULE.SettingsList
			
			for i,k in SortedPairsByMemberValue(categories, "Order") do
				k.Impl = sl:Add(k.Name)
			end
			
			for i,k in pairs(options) do
				if(k.Type == "Combobox") then
					local panel = vgui.Create("DPanel")
				
					local label = VToolkit:CreateLabel(k.GuiText)
					label:SetDark(true)
					label:SetPos(10, 3 + 3)
					label:SetParent(panel)
					
					local combobox = VToolkit:CreateComboBox()
					combobox:SetPos(MODULE.SettingsList:GetWide() - 230, 3)
					combobox:Dock(RIGHT)
					combobox:DockMargin(0, 2, 5, 2)
					combobox:SetParent(panel)
					for i1,k1 in pairs(k.Options) do
						combobox:AddChoice(k1)
					end
					combobox:SetWide(200)
					
					if(k.Incomplete) then
						local dimage = vgui.Create("DImage")
						dimage:SetImage("icon16/error.png")
						dimage:SetSize(16, 16)
						dimage:SetPos(select(1, combobox:GetPos()) - 25, 5)
						dimage:SetParent(panel)
						dimage:SetTooltip("Feature not implemented!")
					end
					
					function combobox:OnSelect(index)
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						net.WriteTable({{ Module = k.Module, Name = k.Name, Value = index}})
						net.SendToServer()
					end
					
					panel:SetSize(select(1, combobox:GetPos()) + combobox:GetWide() + 10, combobox:GetTall() + 5)
					panel:SetPaintBackground(false)
					
					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.Name == k.Category) then cat = cat1.Impl break end
					end
					
					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )
					
					panel:Dock(TOP)
					panel:SetParent(cat)
					
					combobox:ChooseOptionID(k.Default)
					
					if(k.Permission != nil) then
						combobox:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = combobox
				elseif(k.Type == "Checkbox") then
					local panel = vgui.Create("DPanel")
					
					local cb = VToolkit:CreateCheckBox(k.GuiText)
					cb:SetDark(true)
					cb:SetPos(10, 3)
					cb:SetParent(panel)
					
					cb:SetValue(k.Default)
					
					function cb:OnChange()
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						net.WriteTable({{Module = k.Module, Name = k.Name, Value = cb:GetChecked()}})
						net.SendToServer()
					end
					
					
					
					panel:SetSize(cb:GetWide() + 10, cb:GetTall() + 5)
					if(k.Incomplete) then
						local dimage = vgui.Create("DImage")
						dimage:SetImage("icon16/error.png")
						dimage:SetSize(16, 16)
						dimage:SetPos(select(1, cb:GetPos()) + cb:GetWide() + 25, 5)
						dimage:SetParent(panel)
						dimage:SetTooltip("Feature not implemented!")
						panel:SetWide(panel:GetWide() + 25)
					end
					panel:SetPaintBackground(false)
					
					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.Name == k.Category) then cat = cat1.Impl break end
					end
					
					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )
					
					panel:Dock(TOP)
					panel:SetParent(cat)
					
					if(k.Permission != nil) then
						cb:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = cb
				elseif(k.Type == "Slider") then
					local panel = vgui.Create("DPanel")
					
					local slider = VToolkit:CreateSlider(k.GuiText, k.Bounds.Min, k.Bounds.Max, k.Decimals or 2)
					slider:SetPos(10, 3)
					slider:SetParent(panel)
					slider:SetWide(300)
					
					slider:SetValue(k.Default)
					
					function slider:OnValueChanged(value)
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						net.WriteTable({{ Module = k.Module, Name = k.Name, Value = math.Round(value, k.Decimals or 2) }})
						net.SendToServer()
					end
					
					panel:SetSize(slider:GetWide() + 10, slider:GetTall() + 5)
					panel:SetPaintBackground(false)
					
					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.Name == k.Category) then cat = cat1.Impl break end
					end
					
					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )
					
					panel:Dock(TOP)
					panel:SetParent(cat)
					
					if(k.Permission != nil) then
						slider:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = slider
				elseif(k.Type == "Colour") then
					-- Implement Me!
				elseif(k.Type == "NumberWang") then
					-- Implement Me!
				elseif(k.Type == "Text") then
					-- Implement Me!
				end
			end
			MODULE.UpdatingGUI = false
		end,
		Updater = function(panel)
			MODULE:NetCommand("VServerGetProperties")
		end
	})
	
	Vermilion.Menu:AddPage({
		ID = "motd",
		Name = "MOTD",
		Order = 1,
		Category = "server",
		Size = { 500, 500 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("change_motd")
		end,
		Builder = function(panel)
			local motdtext = VToolkit:CreateTextbox("", panel)
			motdtext:SetMultiline(true)
			motdtext:SetPos(10, 10)
			motdtext:SetSize(480, 400)
			motdtext:SetParent(panel)
			motdtext:SetUpdateOnType(true)
			panel.MOTDText = motdtext
			
			panel.UnsavedChanges = false
			
			function motdtext:OnChange()
				panel.UnsavedChanges = true
			end
			
			local typCombo = VToolkit:CreateComboBox({
				"Standard",
				"HTML",
				"URL"
			}, 1)
			typCombo:SetParent(panel)
			typCombo:SetPos(10, 415)
			typCombo:SetSize(200, 20)
			typCombo.OnSelect = function(panel, index, value)
				typCombo.VSelectedIndex = index
				if(typCombo.VUpdating) then
					return
				end
				MODULE:NetStart("VUpdateMOTDSettings")
				net.WriteInt(index, 32)
				net.SendToServer()
			end
			panel.TypeCombo = typCombo
			
			local motdVars = VToolkit:CreateButton("Show Variables", function()
				
			end)
			motdVars:SetPos(370, 415)
			motdVars:SetSize(120, 20)
			motdVars:SetParent(panel)
			
			local preview = VToolkit:CreateButton("Preview", function()
				MODULE:DisplayMOTD(typCombo.VSelectedIndex, motdtext:GetValue())
			end)
			preview:SetPos(370, 445)
			preview:SetSize(120, 20)
			preview:SetParent(panel)
			
			local save = VToolkit:CreateButton("Save Changes...", function()
				MODULE:NetStart("VUpdateMOTD")
				net.WriteString(motdtext:GetValue())
				net.SendToServer()
				panel.UnsavedChanges = false
			end)
			save:SetPos(370, 475)
			save:SetSize(120, 20)
			save:SetParent(panel)
			
			MODULE:AddHook(Vermilion.Event.MENU_CLOSING, function()
				if(panel.UnsavedChanges) then
					VToolkit:CreateConfirmDialog("There are unsaved changes to the MOTD! Really close?", function()
						Vermilion.Menu:Close(true)
						panel.UnsavedChanges = false
					end, { Confirm = "Yes", Deny = "No", Default = false })
					return false
				end
			end)
			
		end,
		Updater = function(panel)
			MODULE:NetCommand("VGetMOTDProperties")
		end
	})
	
	Vermilion.Menu:AddPage({
		ID = "userdata",
		Name = "Userdata Browser",
		Order = 2,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel)
			local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
			label:SetFont("DermaLarge")
			label:SizeToContents()
			label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
			label:SetParent(panel)
		end
	})
	
	Vermilion.Menu:AddPage({
		ID = "voip_channels",
		Name = "VoIP Channels",
		Order = 3,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel)
			local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
			label:SetFont("DermaLarge")
			label:SizeToContents()
			label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
			label:SetParent(panel)
		end
	})
	
	Vermilion.Menu:AddPage({
		ID = "command_muting",
		Name = "Command Muting",
		Order = 4,
		Category = "server",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("manage_server")
		end,
		Builder = function(panel)
			local label = VToolkit:CreateLabel("Control which commands can produce global output, i.e. \"Ned cleared the decals.\". If a command isn't on this list, it doesn't produce global output.")
			label:SetParent(panel)
			label:SetWrap(true)
			label:SetTall(label:GetTall() * 2)
			label:Dock(TOP)
			label:DockMargin(10, 10, 10, 20)
			
			panel.Controls = {}
			
			local scroll = vgui.Create("DScrollPanel")
			scroll:Dock(FILL)
			scroll:SetParent(panel)
			panel.Scroll = scroll
		end,
		Updater = function(panel)
			MODULE:NetCommand("VGetCommandMuting")
		end
	})
end

Vermilion:RegisterModule(MODULE)