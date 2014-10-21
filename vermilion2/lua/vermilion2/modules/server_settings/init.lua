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
	"set_motd",
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
	"add_voip_channel",
	"join_voip_channel",
	"delete_voip_channel"
}
MODULE.NetworkStrings = {
	"VServerGetProperties", -- used to build the settings page
	"VServerUpdate",
}

MODULE.DefaultVoIPChannels = {
	{ Name = "Default", Password = nil }
}

function MODULE:AddVoIPChannel(name, password)
	for i,k in pairs(self:GetData("voip_channels", self.DefaultVoIPChannels, true)) do
		if(k.Name == name) then return false end
	end
	local tPassword = nil
	if(password != nil) then
		tPassword = util.CRC(password)
	end
	table.insert(self:GetData("voip_channels", self.DefaultVoIPChannels, true), { Name = name, Password = tPassword })
	return true
end

function MODULE:JoinChannel(vplayer, chan, pass)
	local chanObj = nil
	for i,k in pairs(self:GetData("voip_channels", self.DefaultVoIPChannels, true)) do
		if(k.Name == chan) then
			chanObj = k
			break
		end
	end
	if(chanObj != nil) then
		if(chanObj.Password != nil) then
			if(pass == nil) then return "BAD_PASSWORD" end
			if(chanObj.Password != util.CRC(pass)) then
				return "BAD_PASSWORD"
			end
		end
		Vermilion:GetUser(vplayer).VoIPChannel = chan
		return "GOOD"
	end
	return "NO_SUCH_CHAN"
end

function MODULE:RegisterChatCommands()

	Vermilion:AddChatCommand("addchan", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "add_voip_channel")) then
			if(not MODULE:AddVoIPChannel(text[1], text[2])) then
				log("VoIP Channel already exists!", NOTIFY_ERROR)
			else
				log("Created VoIP Channel!")
			end
		end
	end, "<name> [password]")
	
	Vermilion:AddChatCommand("delchan", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "delete_voip_channel")) then
			local has = false
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == text[1]) then has = k break end
			end
			if(text[1] == "Default") then has = false end
			if(not has) then
				log("No such VoIP Channel!", NOTIFY_ERROR)
				return
			end
			table.RemoveByValue(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true), has)
			for i,k in pairs(Vermilion.Data.Users) do
				if(k.VoIPChannel == text[1]) then
					k.VoIPChannel = "Default"
				end
			end
			log("Removed VoIP Channel!")
		end
	end, "<chan>", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(string.find(string.lower(k.Name), string.lower(current))) then
					table.insert(tab, k.Name)
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("changechanpass", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "add_voip_channel")) then
			local has = false
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == text[1]) then has = k break end
			end
			if(has.Name == "Default") then
				
			end
		end
	end, "<chan> [oldpass] <newpass>")
	
	Vermilion:AddChatCommand("joinchan", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "join_voip_channel")) then
			local result = MODULE:JoinChannel(sender, text[1], text[2])
			if(result == "BAD_PASSWORD") then
				log("Bad VoIP Channel password!", NOTIFY_ERROR)
			elseif(result == "NO_SUCH_CHAN") then
				log("No such VoIP Channel!", NOTIFY_ERROR)
			else
				log("Joined VoIP Channel!")
			end
		end
	end, "<channel> [password]", function(pos, current, all)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(string.find(string.lower(k.Name), string.lower(current))) then
					table.insert(tab, k.Name)
				end
			end
			return tab
		end
		if(pos == 2) then
			local chan = nil
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == all[1]) then
					chan = k
					break
				end
			end
			if(chan != nil) then
				if(chan.Password == nil) then
					return {{ Name = "", Syntax = "No password required!" }}
				else
					return {{ Name = "", Syntax = "Password Required!" }}
				end
			end
		end
	end)
	
