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

Vermilion.GeoIP = {}
Vermilion.GeoIP.Target = "http://freegeoip.net/json/"
Vermilion.GeoIP.DoFSCache = true
Vermilion.GeoIP.FSCacheTime = 60 * 60 * 24 * 7 -- 1 week
Vermilion.GeoIP.FSCacheFile = "vermilion2/geoipcache.txt"
Vermilion.GeoIP.BlockedIPs = {
	"loopback",
	"localhost",
	"127.0.0.1",
	"::1"
}

if(SERVER) then
	util.AddNetworkString("VGetClientIP")
	
	Vermilion.GeoIP.Requests = {}
	
	net.Receive("VGetClientIP", function(len, vplayer)
		local requestData = Vermilion.GeoIP.Requests[vplayer:SteamID()]
		local ip = net.ReadString()
		Vermilion.GeoIP:Trace(ip, requestData.Success, requestData.Failure)
		Vermilion.GeoIP.Requests[vplayer:SteamID()] = nil
	end)
else
	net.Receive("VGetClientIP", function()
		net.Start("VGetClientIP")
		net.WriteString(Vermilion.GeoIP.MyIP)
		net.SendToServer()
	end)
end

Vermilion.GeoIP.MyIP = ""
http.Fetch("http://icanhazip.com", function(body)
	Vermilion.GeoIP.MyIP = string.Trim(body)
end)


Vermilion:AddHook(Vermilion.Event.MOD_LOADED, "GeoIPOptions", true, function()
	local mod = Vermilion:GetModule("server_settings")
	if(mod != nil) then
		mod:AddOption("Vermilion", "geoip_enabled", "Enable GeoIP Services", "Checkbox", "Misc")
	end
end)


if(SERVER) then
	Vermilion:GetData("geoip_enabled", true, true) -- create the variable if it doesn't exist.
	
	Vermilion:AddDataChangeHook("geoip_enabled", "network_geoip", function(val)
		SetGlobalBool("geoip_enabled", val)
	end)
	SetGlobalBool("geoip_enabled", Vermilion:GetData("geoip_enabled", true, true))
	
	Vermilion.GeoIP.Cache = {}

	function Vermilion.GeoIP:LoadConfiguration()
		if(file.Exists(self.FSCacheFile, "DATA") and self.DoFSCache) then
			self.Cache = util.JSONToTable(file.Read(self.FSCacheFile, "DATA"))
			if(self.Cache.ExpiryTime <= os.time()) then
				Vermilion.Log("GeoIP cache has expired. Removing.")
				table.Empty(self.Cache)
				self.Cache.ExpiryTime = os.time() + self.FSCacheTime
				self.Cache.Addresses = {}
				file.Write(self.FSCacheFile, "")
			end
		else
			self.Cache.ExpiryTime = os.time() + self.FSCacheTime
			self.Cache.Addresses = {}
		end
	end

	timer.Create("VGeoIPFlush", 60, 0, function()
		if(Vermilion.GeoIP.Cache.ExpiryTime > os.time()) then return end
		Vermilion.Log("GeoIP cache has expired. Removing.")
		table.Empty(self.Cache)
		self.Cache.ExpiryTime = os.time() + self.FSCacheTime
		self.Cache.Addresses = {}
		file.Write(self.FSCacheFile, "")
	end)

	Vermilion.GeoIP:LoadConfiguration()

	if(Vermilion.GeoIP.DoFSCache) then
		Vermilion:AddHook("ShutDown", "SaveGeoIPData", true, function()
			file.Write(Vermilion.GeoIP.FSCacheFile, util.TableToJSON(Vermilion.GeoIP.Cache))
		end)
	end

	function Vermilion.GeoIP:Trace(ip, callback, fcallback, vplayer)
		if(not Vermilion:GetData("geoip_enabled", true, true)) then
			if(isfunction(fcallback)) then fcallback(ip, "GeoIP is disabled") end
			return
		end
		if(table.HasValue(self.BlockedIPs, ip) or string.StartWith(ip, "192.168") --[[ assume that any address starting with "192.168" is an internal address. ]]) then
			if(vplayer != nil) then
				Vermilion.GeoIP.Requests[vplayer:SteamID()] = {
					Success = callback,
					Failure = fcallback
				}
				net.Start("VGetClientIP")
				net.Send(vplayer)
				return
			end
			if(isfunction(fcallback)) then fcallback(ip, "Not Found") end
			return
		end
		if(self.Cache.Addresses[ip] != nil) then
			if(isfunction(callback)) then callback(ip, table.Copy(self.Cache.Addresses[ip])) end
			return
		end
		http.Fetch(table.concat({ self.Target, ip }, ""), function(body, len, headers, code)
			if(string.Trim(body) == "Not Found") then
				if(vplayer != nil) then
					Vermilion.GeoIP.Requests[vplayer:SteamID()] = {
						Success = callback,
						Failure = fcallback
					}
					net.Start("VGetClientIP")
					net.Send(vplayer)
					return
				end
				Vermilion.GeoIP.Cache.Addresses[ip] = {
					CountryCode = "Unknown",
					CountryName = "Unknown",
					Lat = 0,
					Long = 0
				}
				if(isfunction(fcallback)) then fcallback(ip, "Not Found") end
				return
			end
			local data = util.JSONToTable(body)
			Vermilion.GeoIP.Cache.Addresses[ip] = {
				CountryCode = data.country_code,
				CountryName = data.country_name,
				Lat = data.latitude,
				Long = data.longitude
			}
			if(isfunction(callback)) then callback(ip, table.Copy(Vermilion.GeoIP.Cache.Addresses[ip])) end
		end, function(err)
			if(isfunction(fcallback)) then fcallback(ip, err) end
		end)
	end

	function Vermilion.GeoIP:TracePlayer(vplayer, callback, fcallback)
		local addr = vplayer:IPAddress()
		if(string.find(addr, ":")) then
			addr = string.sub(addr, 0, select(1, string.find(addr, ":")) - 1)
		end
		self:Trace(addr, callback, fcallback, vplayer)
	end
	
	Vermilion:AddHook("PlayerInitialSpawn", "GeoIPUpdate", true, function(vplayer)
		Vermilion.GeoIP:TracePlayer(vplayer, function(ip, data)
			vplayer:SetNWString("CountryCode", data.CountryCode)
		end)
	end)
	

else
	
	--- temp code until I add the new TargetID
	Vermilion:AddHook("HUDDrawTargetID", "GeoIPTargetID", true, function()
		if(not GetGlobalBool("geoip_enabled")) then return end
		local tr = util.GetPlayerTrace( LocalPlayer() )
		local trace = util.TraceLine( tr )
		if (!trace.Hit) then return end
		if (!trace.HitNonWorld) then return end
		
		if (not trace.Entity:IsPlayer() or trace.Entity:IsBot()) then
			return
		end
		
		local MouseX, MouseY = gui.MousePos()
		
		if ( MouseX == 0 && MouseY == 0 ) then
		
			MouseX = ScrW() / 2
			MouseY = ScrH() / 2
		
		end
		
		local x = MouseX
		local y = MouseY
		
		x = x - 22 / 2
		y = y + 75

		if(trace.Entity.VCountry == nil or trace.Entity.VCountry == "") then
			trace.Entity.VCountry = string.lower(trace.Entity:GetNWString("CountryCode"))
			trace.Entity.VCountryMat = Material("flags16/" .. trace.Entity.VCountry .. ".png", "noclamp smooth")
		end
		
		surface.SetMaterial(trace.Entity.VCountryMat)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(x, y, 24, 16.5)
	end)
	
end