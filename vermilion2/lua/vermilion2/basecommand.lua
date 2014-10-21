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
local subcommands = {}
if(SERVER) then
	util.AddNetworkString("Vermilion_ConsoleUpdate")

	function Vermilion:AddCommand(name, executor)
		subcommands[name] = executor
	end

	Vermilion:AddCommand("dump_settings", function(sender, args)
		PrintTable(Vermilion.Data)
	end)
	
	hook.Add("PlayerInitialSpawn", "Vermilion_ConsoleUpdate", function(vplayer)
		timer.Simple(1, function()
			net.Start("Vermilion_ConsoleUpdate")
			net.WriteTable(table.GetKeys(subcommands))
			net.Send(vplayer)
		end)
	end)

else
	net.Receive("Vermilion_ConsoleUpdate", function()
		subcommands = net.ReadTable()
	end)
end

concommand.Add("vermilion", function(sender, cmd, args, fullstring)
	if(table.Count(args) < 1) then
		Vermilion.Log("Unknown Command!")
		return
	end
	local cmd = subcommands[args[1]]
	if(cmd == nil) then
		Vermilion.Log("Unknown Command!")
		return
	end
	local cargs = table.Copy(args)
	table.remove(cargs, 1)
	cmd(sender, cargs)
end, function(cmd, args)
	local tab = {}
	local nargs = string.Trim(args)
	nargs = string.lower(nargs)
	for i,k in pairs(subcommands) do
		if(string.find(string.lower(i), nargs)) then
			table.insert(tab, "vermilion " .. i)
		end
	end
	return tab
end, "Vermilion Base Command")