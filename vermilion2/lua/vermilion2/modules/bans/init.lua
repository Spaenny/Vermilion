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
MODULE.Name = "Bans"
MODULE.ID = "bans"
MODULE.Description = "Manages the ban system."
MODULE.Author = "Ned"
MODULE.PreventDisable = true
MODULE.Permissions = {
	"ban_user",
	"unban_user",
	"kick_user",
	"manage_bans"
}
MODULE.NetworkStrings = {
	"VGetBanRecords",
	"VBanPlayer",
	"VKickPlayer",
	"VUnbanPlayer"
}
MODULE.DefaultPermissions = {
	{ Name = "admin", Permissions = {
			"ban_user",
			"unban_user",
			"kick_user",
			"manage_bans"
		}
	}
}
MODULE.BanReasons = {
	"Spamming props",
	"Spamming chat",
	"Spamming VoIP",
	"Circumventing protection measures",
	"Harassment",
	"Stupid questions",
	"Abusing privileges",
	"Hacking",
	"Using an aimbot",
	"Impersonation",
	"Prop-surfing",
	"Alternate account",
	"Disobeying administrator's instructions",
	"Asking for permissions"
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "ban",
		Description = "Bans a player",
		Syntax = "<name> <time:minutes (can be fractional, or 0 for permaban)> <reason>",
		CanMute = true,
		Permissions = { "ban_user" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
			if(pos == 2) then
				if(tonumber(current) == nil and current != nil and current != "") then
					return { { Name = "", Syntax = Vermilion:TranslateStr("not_number", nil, vplayer) } }
				end
			end
			if(pos == 3) then
				return VToolkit.MatchStringPart(MODULE.BanReasons, current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(tonumber(text[2]) == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("bad_syntax", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(target == sender) then
				log(Vermilion:TranslateStr("ban_self", nil, sender), NOTIFY_ERROR)
				return
			end
			MODULE:BanPlayer(target, sender, tonumber(text[2]) * 60, table.concat(text, " ", 3), log, glog)
		end,
		AllBroadcast = function(sender, text)
			if(tonumber(text[2]) == nil) then return end
			local time = tonumber(text[2]) * 60
			local reason = table.concat(text, " ", 3)
			if(time == 0) then
				return "All players were permanently banned by " .. sender:GetName() .. " with reason: " .. (reason or "No reason given")
			else
				return "All players were banned by " .. sender:GetName() .. " until " .. os.date("%d/%m/%y", os.time() + time) .. " with reason: " .. (reason or "No reason given")
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "kick",
		Description = "Kicks a player",
		Syntax = "<name> <reason>",
		CanMute = true,
		Permissions = { "kick_user" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
			if(pos == 2) then
				return VToolkit.MatchStringPart(MODULE.BanReasons, current)
			end
		end,
		Function = function(sender, text, log, glog)
			local target = VToolkit.LookupPlayer(text[1])
			if(target == sender) then
				log(Vermilion:TranslateStr("kick_self", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			glog(target:GetName() .. " was kicked by " .. sender:GetName() .. ": " .. table.concat(text, " ", 2))
			target:Kick("Kicked by ".. sender:GetName() .. ": " .. table.concat(text, " ", 2))
		end,
		AllBroadcast = function(sender, text)
			local reason = table.concat(text, " ", 2)
			return "All players were kicked by " .. sender:GetName() .. " with reason: " .. reason
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "unban",
		Description = "Unbans a player",
		Syntax = "<name>",
		CanMute = true,
		Permissions = { "unban_user" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE:GetData("bans", {}, true)) do
					if(string.find(string.lower(k.Name), string.lower(current))) then
						table.insert(tab, { Name = k.Name, Syntax = "(" .. (k.Reason or "No reason given") .. ")" })
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local candidates = {}
			for i,k in pairs(MODULE:GetData("bans", {}, true)) do
				if(string.find(string.lower(k.Name), string.lower(text[1]))) then
					table.insert(candidates, k)
				end
			end
			if(table.Count(candidates) > 1) then
				log("Too many results found. Please narrow your search.", NOTIFY_ERROR)
				return
			end
			if(table.Count(candidates) == 0) then
				log("No results found.", NOTIFY_ERROR)
				return
			end
			table.RemoveByValue(MODULE:GetData("bans", {}, true), candidates[1])
			glog(candidates[1].Name .. " was unbanned by " .. sender:GetName())
		end
	})
	
end

function MODULE:BanPlayer(vplayer, banner, time, reason, log, glog)
	if(IsValid(banner)) then
		log = log or function(text, typ, time) Vermilion:AddNotification(banner, text, typ, time) end
	else
		log = log or function(text, typ, time) Vermilion.Log(text) end
		banner = {}
		function banner:GetName()
			return "Vermilion"
		end
		function banner:SteamID()
			return "VERMILION"
		end
	end
	glog = glog or function(text, typ, time) Vermilion:BroadcastNotification(text, typ, time) end
	local has = false
	for i,k in pairs(MODULE:GetData("bans", {}, true)) do
		if(k.SteamID == vplayer:SteamID()) then
			has = true
			break
		end
	end
	if(has) then
		log("This player has already been banned!", NOTIFY_ERROR)
		return
	end
	if(time < 0) then
		log("Cannot ban player for less 0 minutes! Valid times are 0 (permaban), and any time greater than 0.", NOTIFY_ERROR)
		return
	end
	if(time == 0) then
		table.insert(MODULE:GetData("bans", {}, true), { Name = vplayer:GetName(), SteamID = vplayer:SteamID(), Reason = reason, BanTime = os.time(), ExpiryTime = 0, BannerSteamID = banner:SteamID(), BannerName = banner:GetName() })
		glog(vplayer:GetName() .. " was permanently banned by " .. banner:GetName() .. " with reason: " .. (reason or "No reason given"))
	else
		table.insert(MODULE:GetData("bans", {}, true), { Name = vplayer:GetName(), SteamID = vplayer:SteamID(), Reason = reason, BanTime = os.time(), ExpiryTime = os.time() + time, BannerSteamID = banner:SteamID(), BannerName = banner:GetName() })
		glog(vplayer:GetName() .. " was banned by " .. banner:GetName() .. " until " .. os.date("%d/%m/%y", os.time() + time) .. " with reason: " .. (reason or "No reason given"))
	end
	vplayer:Kick(reason or "No reason given")
end

function MODULE:GetBanData(steamid)
	for i,k in pairs(MODULE:GetData("bans", {}, true)) do
		if(k.SteamID == steamid) then return k end
	end
end

function MODULE:IsPlayerBanned(steamid)
	for i,k in pairs(MODULE:GetData("bans", {}, true)) do
		if(k.SteamID == steamid) then return true end
	end
	return false
end

function MODULE:UpdateBans()
	for i,k in pairs(MODULE:GetData("bans", {}, true)) do
		if(k.ExpiryTime <= os.time() and k.ExpiryTime > 0) then
			table.RemoveByValue(MODULE:GetData("bans", {}, true), k)
		end
	end
end

function MODULE:InitServer()
	self:AddHook("CheckPassword", function(steamid, ip, svpass, clpass, name)
		MODULE:UpdateBans()
		if(MODULE:IsPlayerBanned(util.SteamIDFrom64(steamid))) then
			Vermilion:BroadcastNotification(name .. " has tried to re-connect to the server!", NOTIFY_ERROR)
			if(Vermilion:GetModule("event_logger") != nil) then
				Vermilion:GetModule("event_logger"):AddEvent("exclamation", name .. " attempted to re-connect to the server!")
			end
			if(MODULE:GetBanData(util.SteamIDFrom64(steamid)).ExpiryTime == 0) then
				return false, "You are banned permanently: " .. (MODULE:GetBanData(util.SteamIDFrom64(steamid)).Reason or "No reason given")
			end
			return false, "You are banned until " .. os.date("%d/%m/%y", MODULE:GetBanData(util.SteamIDFrom64(steamid)).ExpiryTime) .. ": " .. (MODULE:GetBanData(util.SteamIDFrom64(steamid)).Reason or "No reason given")
		end
	end)
	
	self:NetHook("VGetBanRecords", function(vplayer)
		MODULE:NetStart("VGetBanRecords")
		net.WriteTable(MODULE:GetData("bans", {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VBanPlayer", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_bans")) then
			local ent = net.ReadEntity()
			if(IsValid(ent)) then
				MODULE:BanPlayer(ent, vplayer, net.ReadInt(32), net.ReadString())
				
				MODULE:NetStart("VGetBanRecords")
				net.WriteTable(MODULE:GetData("bans", {}, true))
				net.Broadcast()
			end
		end
	end)
	
	self:NetHook("VKickPlayer", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_bans")) then
			local ent = net.ReadEntity()
			if(IsValid(ent)) then
				ent:Kick(net.ReadString())
				MODULE:NetStart("VGetBanRecords")
				net.WriteTable(MODULE:GetData("bans", {}, true))
				net.Broadcast()
			end
		end
	end)
	
	self:NetHook("VUnbanPlayer", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_bans")) then
			local steamid = net.ReadString()
			for i,k in pairs(MODULE:GetData("bans", {}, true)) do
				if(k.SteamID == steamid) then
					table.RemoveByValue(MODULE:GetData("bans", {}, true), k)
					Vermilion:BroadcastNotification(k.Name .. " was unbanned by " .. vplayer:GetName())
					MODULE:NetStart("VGetBanRecords")
					net.WriteTable(MODULE:GetData("bans", {}, true))
					net.Broadcast()
					break
				end
			end
		end
	end)
end

function MODULE:InitClient()

	function MODULE:CreateBanForPanel(playersToBan)
		if(not istable(playersToBan)) then playersToBan = { playersToBan } end
		local bTimePanel = VToolkit:CreateFrame(
			{
				['size'] = { 640, 90 },
				['pos'] = { (ScrW() / 2) - 320, (ScrH() / 2) - 45 },
				['closeBtn'] = true,
				['draggable'] = true,
				['title'] = "Input ban time",
				['bgBlur'] = true
			}
		)
		
		VToolkit:SetDark(false)
		
		local yearsLabel = VToolkit:CreateLabel("Years:")
		yearsLabel:SetPos(10 + ((64 - yearsLabel:GetWide()) / 2), 30)
		yearsLabel:SetParent(bTimePanel)
		
		local yearsWang = VToolkit:CreateNumberWang(0, 1000)
		yearsWang:SetPos(10, 45)
		yearsWang:SetParent(bTimePanel)
		
		
		
		local monthsLabel = VToolkit:CreateLabel("Months:")
		monthsLabel:SetPos(84 + ((64 - monthsLabel:GetWide()) / 2), 30)
		monthsLabel:SetParent(bTimePanel)
		
		local monthsWang = VToolkit:CreateNumberWang(0, 12)
		monthsWang:SetPos(84, 45)
		monthsWang:SetParent(bTimePanel)
		monthsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 12) then
				wang:SetValue(0)
				yearsWang:SetValue(yearsWang:GetValue() + 1)
			end
		end
		
		
		
		local weeksLabel = VToolkit:CreateLabel("Weeks:")
		weeksLabel:SetPos(158 + ((64 - weeksLabel:GetWide()) / 2), 30)
		weeksLabel:SetParent(bTimePanel)
		
		local weeksWang = VToolkit:CreateNumberWang(0, 4)
		weeksWang:SetPos(158, 45)
		weeksWang:SetParent(bTimePanel)
		weeksWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 4) then
				wang:SetValue(0)
				monthsWang:SetValue(monthsWang:GetValue() + 1)
			end
		end
		
		
		
		local daysLabel = VToolkit:CreateLabel("Days:")
		daysLabel:SetPos(232 + ((64 - daysLabel:GetWide()) / 2), 30)
		daysLabel:SetParent(bTimePanel)
		
		local daysWang = VToolkit:CreateNumberWang(0, 7)
		daysWang:SetPos(232, 45)
		daysWang:SetParent(bTimePanel)
		daysWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 7) then
				wang:SetValue(0)
				weeksWang:SetValue(weeksWang:GetValue() + 1)
			end
		end
		
		
		
		local hoursLabel = VToolkit:CreateLabel("Hours:")
		hoursLabel:SetPos(306 + ((64 - hoursLabel:GetWide()) / 2), 30)
		hoursLabel:SetParent(bTimePanel)
		
		local hoursWang = VToolkit:CreateNumberWang(0, 24)
		hoursWang:SetPos(306, 45)
		hoursWang:SetParent(bTimePanel)
		hoursWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 24) then
				wang:SetValue(0)
				daysWang:SetValue(daysWang:GetValue() + 1)
			end
		end
		
		
		
		local minsLabel = VToolkit:CreateLabel("Minutes:")
		minsLabel:SetPos(380 + ((64 - minsLabel:GetWide()) / 2), 30)
		minsLabel:SetParent(bTimePanel)
		
		local minsWang = VToolkit:CreateNumberWang(0, 60)
		minsWang:SetPos(380, 45)
		minsWang:SetParent(bTimePanel)
		minsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 60) then
				wang:SetValue(0)
				hoursWang:SetValue(hoursWang:GetValue() + 1)
			end
		end
		
		
		
		local secondsLabel = VToolkit:CreateLabel("Seconds:")
		secondsLabel:SetPos(454 + ((64 - secondsLabel:GetWide()) / 2), 30)
		secondsLabel:SetParent(bTimePanel)
		
		local secondsWang = VToolkit:CreateNumberWang(0, 60)
		secondsWang:SetPos(454, 45)
		secondsWang:SetParent(bTimePanel)
		secondsWang.OnValueChanged = function(wang, val)
			if(tonumber(val) == 60) then
				wang:SetValue(0)
				minsWang:SetValue(minsWang:GetValue() + 1)
			end
		end
		
		
		
		local confirmButton = VToolkit:CreateButton("OK", function(self)
			local times = { yearsWang:GetValue(), monthsWang:GetValue(), weeksWang:GetValue(), daysWang:GetValue(), hoursWang:GetValue(), minsWang:GetValue(), secondsWang:GetValue() }
			bTimePanel:Close()
			VToolkit:CreateTextInput("For what reason are you banning this/these player(s)?", function(text)
				local time = (times[1] * 31557600) + (times[2] * 2592000) + (times[3] * 604800) + (times[4] * 86400) + (times[5] * 3600) + (times[6] * 60) + times[7]
				for i,k in pairs(playersToBan) do
					MODULE:NetStart("VBanPlayer")
					net.WriteEntity(k)
					net.WriteInt(time, 32)
					net.WriteString(text)
					net.SendToServer()
				end
			end)
		end)
		confirmButton:SetPos(528, 30)
		confirmButton:SetSize(100, 20)
		confirmButton:SetParent(bTimePanel)
		
		
		
		local cancelButton = VToolkit:CreateButton("Cancel", function(self)
			bTimePanel:Close()
		end)
		cancelButton:SetPos(528, 60)
		cancelButton:SetSize(100, 20)
		cancelButton:SetParent(bTimePanel)
				
		VToolkit:SetDark(true)
		
		bTimePanel:MakePopup()
		bTimePanel:DoModal()
		bTimePanel:SetAutoDelete(true)
		
	end

	Vermilion.Menu:AddCategory("player", 4)
	
	self:NetHook("VGetBanRecords", function()
		if(not Vermilion.Menu.IsOpen) then return end
		local paneldata = Vermilion.Menu.Pages["bans"]
		paneldata.UnbanPlayer:SetDisabled(true)
		
		paneldata.BanList:Clear()
		for i,k in pairs(net.ReadTable()) do
			local ln = nil
			if(k.ExpiryTime == 0) then
				ln = paneldata.BanList:AddLine(k.Name, os.date("%d/%m/%y %H:%M:%S", k.BanTime), "Never", k.BannerName, k.Reason)
			else
				ln = paneldata.BanList:AddLine(k.Name, os.date("%d/%m/%y %H:%M:%S", k.BanTime), os.date("%d/%m/%y %H:%M:%S", k.ExpiryTime), k.BannerName, k.Reason)
			end
			ln.BSteamID = k.SteamID
			ln.BBSteamID = k.BannerSteamID
			
			steamworks.RequestPlayerInfo(util.SteamIDTo64(k.SteamID))
			if(k.BannerSteamID != "VERMILION") then steamworks.RequestPlayerInfo(util.SteamIDTo64(k.BannerSteamID)) end
			timer.Simple(3, function()
				if(not IsValid(paneldata.Panel) or not IsValid(ln)) then
					return
				end
				local bannedName = steamworks.GetPlayerName(util.SteamIDTo64(k.SteamID))
				local bannerName = k.BannerName
				if(k.BannerSteamID != "VERMILION") then bannerName = steamworks.GetPlayerName(util.SteamIDTo64(k.BannerSteamID)) end
				
				if(bannedName != nil) then
					ln:SetValue(1, bannedName)
				end
				if(bannerName != nil) then
					ln:SetValue(4, bannerName)
				end
			end)
		end
	end)

	Vermilion.Menu:AddPage({
			ID = "bans",
			Name = "Ban Management",
			Order = 1,
			Category = "player",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_bans")
			end,
			Builder = function(panel, paneldata)
				local banPlayer = nil
				local kickPlayer = nil
				local unbanPlayer = nil
			
				local banList = VToolkit:CreateList({
					cols = {
						"Name",
						"Banned On",
						"Expires",
						"Banned By",
						"Reason"
					}
				})
				banList:SetPos(10, 30)
				banList:SetSize(700, panel:GetTall() - 40)
				banList:SetParent(panel)
				paneldata.BanList = banList
				
				function banList:OnRowSelected(index, line)
					local enabled = self:GetSelected()[1] == nil
					unbanPlayer:SetDisabled(enabled)
				end
				
				local banHeader = VToolkit:CreateHeaderLabel(banList, "Ban Listings")
				banHeader:SetParent(panel)
				
				VToolkit:CreateSearchBox(banList)
				
				local banUserPanel = vgui.Create("DPanel")
				banUserPanel:SetTall(panel:GetTall())
				banUserPanel:SetWide((panel:GetWide() / 2) + 55)
				banUserPanel:SetPos(panel:GetWide(), 0)
				banUserPanel:SetParent(panel)
				paneldata.BanUserPanel = banUserPanel
				local cBUPanel = VToolkit:CreateButton("Close", function()
					banUserPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				cBUPanel:SetPos(10, 10)
				cBUPanel:SetSize(50, 20)
				cBUPanel:SetParent(banUserPanel)
				
				
				local banUserList = VToolkit:CreateList({
					cols = { 
						"Name"
					}
				})
				banUserList:SetPos(10, 40)
				banUserList:SetSize(300, panel:GetTall() - 50)
				banUserList:SetParent(banUserPanel)
				paneldata.BanUserList = banUserList
				
				VToolkit:CreateSearchBox(banUserList)
				
				local banUserHeader = VToolkit:CreateHeaderLabel(banUserList, "Active Players")
				banUserHeader:SetParent(banUserPanel)
				
				local banUserButton = VToolkit:CreateButton("Ban Player(s)", function()
					if(table.Count(banUserList:GetSelected()) == 0) then
						VToolkit:CreateErrorDialog("Must select at least one player to ban.")
						return
					end
					local tab = {}
					for i,k in pairs(banUserList:GetSelected()) do
						table.insert(tab, VToolkit.LookupPlayer(k:GetValue(1)))
					end
					MODULE:CreateBanForPanel(tab)
					banUserPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				banUserButton:SetTall(30)
				banUserButton:SetPos(banUserPanel:GetWide() - 185, (banUserPanel:GetTall() - banUserButton:GetTall()) / 2)
				banUserButton:SetWide(banUserPanel:GetWide() - banUserButton:GetX() - 15)
				banUserButton:SetParent(banUserPanel)
				
				
				
				local kickUserPanel = vgui.Create("DPanel")
				kickUserPanel:SetTall(panel:GetTall())
				kickUserPanel:SetWide((panel:GetWide() / 2) + 55)
				kickUserPanel:SetPos(panel:GetWide(), 0)
				kickUserPanel:SetParent(panel)
				paneldata.KickUserPanel = kickUserPanel
				local cKUPanel = VToolkit:CreateButton("Close", function()
					kickUserPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				cKUPanel:SetPos(10, 10)
				cKUPanel:SetSize(50, 20)
				cKUPanel:SetParent(kickUserPanel)
				
				local kickUserList = VToolkit:CreateList({
					cols = { 
						"Name"
					}
				})
				kickUserList:SetPos(10, 40)
				kickUserList:SetSize(300, panel:GetTall() - 50)
				kickUserList:SetParent(kickUserPanel)
				paneldata.KickUserList = kickUserList
				
				VToolkit:CreateSearchBox(kickUserList)
				
				local kickUserHeader = VToolkit:CreateHeaderLabel(kickUserList, "Active Players")
				kickUserHeader:SetParent(kickUserPanel)
				
				local kickUserButton = VToolkit:CreateButton("Kick Player(s)", function()
					if(table.Count(kickUserList:GetSelected()) == 0) then
						VToolkit:CreateErrorDialog("Must select at least one player to kick.")
						return
					end
					VToolkit:CreateTextInput("For what reason are you kicking this/these player(s)?", function(text)
						for i,k in pairs(kickUserList:GetSelected()) do
							MODULE:NetStart("VKickPlayer")
							net.WriteEntity(VToolkit.LookupPlayer(k:GetValue(1)))
							net.WriteString(text)
							net.SendToServer()
						end
						kickUserPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
					end)
				end)
				kickUserButton:SetTall(30)
				kickUserButton:SetPos(kickUserPanel:GetWide() - 185, (kickUserPanel:GetTall() - kickUserButton:GetTall()) / 2)
				kickUserButton:SetWide(kickUserPanel:GetWide() - kickUserButton:GetX() - 15)
				kickUserButton:SetParent(kickUserPanel)
				
				
				
				banPlayer = VToolkit:CreateButton("Ban Player", function()
					banUserPanel:MoveTo((panel:GetWide() / 2) - 50, 0, 0.25, 0, -3)
				end)
				banPlayer:SetPos(panel:GetWide() - 185, 30)
				banPlayer:SetSize(panel:GetWide() - banPlayer:GetX() - 5, 30)
				banPlayer:SetParent(panel)
				
				local banImg = vgui.Create("DImage")
				banImg:SetImage("icon16/user_delete.png")
				banImg:SetSize(16, 16)
				banImg:SetParent(banPlayer)
				banImg:SetPos(10, (banPlayer:GetTall() - 16) / 2)
				
				kickPlayer = VToolkit:CreateButton("Kick Player", function()
					kickUserPanel:MoveTo((panel:GetWide() / 2) - 50, 0, 0.25, 0, -3)
				end)
				kickPlayer:SetPos(panel:GetWide() - 185, 70)
				kickPlayer:SetSize(panel:GetWide() - kickPlayer:GetX() - 5, 30)
				kickPlayer:SetParent(panel)
				
				local kickImg = vgui.Create("DImage")
				kickImg:SetImage("icon16/disconnect.png")
				kickImg:SetSize(16, 16)
				kickImg:SetParent(kickPlayer)
				kickImg:SetPos(10, (kickPlayer:GetTall() - 16) / 2)
				
				unbanPlayer = VToolkit:CreateButton("Unban Player", function()
					MODULE:NetStart("VUnbanPlayer")
					net.WriteString(banList:GetSelected()[1].BSteamID)
					net.SendToServer()
				end)
				unbanPlayer:SetPos(panel:GetWide() - 185, 110)
				unbanPlayer:SetSize(panel:GetWide() - unbanPlayer:GetX() - 5, 30)
				unbanPlayer:SetParent(panel)
				unbanPlayer:SetDisabled(true)
				paneldata.UnbanPlayer = unbanPlayer
				
				local unbanImg = vgui.Create("DImage")
				unbanImg:SetImage("icon16/accept.png")
				unbanImg:SetSize(16, 16)
				unbanImg:SetParent(unbanPlayer)
				unbanImg:SetPos(10, (unbanPlayer:GetTall() - 16) / 2)
				
				banUserPanel:MoveToFront()
				kickUserPanel:MoveToFront()
				
			end,
			Updater = function(panel, paneldata)
				MODULE:NetCommand("VGetBanRecords")
				
				paneldata.BanUserList:Clear()
				paneldata.KickUserList:Clear()
				for i,k in pairs(VToolkit.GetValidPlayers()) do
					paneldata.BanUserList:AddLine(k:GetName())
					paneldata.KickUserList:AddLine(k:GetName())
				end
				paneldata.BanUserPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				paneldata.KickUserPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
			end
		})
end

Vermilion:RegisterModule(MODULE)