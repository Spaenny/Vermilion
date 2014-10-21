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

Vermilion.ChatCommands = {}
Vermilion.ChatAliases = {}

function Vermilion:AddChatCommand(activator, func, syntax, predictor)
	syntax = syntax or ""
	if(self.ChatCommands[activator] != nil) then
		self.Log("Chat command " .. activator .. " has been overwritten!")
	end
	self.ChatCommands[activator] = { Function = func, Syntax = syntax, Predictor = predictor }
	Vermilion:AddCommand(activator, function(sender, args)
		local success, err = pcall(func, sender, args, function(text) Vermilion.Log(text) end)
		if(not success) then
			Vermilion.Log("Command failed with an error: " .. tostring(err))
		end
	end)
end

function Vermilion:AliasChatCommand(command, aliasTo)
	if(self.ChatAliases[aliasTo] != nil) then
		self.Log("Chat alias " .. aliasTo .. " is being overwritten!")
	end
	self.ChatAliases[aliasTo] = command
end

function Vermilion:HandleChat(vplayer, text, targetLogger, isConsole)
	targetLogger = targetLogger or vplayer
	local logFunc = nil
	if(isfunction(targetLogger)) then
		logFunc = targetLogger
	else
		if(isConsole) then
			logFunc = function(text) if(sender == nil) then Vermilion.Log(text) else sender:PrintMessage(HUD_PRINTCONSOLE, text) end end
		else
			logFunc = function(text, typ, delay) Vermilion:AddNotification(targetLogger, text, typ, delay) end
		end
	end
	if(string.StartWith(text, Vermilion:GetData("command_prefix", "!", true))) then
		local commandText = string.sub(text, 2)
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
		table.insert(parts2, string.Trim(string.Replace(part, "\"", "")))
		parts = {}
		for i,k in pairs(parts2) do
			if(k != nil and k != "") then
				table.insert(parts, k)
			end
		end
		local commandName = parts[1]
		if(Vermilion.ChatAliases[commandName] != nil) then
			commandName = Vermilion.ChatAliases[commandName]
		end
		local command = Vermilion.ChatCommands[commandName]
		if(command != nil) then
			table.remove(parts, 1)
			local success, err = pcall(command.Function, vplayer, parts, logFunc)
			if(not success) then 
				logFunc("Command failed with an error " .. tostring(err), NOTIFY_ERROR, 25) 
			end
			return ""
		else
			logFunc("No such command!", NOTIFY_ERROR)
		end
	end
end

Vermilion:AddHook("PlayerSay", "Say1", false, function(vplayer, text, teamChat)
	return Vermilion:HandleChat(vplayer, text, vplayer, false)
end)