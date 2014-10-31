
-- permissions
"add_voip_channel",
"join_voip_channel",
"delete_voip_channel",

MODULE.DefaultVoIPChannels = {
	{ Name = "Default", Password = nil, Founder = nil }
}


function MODULE:AddVoIPChannel(name, password, founder)
	if(name == nil or name == "") then return false end
	for i,k in pairs(self:GetData("voip_channels", self.DefaultVoIPChannels, true)) do
		if(k.Name == name) then return false end
	end
	local tPassword = nil
	if(password != nil) then
		tPassword = util.CRC(password)
	end
	table.insert(self:GetData("voip_channels", self.DefaultVoIPChannels, true), { Name = name, Password = tPassword, Founder = founder:SteamID() })
	return true
end

function MODULE:JoinChannel(vplayer, chan, pass)
	local chanObj = nil
	for i,k in pairs(self:GetData("voip_channels", self.DefaultVoIPChannels, true)) do
		if(k.Name == chan) then
			chanObj = k
			break
		end
	end
	if(chanObj != nil) then
		if(chanObj.Password != nil) then
			if(pass == nil) then return "BAD_PASSWORD" end
			if(chanObj.Password != util.CRC(pass)) then
				return "BAD_PASSWORD"
			end
		end
		Vermilion:GetUser(vplayer).VoIPChannel = chan
		return "GOOD"
	end
	return "NO_SUCH_CHAN"
end



-- commands
Vermilion:AddChatCommand({
		Name = "addchan",
		Description = "Adds a VoIP channel.",
		Syntax = "<name> [password]",
		CanMute = true,
		Predictor = function(pos, current, all)
			
		end,
		Function = function(sender, text, log, glog)
			if(Vermilion:HasPermission(sender, "add_voip_channel")) then
				if(not MODULE:AddVoIPChannel(text[1], text[2], sender)) then
					log("VoIP Channel already exists!", NOTIFY_ERROR)
				else
					glog("VoIP channel '" .. text[1] .. "' was created successfully by " .. sender:GetName())
				end
			end
		end
	})
	
	Vermilion:AddChatCommand({
		Name = "delchan",
		Description = "Deletes a VoIP channel.",
		Syntax = "<chan>",
		Predictor = function(pos, current, all)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
					if(string.find(string.lower(k.Name), string.lower(current))) then
						table.insert(tab, k.Name)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log)
			if(Vermilion:HasPermission(sender, "delete_voip_channel")) then
				local has = false
				for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
					if(k.Name == text[1]) then has = k break end
				end
				if(text[1] == "Default") then has = false end
				if(not has) then
					log("No such VoIP Channel!", NOTIFY_ERROR)
					return
				end
				if(has.Founder != sender:SteamID()) then
					log("You are not the founder of this channel thus you cannot delete it.", NOTIFY_ERROR)
					return
				end
				table.RemoveByValue(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true), has)
				for i,k in pairs(Vermilion.Data.Users) do
					if(k.VoIPChannel == text[1]) then
						k.VoIPChannel = "Default"
					end
				end
				log("Removed VoIP Channel!")
			end
		end
	})
	
	Vermilion:AddChatCommand({
		
	})
	
	Vermilion:AddChatCommand("changechanpass", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "add_voip_channel")) then
			local has = false
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == text[1]) then has = k break end
			end
			if(has.Name == "Default") then
				
			end
		end
	end, "<chan> [oldpass] <newpass>")
	
	Vermilion:AddChatCommand("joinchan", function(sender, text, log)
		if(Vermilion:HasPermission(sender, "join_voip_channel")) then
			local result = MODULE:JoinChannel(sender, text[1], text[2])
			if(result == "BAD_PASSWORD") then
				log("Bad VoIP Channel password!", NOTIFY_ERROR)
			elseif(result == "NO_SUCH_CHAN") then
				log("No such VoIP Channel!", NOTIFY_ERROR)
			else
				log("Joined VoIP Channel!")
			end
		end
	end, "<channel> [password]", function(pos, current, all)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(string.find(string.lower(k.Name), string.lower(current))) then
					table.insert(tab, k.Name)
				end
			end
			return tab
		end
		if(pos == 2) then
			local chan = nil
			for i,k in pairs(MODULE:GetData("voip_channels", MODULE.DefaultVoIPChannels, true)) do
				if(k.Name == all[1]) then
					chan = k
					break
				end
			end
			if(chan != nil) then
				if(chan.Password == nil) then
					return {{ Name = "", Syntax = "No password required!" }}
				else
					return {{ Name = "", Syntax = "Password Required!" }}
				end
			end
		end
	end)
	
-- calculator
function MODULE:CalcVoIPChannels(listener, talker, default)
		if(IsValid(listener) and IsValid(talker)) then
			local vListener = Vermilion:GetUser(listener)
			local vTalker = Vermilion:GetUser(talker)
			if(vListener.VoIPChannel == nil) then
				vListener.VoIPChannel = "Default"
			end
			if(vTalker.VoIPChannel == nil) then
				vTalker.VoIPChannel = "Default"
			end
			return vListener.VoIPChannel == vTalker.VoIPChannel
		end
		return default
	end