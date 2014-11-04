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
MODULE.Name = "VoIP Channels"
MODULE.ID = "voip_channels"
MODULE.Description = "Manages VoIP Channels"
MODULE.Author = "Ned"
MODULE.Permissions = {
	"add_voip_channel",
	"join_voip_channel",
	"delete_voip_channel",
	"enter_any_voip_channel",
	"change_channel_password"
}

MODULE.DefaultVoIPChannels = {
	{ Name = "Default", Password = nil, Founder = nil }
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "addchan",
		Description = "Adds a VoIP channel.",
		Syntax = "<name> [password]",
		CanMute = true,
		Permissions = { "add_voip_channel" },
		Function = function(sender, text, log, glog)
			if(not MODULE:AddVoIPChannel(text[1], text[2], sender)) then
				log("VoIP Channel already exists!", NOTIFY_ERROR)
			else
				glog("VoIP channel '" .. text[1] .. "' was created successfully by " .. sender:GetName())
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "delchan",
		Description = "Deletes a VoIP channel.",
		Syntax = "<chan>",
		CanMute = true,
		Permissions = { "delete_voip_channel" },
		Predictor = function(pos, current, all)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
					if(string.find(string.lower(k.Name), string.lower(current))) then
						table.insert(tab, k.Name)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log)
			local has = false
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == text[1]) then has = k break end
			end
			if(text[1] == "Default") then has = false end
			if(not has) then
				log("No such VoIP Channel!", NOTIFY_ERROR)
				return
			end
			if(has.Founder != sender:SteamID()) then
				log("You are not the founder of this channel thus you cannot delete it.", NOTIFY_ERROR)
				return
			end
			table.RemoveByValue(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true), has)
			for i,k in pairs(Vermilion.Data.Users) do
				if(k.VoIPChannel == text[1]) then
					k.VoIPChannel = "Default"
				end
			end
			glog("VoIP channel '" .. text[1] .. " was deleted by " .. sender:GetName())
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "changechanpass",
		Description = "Changes a channel password.",
		Syntax = "<chan> [oldpass] <newpass>",
		Permissions = { "change_channel_password" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
					if(string.find(string.lower(k.Name), string.lower(current))) then
						table.insert(tab, k.Name)
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
			local has = false
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == text[1]) then has = k break end
			end
			if(has.Name == "Default") then
				has = false
			end
			if(not has) then
				log("No such VoIP channel.", NOTIFY_ERROR)
				return
			end
			if(has.Founder != sender:SteamID()) then
				log("You are not the founder of this channel thus you cannot modify it.", NOTIFY_ERROR)
				return
			end
			if(has.Password != nil) then
				if(table.Count(text) < 3) then
					log("Original channel password required!", NOTIFY_ERROR)
					return
				end
				if(has.Password != util.CRC(text[2])) then
					log("Invalid password!", NOTIFY_ERROR)
					return
				end
			end
			has.Password = util.CRC(text[3])
			log("Updated password!")
		end
	})
	
end

function MODULE:InitServer()
	
	function MODULE:AddVoIPChannel(name, password, founder)
		if(name == nil or name == "") then return false end
		for i,k in pairs(self:GetData("voip_channels", self.DefaultVoIPChannels, true)) do
			if(k.Name == name) then return false end
		end
		local tPassword = nil
		if(password != nil) then
			tPassword = util.CRC(password)
		end
		table.insert(self:GetData("voip_channels", self.DefaultVoIPChannels, true), { Name = name, Password = tPassword, Founder = founder:SteamID() })
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
	
	function MODULE:CalcVoIPChannels(listener, talker, default)
		if(IsValid(listener) and IsValid(talker)) then
			local vListener = Vermilion:GetUser(listener)
			local vTalker = Vermilion:GetUser(talker)
			if(vListener == nil or vTalker == nil) then return end
			if(vListener.VoIPChannel == nil) then
				vListener.VoIPChannel = "Default"
			end
			if(vTalker.VoIPChannel == nil) then
				vTalker.VoIPChannel = "Default"
			end
			if(vListener.VoIPChannel != vTalker.VoIPChannel) then return false end
		end
		return default
	end
	
	self:AddHook("PlayerCanHearPlayersVoice", function(listener, talker)
		return MODULE:CalcVoIPChannels(listener, talker, nil)
	end)
	
	
end

function MODULE:InitClient()
	
end

Vermilion:RegisterModule(MODULE)