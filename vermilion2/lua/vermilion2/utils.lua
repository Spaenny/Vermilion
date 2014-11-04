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



function Vermilion.ParseChatLineForCommand(line)
	local command = string.Trim(string.sub(line, 1, string.find(line, " ") or nil))
	local response = {}
	for i,k in pairs(Vermilion.ChatCommands) do
		if(string.find(line, " ")) then
			if(command == i) then
				table.insert(response, { Name = i, Syntax = k.Syntax })
			end
		elseif(string.StartWith(i, command)) then
			table.insert(response, { Name = i, Syntax = k.Syntax })
		end
	end
	for i,k in pairs(Vermilion.ChatAliases) do
		if(string.find(line, " ")) then
			if(command == i) then
				table.insert(response, { Name = i, Syntax = "(alias of " .. k .. ") - " .. Vermilion.ChatCommands[k].Syntax })
			end
		elseif(string.StartWith(i, command)) then
			table.insert(response, { Name = i, Syntax = "(alias of " .. k .. ") - " .. Vermilion.ChatCommands[k].Syntax })
		end
	end
	
	return command, response
end

function Vermilion.ParseChatLineForParameters(line)
	local parts = string.Explode(" ", line, false)
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
			if(string.EndsWith(part, "\"")) then
				table.insert(parts2, string.Replace(part, "\"", ""))
				part = ""
				continue
			end
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
	local cmdName = parts[1]
	table.remove(parts, 1)
	
	return cmdName, parts
end