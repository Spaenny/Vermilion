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
 
 These are unofficial bindings for the SoundCloud API for Gmod Lua and is in no way endorsed by SoundCloud
 or Facepunch Studios.
]]

SoundCloud = {}

SoundCloud.ClientID = "723bb3b64d04057d0c11ae48cc57ab80"

SoundCloud.Utils = {}

function SoundCloud.Utils.UrlEncode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w %-%_%.%~])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
		end
	return str
end

SoundCloud.Users = {}

function SoundCloud:Resolve(url, scallback, fcallback)
	local scallback1 = scallback
	self:RunQuery("resolve.json?url=" .. url .. "&client_id=%%clientid%%", function(data)
		if(isfunction(scallback)) then scallback1(data.id) end
	end, fcallback)
end

function SoundCloud:RunQuery(url, scallback, fcallback)
	local targetURL = string.Replace("http://api.soundcloud.com/" .. url, "%%clientid%%", self.ClientID, false)
	--print(targetURL)
	http.Fetch(targetURL, function(body, len, headers, code)
		if(code == 401) then
			if(fcallback != nil) then fcallback("Bad ClientID") end
			return
		end
		if(code == 404) then
			if(fcallback != nil) then fcallback("Nothing found") end
			return
		end
		local data = util.JSONToTable(body)
		if(data == nil) then
			print(body)
			if(fcallback != nil) then fcallback("No valid data returned.") end
			return
		end
		if(scallback != nil) then scallback(data) end
	end, function(err)
		if(fcallback != nil) then fcallback(err) end
	end)
end

function SoundCloud.Users:Search(query, scallback, fcallback)
	SoundCloud:RunQuery("users.json?client_id=%%clientid%%&q=" .. SoundCloud.Utils.UrlEncode(query), scallback, fcallback)
end

function SoundCloud.Users:GetUser(userID, scallback, fcallback, r1)
	if(tonumber(userID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. userID, function(id)
			self:GetUser(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("users/" .. userID .. ".json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Users:GetTracks(userID, scallback, fcallback, r1)
	if(tonumber(userID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. userID, function(id)
			self:GetTracks(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("users/" .. userID .. "/tracks.json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Users:GetPlaylists(userID, scallback, fcallback, r1)
	if(tonumber(userID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. userID, function(id)
			self:GetPlaylists(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("users/" .. userID .. "/playlists.json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Users:GetFollowed(userID, scallback, fcallback, r1)
	if(tonumber(userID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. userID, function(id)
			self:GetFollowed(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("users/" .. userID .. "/followings.json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Users:GetFollowers(userID, scallback, fcallback, r1)
	if(tonumber(userID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. userID, function(id)
			self:GetFollowers(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("users/" .. userID .. "/followers.json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Users:GetComments(userID, scallback, fcallback, r1)
	if(tonumber(userID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. userID, function(id)
			self:GetComments(id, scallback, fcallback, true)
		end, fcallback)
	end
	SoundCloud:RunQuery("users/" .. userID .. "/comments.json?client_id=%%clientid%%", scallback, fcallback)
end


SoundCloud.Tracks = {}

function SoundCloud.Tracks:GetTrack(trackID, scallback, fcallback, r1)
	if(tonumber(trackID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. trackID, function(id)
			self:GetTrack(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("tracks/" .. trackID .. ".json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Tracks:GenerateStream(trackID)
	return "https://api.soundcloud.com/tracks/" .. trackID .. "/stream?client_id=" .. SoundCloud.ClientID

end

function SoundCloud.Tracks:Search(query, scallback, fcallback)
	SoundCloud:RunQuery("tracks.json?client_id=%%clientid%%&q=" .. SoundCloud.Utils.UrlEncode(query), scallback, fcallback)
end

function SoundCloud.Tracks:GetComments(trackID, scallback, fcallback, r1)
	if(tonumber(trackID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. trackID, function(id)
			self:GetComments(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("tracks/" .. trackID .. "/comments.json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Tracks:GetFavoriters(trackID, scallback, fcallback, r1)
	if(tonumber(trackID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. trackID, function(id)
			self:GetFavoriters(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("tracks/" .. trackID .. "/favoriters.json?client_id=%%clientid%%", scallback, fcallback)
end


SoundCloud.Playlists = {}

function SoundCloud.Playlists:GetPlaylist(playlistID, scallback, fcallback, r1)
	if(tonumber(playlistID) == nil and not r1) then
		SoundCloud:Resolve("https://soundcloud.com/" .. playlistID, function(id)
			self:GetPlaylist(id, scallback, fcallback, true)
		end, fcallback)
		return
	end
	SoundCloud:RunQuery("playlists/" .. playlistID .. ".json?client_id=%%clientid%%", scallback, fcallback)
end

function SoundCloud.Playlists:Search(query, scallback, fcallback)
	SoundCloud:RunQuery("playlists.json?client_id=%%clientid%%&q=" .. SoundCloud.Utils.UrlEncode(query), scallback, fcallback)
end