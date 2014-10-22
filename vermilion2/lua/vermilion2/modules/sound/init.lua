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
MODULE.Name = "Sounds"
MODULE.ID = "sound"
MODULE.Description = "Plays sounds from files, the internet and the SoundCloud API."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"playsound",
	"playstream",
	"playsoundcloud",
	"stopsound",
	"pausesound",
	"unpausesound"
}
MODULE.NetworkStrings = {
	"VQueueSound",
	"VQueueStream",
	"VQueueSoundCloud",
	"VPlaySound",
	"VPlayStream",
	"VPlaySoundCloud",
	"VStop",
	"VPause",
	"VUnpause"
}

MODULE.TYPE_FILE = -1
MODULE.TYPE_STREAM = -2
MODULE.TYPE_SOUNDCLOUD = -3

MODULE.Channels = {}
MODULE.Visualisers = {}

function MODULE:RegisterVisualiser(name, drawFunc)
	self.Visualisers[name] = drawFunc
end

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand("playsound", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "playsound")) then
			local path = nil
			local target = VToolkit.GetValidPlayers(false)
			local loop = false
			local volume = 100
			
			if(table.Count(text) < 1) then
				log("Missing path!", NOTIFY_ERROR)
				return
			end
			
			path = text[1]
			
			if(table.Count(text) >= 2) then
				if(text[2] != "nil") then
					target = VToolkit.LookupPlayer(text[2])
					if(not IsValid(target)) then
						log("No such player!", NOTIFY_ERROR)
						return
					end
				end
			end
			
			if(table.Count(text) >= 3) then
				if(tobool(text[3]) != nil) then
					loop = tobool(text[3])
				else
					log("Invalid loop parameter!", NOTIFY_ERROR)
					return
				end
			end
			
			if(table.Count(text) >= 4) then
				if(tonumber(text[4]) != nil) then
					volume = tonumber(text[4])
					if(volume < 0 or volume > 100) then
						log("Invalid volume parameter!", NOTIFY_ERROR)
						return
					end
				else
					log("Invalid volume parameter!", NOTIFY_ERROR)
					return
				end
			end
			
			MODULE:SendSound(target, path, "BaseSound", { Volume = volume, Loop = loop })
			Vermilion:BroadcastNotification(sender:GetName() .. " is playing a sound.")
		end
	end, "<path> [target:nil/name] [loop:true/false] [volume:0-100]")
	
	Vermilion:AddChatCommand("playstream", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "playsound")) then
			local url = nil
			local target = VToolkit.GetValidPlayers(false)
			local loop = false
			local volume = 100
			
			if(table.Count(text) < 1) then
				log("Missing URL!", NOTIFY_ERROR)
				return
			end
			
			url = text[1]
			
			if(table.Count(text) >= 2) then
				if(text[2] != "nil") then
					target = VToolkit.LookupPlayer(text[2])
					if(not IsValid(target)) then
						log("No such player!", NOTIFY_ERROR)
						return
					end
				end
			end
			
			if(table.Count(text) >= 3) then
				if(tobool(text[3]) != nil) then
					loop = tobool(text[3])
				else
					log("Invalid loop parameter!", NOTIFY_ERROR)
					return
				end
			end
			
			if(table.Count(text) >= 4) then
				if(tonumber(text[4]) != nil) then
					volume = tonumber(text[4])
					if(volume < 0 or volume > 100) then
						log("Invalid volume parameter!", NOTIFY_ERROR)
						return
					end
				else
					log("Invalid volume parameter!", NOTIFY_ERROR)
					return
				end
			end
			
			MODULE:SendStream(target, url, "BaseSound", { Volume = volume, Loop = loop })
			Vermilion:BroadcastNotification(sender:GetName() .. " is playing a stream.")
		end
	end, "<url> [target:nil/name] [loop:true/false] [volume:0-100]")
	
	Vermilion:AddChatCommand("playsoundcloud", function(sender, text, log)
		
	end)
	
	Vermilion:AddChatCommand("stopsound", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "stopsound")) then
			local target = VToolkit.GetValidPlayers(false)
			local channel = "BaseSound"
			
			if(table.Count(text) >= 1) then
				if(text[1] != "nil") then
					target = VToolkit.LookupPlayer(text[1])
					if(not IsValid(target)) then
						log("No such player!", NOTIFY_ERROR)
						return
					end
				end
			end
			
			if(table.Count(text) >= 2) then
				channel = text[2]
			end
			
			MODULE:NetStart("VStop")
			net.WriteString(channel)
			net.Send(target)
			
			Vermilion:BroadcastNotification(sender:GetName() .. " stopped the sound in the " .. channel .. " channel.")
		end
	end, "[target:nil/name] [channel]")
	
	Vermilion:AddChatCommand("pausesound", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "pausesound")) then
			local target = VToolkit.GetValidPlayers(false)
			local channel = "BaseSound"
			
			if(table.Count(text) >= 1) then
				if(text[1] != "nil") then
					target = VToolkit.LookupPlayer(text[1])
					if(not IsValid(target)) then
						log("No such player!", NOTIFY_ERROR)
						return
					end
				end
			end
			
			if(table.Count(text) >= 2) then
				channel = text[2]
			end
			
			MODULE:NetStart("VPause")
			net.WriteString(channel)
			net.Send(target)
			
			Vermilion:BroadcastNotification(sender:GetName() .. " paused the sound in the " .. channel .. " channel.")
		end
	end, "[target:nil/name] [channel]")
	
	Vermilion:AddChatCommand("unpausesound", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "unpausesound")) then
			local target = VToolkit.GetValidPlayers(false)
			local channel = "BaseSound"
			
			if(table.Count(text) >= 1) then
				if(text[1] != "nil") then
					target = VToolkit.LookupPlayer(text[1])
					if(not IsValid(target)) then
						log("No such player!", NOTIFY_ERROR)
						return
					end
				end
			end
			
			if(table.Count(text) >= 2) then
				channel = text[2]
			end
			
			MODULE:NetStart("VUnpause")
			net.WriteString(channel)
			net.Send(target)
			
			Vermilion:BroadcastNotification(sender:GetName() .. " resumed the sound in the " .. channel .. " channel.")
		end
	end, "[target:nil/name] [channel]")
