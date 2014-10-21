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
	"stopsound"
}
MODULE.NetworkStrings = {
	"VPlaySound",
	"VPlayStream",
	"VPlaySoundCloud",
	"VStop"
}

MODULE.Channels = {}

MODULE.Visualisers = {}

function MODULE:RegisterVisualiser(name, drawFunc)
	self.Visualisers[name] = drawFunc
end

function MODULE:RegisterChatCommands()
	
end

function MODULE:InitShared()
	if(SERVER) then
		AddCSLuaFile("vermilion2/modules/sound/soundcloud_bindings.lua")
	end
	include("vermilion2/modules/sound/soundcloud_bindings.lua")
end

function MODULE:InitServer()
	
end

function MODULE:InitClient()

	CreateClientConVar("vermilion_fft", 1, true, false)
	CreateClientConVar("vermilion_fft_type", "Default", true, false)
	
	function MODULE:PlaySoundTest()
		local path = "spin.mp3"
		local index = "BaseSound"
		local loop = false
		local volume = 100 / 100
	
		local typ = "noplay"
		if(loop) then typ = typ .. " noblock" end
		sound.PlayFile("sound/" .. path, typ, function(station, errorID)
			if(IsValid(station)) then
				station:EnableLooping(loop)
				station:Play()
				station:SetVolume(volume)
				MODULE.Channels[index] = station
			else
				print(errs[tostring(errorID)])
			end
		end)
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
			return not (IsValid(MODULE.Channels["BaseSound"]) and GetConVarNumber("vermilion_fft") == 1 and MODULE.Channels["BaseSound"]:GetState() != 0)
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
		if(IsValid(MODULE.Channels["BaseSound"]) and GetConVarNumber("vermilion_fft") == 1 and MODULE.Channels["BaseSound"]:GetState() != 0) then
			local tab = {}
			local num = MODULE.Channels["BaseSound"]:FFT(tab, FFT_256)
			local width = 5
			local spacing = 1
			
			if(num > 80) then num = 80 end -- limit to 80 channels
			local xpos = ScrW() - 10 - ((width + spacing) * num)
			local totalLen = xpos
			local ypos = ScrH() - 100
			local percent = (MODULE.Channels["BaseSound"]:GetTime() / MODULE.Channels["BaseSound"]:GetLength()) * num -- get the progress through the track as a percentage of the number of channels.
			MODULE.Visualisers[GetConVarString("vermilion_fft_type")](tab, percent, xpos, ypos, width, spacing)
		end
	end)
	
end

Vermilion:RegisterModule(MODULE)