end

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
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Module = "limit_spawn", Name = "enable_limit_remover", GuiText = "Spawn Limit Remover:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "enable_no_damage", GuiText = "Disable Damage:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "flashlight_control", GuiText = "Flashlight Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "noclip_control", GuiText = "Noclip Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "spray_control", GuiText = "Spray Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "voip_control", GuiText = "VoIP Control:", Type = "Combobox", Options = {
			"Do not limit",
			"Globally Disable VoIP",
			"Globally Enable VoIP",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "limit_chat", GuiText = "Chat Blocker:", Type = "Combobox", Options = {
			"Off",
			"Globally Disable Chat",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "enable_lock_immunity", GuiText = "Lua Lock Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", CategoryWeight = 2, Default = 3, Incomplete = true },
	{ Name = "enable_kill_immunity", GuiText = "Lua Kill Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", CategoryWeight = 2, Default = 3, Incomplete = true },
	{ Name = "enable_kick_immunity", GuiText = "Lua Kick Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", CategoryWeight = 2, Default = 3, Incomplete = true },
	{ Name = "disable_fall_damage", GuiText = "Fall Damage Modifier:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"All Players suffer reduced damage",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "disable_owner_nag", GuiText = "Disable 'No owner detected' nag at startup", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = false, Incomplete = true },
	--{ Module = "deathnotice", Name = "enabled", GuiText = "Enable Kill Notices", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = true },
	{ Name = "player_collision_mode", GuiText = "Player Collisions Mode (experimental):", Type = "Combobox", Options = {
			"No change",
			"Always disable collisions",
			"Permissions Based"
		}, Category = "Misc", CategoryWeight = 50, Default = 3, Incomplete = true },
	{ Name = "pvp_mode", GuiText = "PVP Mode: ", Type = "Combobox", Options = {
			"Allow all PvP",
			"Disable all PvP",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 }
	--{ Module = "scoreboard", Name = "scoreboard_enabled", GuiText = "Enable Vermilion Scoreboard", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = true },
	--{ Module = "gm_customiser", Name = "enabled", GuiText = "Automatically adapt settings to suit supported gamemodes", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = true },
	--{ Name = "respect_rank_order", GuiText = "Enable Rank Hierarchy-Based Immunity", Type = "Checkbox", Category = "Immunity", CategoryWeight = 2, Default = true }
}

function MODULE:AddCategory(name, order)
	for i,k in pairs(categories) do
		if(k.Name == name) then return end
	end
	table.insert(categories, { Name = name, Order = order })
end

function MODULE:AddOption(mod, name, guitext, typ, category, categoryweight, defaultval, permission, otherdat)
	otherdat = otherdat or {}
	table.insert(options, table.Merge({ Module = mod, Name = name, GuiText = guitext, Type = typ, Category = category, CategoryWeight = categoryweight, Default = defaultval, Permission = permission}, otherdat))
end

function MODULE:InitServer()

	self:NetHook("VServerGetProperties", function(vplayer)
		local tab = {}
		for i,k in pairs(options) do
			local val = nil
			if(k.Module != nil) then
				val = Vermilion:GetModuleData(k.Module, k.Name, k.Default)
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
					Vermilion:SetModuleData(k.Module, k.Name, k.Value)
				else
					self:SetData(k.Name, k.Value)
				end
			end
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
					return Vermilion:HasPermission(ply, "noclip")
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
					return Vermilion:HasPermission(ply, "enable_flashlight")
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
				if(Vermilion:HasPermission(ply, "no_fall_damage")) then return 0 end
				if(Vermilion:HasPermission(ply, "reduced_fall_damage")) then return 5 end
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
					if(Vermilion:HasPermission(victim, "no_damage")) then
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
			if(Vermilion:HasPermission(ply, "unlimited_ammo") or MODULE:GetData("unlimited_ammo", 3) == 2) then
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
				return MODULE:CalcVoIPChannels(listener, talker, true)
			end
		end
	end)
	
	function MODULE:CalcVoIPChannels(listener, talker, default)
		if(IsValid(listener) and IsValid(talker)) then
			local vListener = Vermilion:GetUser(listener)
			local vTalker = Vermilion:GetUser(talker)
			if(vListener.VoIPChannel == nil) then
				vListener.VoIPChannel = "Default"
			end
			if(vTalker.VoIPChannel == nil) then
				vTalker.VoIPChannel = "Default"
			end
			return vListener.VoIPChannel == vTalker.VoIPChannel
		end
		return default
	end


end

function MODULE:InitClient()

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
	
	self:AddHook(Vermilion.Event.CLIENT_GOT_RANKS, function()
		for i,k in pairs(options) do
			if(k.Permission != nil) then
				k.Impl:SetEnabled(Vermilion:HasPermission(k.Permission))
			end
		end
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
					
					local slider = VToolkit:CreateSlider(k.GuiText, k.Bounds.Min, k.Bounds.Max, 2)
					slider:SetPos(10, 3)
					slider:SetParent(panel)
					slider:SetWide(300)
					
					slider:SetValue(k.Default)
					
					function slider:OnChange(index)
						if(MODULE.UpdatingGUI) then return end
						MODULE:NetStart("VServerUpdate")
						net.WriteTable({{ Module = k.Module, Name = k.Name, Value = index}})
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
			MODULE:NetStart("VServerGetProperties")
			net.SendToServer()
		end
	})
	
	Vermilion.Menu:AddPage({
		ID = "motd",
		Name = "MOTD",
		Order = 1,
		Category = "server",
		Size = { 500, 500 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("set_motd")
		end,
		Builder = function(panel)
			local motdtext = VToolkit:CreateTextbox("", panel)
			motdtext:SetMultiline(true)
			motdtext:SetPos(10, 10)
			motdtext:SetSize(480, 400)
			motdtext:SetParent(panel)
			
			local isURL = VToolkit:CreateCheckBox("MOTD Is URL")
			isURL:SetPos(10, 420)
			isURL:SetParent(panel)
			isURL:SizeToContents()
			
			local isHTML = VToolkit:CreateCheckBox("MOTD is HTML")
			isHTML:SetPos(10, 440)
			isHTML:SetParent(panel)
			isHTML:SizeToContents()
			
			local motdVars = VToolkit:CreateButton("Show Variables", function()
				
			end)
			motdVars:SetPos(370, 425)
			motdVars:SetSize(120, 20)
			motdVars:SetParent(panel)
			
			local preview = VToolkit:CreateButton("Preview", function()
			
			end)
			preview:SetPos(370, 455)
			preview:SetSize(120, 20)
			preview:SetParent(panel)
			
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
end

Vermilion:RegisterModule(MODULE)