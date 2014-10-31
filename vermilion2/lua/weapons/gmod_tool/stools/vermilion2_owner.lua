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

-- This tool needs a rethink...

TOOL.Category = "Vermilion 2 Dev Toolkit"
TOOL.Name = "Owner"
TOOL.Tab = "Vermilion 2"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.vermilion2_owner.name", "Owner Tool (Vermilion 2 Dev Toolkit)")
	language.Add("tool.vermilion2_owner.desc", "Figure out who owns what")
	language.Add("tool.vermilion2_owner.0", "Left Click to print the owner")
end



function TOOL:LeftClick( trace )
	if(trace.Entity and not trace.Entity:IsWorld()) then
		if(SERVER) then
			local tplayer = Vermilion:GetUserBySteamID(trace.Entity.Vermilion_Owner)
			if(tplayer == nil) then
				Vermilion:AddNotification(self:GetOwner(), "Entity " .. tostring(trace.Entity:EntIndex()) .. " doesn't have an owner!", NOTIFY_ERROR)
				return
			end
			Vermilion:AddNotification(self:GetOwner(), "Entity " .. tostring(trace.Entity:EntIndex()) .. " is owned by " .. tplayer.Name)
		end
	end
	return true
end