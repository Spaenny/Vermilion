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

if(SERVER) then
	util.AddNetworkString("VChatPrediction")
	
	net.Receive("VChatPrediction", function(len, vplayer)
		local current = net.ReadString()
		
		local command, response = Vermilion.ParseChatLineForCommand(current)
		
		local predictor = nil
		if(Vermilion.ChatAliases[command] != nil) then
			local cmdObj = Vermilion.ChatCommands[Vermilion.ChatAliases[command]]
			if(cmdObj != nil) then
				predictor = cmdObj.Predictor
			end
		else
			local cmdObj = Vermilion.ChatCommands[command]
			if(cmdObj != nil) then
				predictor = cmdObj.Predictor
			end
		end
		
		if(string.find(current, " ") and predictor != nil) then
			local cmdName,parts = Vermilion.ParseChatLineForParameters(current)
			local dataTable = predictor(table.Count(parts), parts[table.Count(parts)], parts, vplayer)
			if(dataTable != nil) then
				for i,k in pairs(dataTable) do
					if(istable(k)) then
						table.insert(response, k)
					else
						table.insert(response, { Name = k, Syntax = "" })
					end					
				end
			end
		end
		net.Start("VChatPrediction")
		net.WriteTable(response)
		net.Send(vplayer)
	end)
	
