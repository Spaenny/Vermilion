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

function VToolkit.NetSanitiseTable(tab)
	local rtab = {}
	for i,k in pairs(tab) do
		if(istable(k)) then rtab[i] = VToolkit.NetSanitiseTable(k) else
			if(not (isfunction(k))) then
				rtab[i] = k
			end
		end
	end
	return rtab
end

function net.ReadBoolean()
	return net.ReadBit() == 1
end

-- just to make it look nicer
function net.WriteBoolean(bool)
	net.WriteBit(bool)
end

VToolkit.TimeDiff = 0

function VToolkit:ServerTime()
	if(SERVER) then return os.time() end
	return os.time() + self.TimeDiff
end


if(SERVER) then
	util.AddNetworkString("VTimeSync")
	-- use hook.Add here since Vermilion hasn't overwritten the hooks yet.
	hook.Add("PlayerSpawn", "VTimeSync", function(ply)
		net.Start("VTimeSync")
		net.WriteUInt(os.time(), 32)
		net.Send(ply)
	end)
else
	net.Receive("VTimeSync", function(len)
		VToolkit.TimeDiff = net.ReadUInt(32) - os.time()
		print("VToolkit: Synced the client time with the server.")
	end)
end