end

function MODULE:InitShared()
	if(SERVER) then
		AddCSLuaFile("vermilion2/modules/sound/soundcloud_bindings.lua")
	end
	include("vermilion2/modules/sound/soundcloud_bindings.lua")
end

function MODULE:InitServer()
	
	function MODULE:SendSound(vplayer, path, channel, parameters)
		MODULE:NetStart("VPlaySound")
		net.WriteString(path)
		net.WriteString(channel)
		net.WriteTable(parameters or {})
		net.Send(vplayer)
	end
	
	function MODULE:BroadcastSound(path, channel, parameters)
		self:SendSound(VToolkit.GetValidPlayers(false), path, channel, parameters)
	end
	
	function MODULE:SendStream(vplayer, url, channel, parameters)
		MODULE:NetStart("VPlayStream")
		net.WriteString(url)
		net.WriteString(channel)
		net.WriteTable(parameters or {})
		net.Send(vplayer)
	end
	
	function MODULE:BroadcastStream(url, channel, parameters)
		self:SendStream(VToolkit.GetValidPlayers(false), url, channel, parameters)
	end
	
end

function MODULE:InitClient()

	CreateClientConVar("vermilion_fft", 1, true, false)
	CreateClientConVar("vermilion_fft_type", "Default", true, false)
	
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		local mod = Vermilion:GetModule("client_settings")
		if(mod == nil) then return end
		mod:AddOption("vermilion_fft", "Enable Visualiser", "Checkbox", "Features")
		mod:AddOption("vermilion_fft_type", "Visualiser Style", "Combobox", "Graphics", {
			Options = table.GetKeys(MODULE.Visualisers),
			SetAs = "text"
		})
	end)
	
	self:NetHook("VPlaySound", function()
		local path = net.ReadString()
		local channel = net.ReadString()
		local parameters = net.ReadTable()
		MODULE:QueueSoundFile(path, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end)
	
	self:NetHook("VPlayStream", function()
		local url = net.ReadString()
		local channel = net.ReadString()
		local parameters = net.ReadTable()
		MODULE:QueueSoundStream(url, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end)
	
	local function setChannel(name, data)
		if(MODULE.Channels[name] != nil) then
			if(IsValid(MODULE.Channels[name].AudioChannel)) then
				MODULE.Channels[name].AudioChannel:Stop()
			end
		end
		MODULE.Channels[name] = data
	end
	
	function MODULE:GetChannel(name)
		return self.Channels[name]
	end
	
	local requiredFileParamters = {
		{ Name = "Volume", Default = 1 },
		{ Name = "Loop", Default = false }
	}
	
	local requiredStreamParameters = {
		{ Name = "Volume", Default = 1 },
		{ Name = "Loop", Default = false }
	}
	
	function MODULE:QueueSoundFile(path, channel, parameters, callback)
		parameters = parameters or {}
		
		for i,k in pairs(requiredFileParamters) do
			if(parameters[k.Name] == nil) then
				parameters[k.Name] = k.Default
			end
		end
		
		local data = { Type = MODULE.TYPE_FILE, Path = path, Ready = false, AudioChannel = nil }
		table.Merge(data, parameters)
		setChannel(channel, data)
		
		local typ = ""
		if(data.Loop) then
			typ = "noblock"
		end
		
		sound.PlayFile("sound/" .. data.Path, "noplay " .. typ, function(channel, errid, errnam)
			if(IsValid(channel)) then
				channel:EnableLooping(data.Loop)
				channel:SetVolume(data.Volume)
				data.AudioChannel = channel
				data.Ready = true
				if(isfunction(callback)) then callback(data) end
			else
				Vermilion.Log(errnam)
			end
		end)
	end
	
	function MODULE:QueueSoundStream(url, channel, parameters, callback)
		parameters = parameters or {}
		
		for i,k in pairs(requiredFileParamters) do
			if(parameters[k.Name] == nil) then
				parameters[k.Name] = k.Default
			end
		end
		
		local data = { Type = MODULE.TYPE_STREAM, URL = url, Ready = false, AudioChannel = nil }
		table.Merge(data, parameters)
		setChannel(channel, data)
		
		local typ = ""
		if(data.Loop) then
			typ = "noblock"
		end
		
		sound.PlayURL(data.URL, "noplay " .. typ, function(channel, errid, errnam)
			if(IsValid(channel)) then
				channel:EnableLooping(data.Loop)
				channel:SetVolume(data.Volume)
				data.AudioChannel = channel
				data.Ready = true
				if(isfunction(callback)) then callback(data) end
			else
				Vermilion.Log(errnam)
			end
		end)
	end
	
	function MODULE:PlaySoundFile(path, channel, parameters)
		self:QueueSoundFile(path, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end
	
	function MODULE:PlaySoundStream(url, channel, parameters)
		self:QueueSoundStream(url, channel, parameters, function(data)
			MODULE:PlayChannel(channel)
		end)
	end
	
	function MODULE:ValidateChannel(channel)
		if(self:GetChannel(channel) == nil) then return false end
		if(not self:GetChannel(channel).Ready) then return false end
		if(not IsValid(self:GetChannel(channel).AudioChannel)) then return false end
		
		return true
	end
	
	function MODULE:PlayChannel(channel)
		if(not self:ValidateChannel(channel)) then return false end
		self:GetChannel(channel).AudioChannel:Play()
		return true
	end
	
	function MODULE:PauseChannel(channel)
		if(not self:ValidateChannel(channel)) then return false end
		self:GetChannel(channel).AudioChannel:Pause()
		return true
	end
	
	function MODULE:StopChannel(channel)
		if(not self:ValidateChannel(channel)) then return false end
		self:GetChannel(channel).AudioChannel:Stop()
		return true
	end
	
	
	self:RegisterVisualiser("Default", function(data, percent, xpos, ypos, width, spacing)
		for i,k in pairs(data) do
			if(i > 80) then break end -- limit to 80 channels
			local colour = Color(255, 0, 0, 255)
			if(percent >= i) then colour = Color(0, 0, 255, 255) end -- draw the progress through the track
			draw.RoundedBox(2, xpos, ypos - ((k / 2) * (500 + (i * 8)) ), width, k * (500 + (i * 8)), colour)
			xpos = xpos + width + spacing
		end
	end)
	
	self:RegisterVisualiser("Scope", function(data, percent, xpos, ypos, width, spacing)
		for i,k in pairs(data) do
			if(i > 80) then break end -- limit to 80 channels.
			local colour = Color(255, 0, 0, 255)
			if(percent >= i) then colour = Color(0, 0, 255, 255) end
			surface.SetDrawColor(colour)
			if(table.Count(data) < i + 1) then
				for yh = 3,-3,-1 do
					surface.DrawLine(xpos, (ypos + yh) - ((k /2) * (500 + (i * 8))), xpos + width + spacing, ypos + 1)
				end
			else
				for yh = 3,-3,-1 do
					local ryh = 1
					if(i % 2 == 0) then
						ryh = -1
					end
					local ryh2 = 1
					if((i + 1) % 2 == 0) then
						ryh2 = -1
					end
					surface.DrawLine(xpos, (ypos + yh) - (((k / 2) * (500 + (i * 8))) * ryh), xpos + width + spacing, (ypos + yh) - (((data[i + 1] / 2) * (500 + ((i+1) * 8))) * ryh2))
				end
			end
			xpos = xpos + width + spacing
		end
	end)

	self:AddHook("HUDShouldDraw", function(name)
		if(name == "NetGraph") then
			if(GetConVarNumber("vermilion_fft") != 1) then return end
			if(not MODULE:ValidateChannel("BaseSound")) then return end
			if(MODULE:GetChannel("BaseSound").AudioChannel:GetState() == 0) then return end
			return false
		end
	end)
	
	self:AddHook("HUDPaint", "FFTDraw", function()
		if(MODULE.Credits != nil) then
			local pos = 0
			local maxw = 0
			for i,k in pairs(MODULE.Credits) do
				local w,h = draw.SimpleText(k, "Default", ScrW() - MODULE.CreditW - 20, ScrH() - MODULE.CreditH - 100 + pos, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if(w > maxw) then maxw = w end
				pos = pos + h + 10
			end
			
			MODULE.CreditW = maxw
			MODULE.CreditH = pos
		end
		if(MODULE:ValidateChannel("BaseSound") and GetConVarNumber("vermilion_fft") == 1 and MODULE:GetChannel("BaseSound").AudioChannel:GetState() != 0) then
			local tab = {}
			local num = MODULE:GetChannel("BaseSound").AudioChannel:FFT(tab, FFT_256)
			local width = 5
			local spacing = 1
			
			if(num > 80) then num = 80 end -- limit to 80 channels
			local xpos = ScrW() - 10 - ((width + spacing) * num)
			local totalLen = xpos
			local ypos = ScrH() - 100
			local percent = (MODULE:GetChannel("BaseSound").AudioChannel:GetTime() / MODULE:GetChannel("BaseSound").AudioChannel:GetLength()) * num -- get the progress through the track as a percentage of the number of channels.
			if(not isfunction(MODULE.Visualisers[GetConVarString("vermilion_fft_type")])) then
				MODULE.Visualisers["Default"](tab, percent, xpos, ypos, width, spacing)
				return
			end
			MODULE.Visualisers[GetConVarString("vermilion_fft_type")](tab, percent, xpos, ypos, width, spacing)
		end
	end)
	
end

Vermilion:RegisterModule(MODULE)