else
	net.Receive("VChatPrediction", function()
		local response = net.ReadTable()
		Vermilion.ChatPredictions = response
	end)
	
	Vermilion.ChatOpen = false
	
	Vermilion:AddHook("StartChat", "VOpenChatbox", false, function()
		Vermilion.ChatOpen = true
	end)
	
	Vermilion:AddHook("FinishChat", "VCloseChatbox", false, function()
		Vermilion.ChatOpen = false
		Vermilion.ChatPredictions = {}
	end)
	
	Vermilion:AddHook("HUDShouldDraw", "ChatHideHUD", false, function(name)
		if(Vermilion.CurrentChatText == nil) then return end
		if(string.StartWith(Vermilion.CurrentChatText, "!") and (name == "NetGraph" or name == "CHudAmmo")) then return false end
	end)
	
	Vermilion.ChatPredictions = {}
	Vermilion.ChatTabSelected = 1
	Vermilion.ChatBGW = 0
	Vermilion.ChatBGH = 0
	Vermilion.MoveEnabled = true
	
	Vermilion:AddHook("Think", "ChatMove", false, function()
		if(Vermilion.ChatOpen and Vermilion.MoveEnabled and table.Count(Vermilion.ChatPredictions) > 0) then
			if(input.IsKeyDown(KEY_DOWN)) then
				if(string.find(Vermilion.CurrentChatText, " ")) then
					if(Vermilion.ChatTabSelected + 1 > table.Count(Vermilion.ChatPredictions)) then
						Vermilion.ChatTabSelected = 2
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected + 1
					end
				else
					if(Vermilion.ChatTabSelected + 1 > table.Count(Vermilion.ChatPredictions)) then
						Vermilion.ChatTabSelected = 1
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected + 1
					end
				end
				Vermilion.MoveEnabled = false
				timer.Simple(0.1, function()
					Vermilion.MoveEnabled = true
				end)
			elseif(input.IsKeyDown(KEY_UP)) then
				if(string.find(Vermilion.CurrentChatText, " ")) then
					if(Vermilion.ChatTabSelected - 1 < 2) then
						Vermilion.ChatTabSelected = table.Count(Vermilion.ChatPredictions)
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected - 1
					end
				else
					if(Vermilion.ChatTabSelected - 1 < 1) then
						Vermilion.ChatTabSelected = table.Count(Vermilion.ChatPredictions)
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected - 1
					end
				end
				Vermilion.MoveEnabled = false
				timer.Simple(0.1, function()
					Vermilion.MoveEnabled = true
				end)
			end
		end
	end)
	
	Vermilion:AddHook("OnChatTab", "VInsertPrediction", false, function()
		if(table.Count(Vermilion.ChatPredictions) > 0 and string.find(Vermilion.CurrentChatText, " ") and table.Count(Vermilion.ChatPredictions) > 1) then
			if(Vermilion.ChatPredictions[Vermilion.ChatTabSelected].Name == "") then return end
			local commandText = Vermilion.CurrentChatText
			local parts = string.Explode(" ", commandText, false)
			local parts2 = {}
			local part = ""
			local isQuoted = false
			for i,k in pairs(parts) do
				if(isQuoted and string.find(k, "\"")) then
					table.insert(parts2, string.Replace(part .. " " .. k, "\"", ""))
					isQuoted = false
					part = ""
				elseif(not isQuoted and string.find(k, "\"")) then
					part = k
					isQuoted = true
				elseif(isQuoted) then
					part = part .. " " .. k
				else
					table.insert(parts2, k)
				end
			end
			if(isQuoted) then table.insert(parts2, string.Replace(part, "\"", "")) end
			parts = {}
			for i,k in pairs(parts2) do
				--if(k != nil and k != "") then
					table.insert(parts, k)
				--end
			end
			parts[table.Count(parts)] = Vermilion.ChatPredictions[Vermilion.ChatTabSelected].Name
			
			return table.concat(parts, " ", 1) .. " "
		end
		if(Vermilion.ChatPredictions != nil and table.Count(Vermilion.ChatPredictions) > 0 and Vermilion.ChatTabSelected == 0) then
			return "!" .. Vermilion.ChatPredictions[1].Name .. " "
		end
		if(Vermilion.ChatPredictions != nil and Vermilion.ChatTabSelected > 0) then
			if(Vermilion.ChatPredictions[Vermilion.ChatTabSelected] == nil) then return end
			return "!" .. Vermilion.ChatPredictions[Vermilion.ChatTabSelected].Name .. " "
		end
	end)
	
	Vermilion:AddHook("HUDPaint", "PredictDraw", false, function()
		if(table.Count(Vermilion.ChatPredictions) > 0 and Vermilion.ChatOpen) then
			local pos = 0
			local xpos = 0
			local maxw = 0
			local text = "Press up/down to select a suggestion and press tab to insert it."
			if(Vermilion:GetModule("chatbox") != nil and GetConVarNumber("vermilion_replace_chat") == 1) then
				text = "Press up/down to select a suggestion and press right arrow key to insert it."
			end
			local mapbx = nil
			local maptx = nil
			if(chat.GetChatBoxSize == nil) then
				mapbx = math.Remap(545, 0, 1366, 0, ScrW())
				maptx = math.Remap(550, 0, 1366, 0, ScrW())

				if(ScrW() > 1390) then
					mapbx = mapbx + 100
					maptx = maptx + 100
				end
			else
				mapbx = select(1, chat.GetChatBoxSize()) + 10
				mapbx = select(1, chat.GetChatBoxSize()) + 15
			end
			draw.RoundedBox(2, mapbx, select(2, chat.GetChatBoxPos()) - 15, Vermilion.ChatBGW + 10, Vermilion.ChatBGH + 5, Color(0, 0, 0, 128))
			draw.SimpleText(text, "Default", maptx, select(2, chat.GetChatBoxPos()) - 20, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			Vermilion.ChatBGH = 0
			for i,k in pairs(Vermilion.ChatPredictions) do
				local text = k.Name
				if(table.Count(Vermilion.ChatPredictions) <= 8 or string.find(Vermilion.CurrentChatText, " ")) then
					if(k.Name != "") then
						text = k.Name .. " " .. k.Syntax
					else
						text = k.Syntax
					end
				end
				local colour = Color(255, 255, 255)
				if(i == Vermilion.ChatTabSelected and Vermilion.ChatPredictions[Vermilion.ChatTabSelected].Name != "") then colour = Color(255, 0, 0) end
				local w,h = draw.SimpleText(text, "Default", maptx + xpos, select(2, chat.GetChatBoxPos()) + pos, colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if(maxw < w) then maxw = w end
				pos = pos + h + 5
				if(pos > Vermilion.ChatBGH) then Vermilion.ChatBGH = pos end
				if(pos + select(2, chat.GetChatBoxPos()) + 20 >= ScrH()) then
					xpos = xpos + maxw + 10
					maxw = 0
					pos = 0
				end
			end
			Vermilion.ChatBGW = xpos + maxw
		end
	end)
	
	Vermilion:AddHook("ChatTextChanged", "ChatPredict", false, function(chatText)
		if(Vermilion.CurrentChatText != chatText) then
			if(string.find(chatText, " ")) then
				Vermilion.ChatTabSelected = 2
			else
				Vermilion.ChatTabSelected = 1
			end
		end
		Vermilion.CurrentChatText = chatText
		
		if(string.StartWith(chatText, "!")) then
			net.Start("VChatPrediction")
			local space = nil
			if(string.find(chatText, " ")) then
				space = string.find(chatText, " ") - 1
				
			end
			net.WriteString(string.sub(chatText, 2))
			net.SendToServer()
		else
			Vermilion.ChatPredictions = {}
		end
	end)
end