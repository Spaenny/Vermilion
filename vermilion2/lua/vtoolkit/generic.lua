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

function VToolkit.LookupPlayer(name, log)
	log = log or Vermilion.Log
	local results = {}
	if(name == nil) then return nil end
	
	for i,ply in pairs(VToolkit.GetValidPlayers()) do
		if(string.find(string.lower(ply:GetName()), string.lower(name))) then
			table.insert(results, ply)
		end
	end
	
	if(table.Count(results) == 1) then
		return results[1]
	elseif(table.Count(results) > 1) then
		log("Warning: ambiguous results for search " .. name .. " on the server. (Search matched " .. tostring(table.Count(results)) .. " players.)")
	elseif(table.Count(results) == 0) then
		log("Warning: no results for user " .. name .. " on the server.")
	end
	
end

function VToolkit.LookupPlayerBySteamID(steamid)
	for i,ply in pairs(player.GetAll()) do
		if(ply:SteamID() == steamid) then
			return ply
		end
	end
	return nil
end

function VToolkit.CBound(Point1, Point2)
	local CBound = {}
	CBound.Point1 = Point1
	CBound.Point2 = Point2
	
	function CBound:IsInside(point)
		if(isentity(point) and point:IsPlayer()) then
			return point:GetPos():WithinAABox(self.Point1, self.Point2) or point:GetPos():WithinAABox(self.Point2, self.Point1) or (point:GetPos() + Vector(0, 0, 80)):WithinAABox(self.Point1, self.Point2) or (point:GetPos() + Vector(0, 0, 80)):WithinAABox(self.Point2, self.Point1)
		end
		if(isentity(point)) then return point:GetPos():WithinAABox(self.Point1, self.Point2) or point:GetPos():WithinAABox(self.Point2, self.Point1) end
		return point:WithinAABox(self.Point1, self.Point2) or point:WithinAABox(self.Point2, self.Point1)
	end
	
	function CBound:GetEnts()
		return ents.FindInBox(self.Point2, self.Point2)
	end
	
	function CBound:Intersects(ocbound)
		for i,vert in pairs(ocbound:GetAllVertices()) do
			if(self:IsInside(vert)) then return true end
		end
		for i,vert in pairs(self:GetAllVertices()) do
			if(ocbound:IsInside(vert)) then return true end
		end
		return false
	end
	
	function CBound:GetAllVertices()
		local verts = {}
		table.insert(verts, self.Point1)
		table.insert(verts, self.Point2)
		table.insert(verts, Vector(self.Point1.x, self.Point2.y, self.Point1.z))
		table.insert(verts, Vector(self.Point2.x, self.Point1.y, self.Point1.z))
		table.insert(verts, Vector(self.Point2.x, self.Point2.y, self.Point1.z))
		table.insert(verts, Vector(self.Point1.x, self.Point2.y, self.Point2.z))
		table.insert(verts, Vector(self.Point2.x, self.Point1.y, self.Point2.z))
		table.insert(verts, Vector(self.Point1.x, self.Point1.y, self.Point2.z))
		return verts
	end
	
	function CBound:Volume()
		local Point1w = Vector(self.Point1.x, self.Point2.y, self.Point1.z)
		local Point1l = Vector(self.Point2.x, self.Point1.y, self.Point1.z)
		local Point1h = Vector(self.Point1.x, self.Point1.y, self.Point2.z)
		
		local saTop = self.Point1:Distance(Point1w) * self.Point1:Distance(Point1l)
		return saTop * self.Point1:Distance(Point1h)
	end
	
	function CBound:SurfaceArea()
		return -1 --cba to do this now
	end
	
	return CBound
end

function VToolkit.PerPlayerStorage()
	local storage = {}
	storage.data = {}
	
	function storage:Store(vplayer, key, data)
		if(self.data[vplayer:SteamID()] == nil) then self.data[vplayer:SteamID()] = {} end
		self.data[vplayer:SteamID()][key] = data
	end
	
	function storage:Get(vplayer, key, default)
		if(self.data[vplayer:SteamID()] != nil) then
			if(self.data[vplayer:SteamID()][key] != nil) then return self.data[vplayer:SteamID()][key] end
		end
		return default
	end
	
	function storage:GetPlayerData(vplayer)
		return self.data[vplayer:SteamID()]
	end
	
	function storage:Remove(vplayer, key)
		if(self.data[vplayer:SteamID()] != nil) then
			self.data[vplayer:SteamID()][key] = nil
		end
	end
	
	function storage:HasData(vplayer, key)
		if(self.data[vplayer:SteamID()] != nil) then
			return self.data[vplayer:SteamID()][key] != nil
		end
		return false
	end
	
	function storage:HasPlayer(vplayer)
		return self.data[vplayer:SteamID()] != nil
	end
	
	function storage:Clear(vplayer)
		if(vplayer == nil) then
			self.data[vplayer:SteamID()] = nil
		else
			self.data = {}
		end
	end
	
	function storage:ToJSON()
		return util.TableToJSON(self.data)
	end
end

function VToolkit.FindInTable(tab, sorter)
	local rtab = {}
	for k,v in pairs(tab) do
		if(sorter(v)) then rtab[k] = v end
	end
	return rtab
end

function VToolkit.FilterTable(tab, callback)
	local new = {}
	for k,v in pairs(tab) do
		if(callback(k, v)) then new[k] = v end
	end
	return new
end

function VToolkit.GetValidPlayers(withBots)
	withBots = withBots or true
	return VToolkit.FilterTable(player.GetAll(), function(index, ply)
		if(not IsValid(ply)) then return false end
		if(not withBots and ply:IsBot()) then return false end
		return true
	end)
end

function VToolkit.RemoveSensitiveInfo(t, indent, done, parent, grandparent)
	local ntab = {}
	done = done or {}
	indent = indent or 0
	for i,k in pairs(t) do
		if(key == "SteamID" or key == "CountryCode" or key == "CountryName" or (key == "Name" and grandparent != "Ranks") or parent == "Positive" or parent == "Negative" or key == "longest_shot_holder") then
			ntab[key] = "[REDACTED]"
			continue
		end
		if(istable(value) and not done[value]) then
			done [value] = true
			ntab[key] = VToolkit.RemoveSensitiveInfo(value, indent + 2, done, key, parent)
		else
			ntab[key] = value
		end
	end
	return ntab
end

function VToolkit.Merge(destination, source)
	for i,k in pairs(source) do
		local has = false
		for i1,k1 in pairs(destination) do
			if(k1 == k) then has = true break end
		end
		if(not has) then table.insert(destination, k) end
	end
end

function VToolkit.GetWeaponName(vclass)
	local target = vclass
	if(not isstring(target)) then -- assume it is a weapon
		target = target:GetClass()
	end
	if(list.Get("Weapon")[target] == nil) then return nil end
	return list.Get( "Weapon" )[target]['PrintName']
end

function VToolkit.GetNPCName(vclass)
	local target = vclass
	if(not isstring(target)) then -- assume it is an NPC
		target = target:GetClass()
	end
	if(list.Get("NPC")[vclass] == nil) then return nil end
	return list.Get( "NPC" )[vclass]['Name']
end