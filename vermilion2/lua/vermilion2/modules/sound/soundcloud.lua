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

local MODULE = Vermilion:GetModule("sound")

if(SERVER) then
	resource.AddSingleFile("materials/vermilion/powered_by_soundcloud.png")
end

if(CLIENT) then


	surface.CreateFont("Vermilion_SC_TrackTitle", {
		font = "Roboto",
		size = 18,
		antialias = true
	})
	surface.CreateFont("Vermilion_SC_TrackSubTitle", {
		font = "Roboto",
		size = 13,
		antialias = true
	})

	local resultTextColour = Color(255, 255, 255, 255)
	local resultTime = 0
	
	
	local function buildTrackResult(name, uploader, len, genre, uploaded, trackid, data, index)
		uploader = uploader or ""
		len = len or 0
		genre = genre or ""
		uploaded = uploaded or ""
		
		if(genre == "") then genre = "No Genre" end
		
		local panel = vgui.Create("DPanel")
		function panel:Paint(w, h)
			surface.SetDrawColor(5, 5, 5, 220)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 0, 0, 255)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		
		local titleLabel = vgui.Create("DLabel")
		titleLabel:SetText(name)
		titleLabel:SetPos(10, 5)
		titleLabel:SetFont("Vermilion_SC_TrackTitle")
		titleLabel:SizeToContents()
		titleLabel:SetParent(panel)
		titleLabel:SetTextColor(resultTextColour)
		
		local authorLabel = vgui.Create("DLabel")
		authorLabel:SetText(uploader)
		authorLabel:SetPos(10, titleLabel:GetTall() + 10)
		authorLabel:SetFont("Vermilion_SC_TrackSubTitle")
		authorLabel:SizeToContents()
		authorLabel:SetParent(panel)
		authorLabel:SetTextColor(resultTextColour)
		
		local dataPanel = vgui.Create("DPanel")
		dataPanel:SetDrawBackground(false)
		dataPanel:SetSize(120, 40)
		dataPanel:Dock(RIGHT)
		dataPanel:DockPadding(0, 25, 0, 0)
		dataPanel:SetParent(panel)
		
		local lenLabel = vgui.Create("DLabel")
		local formattedTime = string.FormattedTime(len / 1000, "%02i:%02i:%02i")
		lenLabel:SetText(formattedTime)
		lenLabel:SetTextColor(resultTextColour)
		lenLabel:SizeToContents()
		lenLabel:Dock(TOP)
		lenLabel:DockMargin(0, 0, 10, 0)
		lenLabel:SetParent(dataPanel)
		
		local genreLabel = vgui.Create("DLabel")
		genreLabel:SetText(genre)
		genreLabel:SetTextColor(resultTextColour)
		genreLabel:SizeToContents()
		genreLabel:Dock(TOP)
		genreLabel:SetParent(dataPanel)
		
		local uploadedLabel = vgui.Create("DLabel")
		local uploadTable = string.Split(uploaded, " ")
		table.remove(uploadTable, 3)
		uploadedLabel:SetText(table.concat(uploadTable, " "))
		uploadedLabel:SetTextColor(resultTextColour)
		uploadedLabel:SizeToContents()
		uploadedLabel:Dock(TOP)
		uploadedLabel:DockMargin(0, 0, 10, 0)
		uploadedLabel:SetParent(dataPanel)
		
		local playButton = VToolkit:CreateButton("Play", function()
			MODULE:QueueSoundStream(SoundCloud.Tracks:GenerateStream(trackid), "BaseSound", {}, function(data)
				MODULE:PlayChannel("BaseSound")
			end)
		end)
		playButton:SetPos(10, authorLabel:GetY() + 20)
		playButton:SetSize(60, 20)
		playButton:SetImage("icon16/control_play.png")
		playButton:SetParent(panel)
		
		local broadcastButton = VToolkit:CreateButton("Broadcast", function()
			MODULE:NetStart("VPlayStream")
			net.WriteString(SoundCloud.Tracks:GenerateStream(trackid))
			net.WriteString("BaseSound")
			net.WriteTable({})
			net.SendToServer()
		end)
		broadcastButton:SetSize(100, 20)
		broadcastButton:SetImage("icon16/transmit.png")
		broadcastButton:SetParent(panel)
		broadcastButton:MoveRightOf(playButton, 10)
		broadcastButton:SetPos(broadcastButton:GetX(), playButton:GetY())
		
		
		local openInSoundCloudBtn = VToolkit:CreateButton("Open In SoundCloud", function()
			gui.OpenURL(data.permalink_url)
		end)
		openInSoundCloudBtn:SetSize(150, 20)
		openInSoundCloudBtn:SetImage("icon16/transmit.png")
		openInSoundCloudBtn:SetParent(panel)
		openInSoundCloudBtn:MoveRightOf(broadcastButton, 10)
		openInSoundCloudBtn:SetPos(openInSoundCloudBtn:GetX(), playButton:GetY())
		
		local moreBtn = VToolkit:CreateButton("More", function()
			local scmenu = DermaMenu(panel)
			if(data.purchase_url != nil) then // <-- as far as I remember, I have to put this here to comply with the whole "link back to the artist" agreement.
				scmenu:AddOption("Buy", function() gui.OpenURL(data.purchase_url) end):SetIcon("icon16/cart.png")
				scmenu:AddSpacer()
			end
			if(data.bpm != nil) then scmenu:AddOption("BPM: " .. tostring(data.bpm)):SetIcon("icon16/time.png") else scmenu:AddOption("BPM: Unknown"):SetIcon("icon16/time.png") end
			if(data.key_signature != nil and data.key_signature != "") then scmenu:AddOption("Key Signature: " .. data.key_signature):SetIcon("icon16/music.png") else scmenu:AddOption("Key Signature: Unknown"):SetIcon("icon16/music.png") end
			if(data.track_type != nil and data.track_type != "") then scmenu:AddOption("Track Type: " .. data.track_type):SetIcon("icon16/tag_blue.png") else scmenu:AddOption("Track Type: Unknown"):SetIcon("icon16/tag_blue.png") end
			scmenu:AddSpacer()
			if(data.license != nil) then scmenu:AddOption("License: " .. data.license):SetIcon("icon16/report.png") else scmenu:AddOption("License: Unknown"):SetIcon("icon16/report.png") end
			scmenu:AddSpacer()
			if(data.playback_count != nil) then scmenu:AddOption("Plays: " .. tostring(data.playback_count)):SetIcon("icon16/control_play.png") else scmenu:AddOption("Plays: Unknown"):SetIcon("icon16/control_play.png") end
			if(data.download_count != nil) then scmenu:AddOption("Downloads: " .. tostring(data.download_count)):SetIcon("icon16/disk.png") else scmenu:AddOption("Downloads: Unknown"):SetIcon("icon16/disk.png") end
			if(data.favoritings_count != nil) then scmenu:AddOption("Favourites: " .. tostring(data.favoritings_count)):SetIcon("icon16/star.png") else scmenu:AddOption("Favourites: Unknown"):SetIcon("icon16/star.png") end
			scmenu:AddSpacer()
			if(data.original_format != nil) then scmenu:AddOption("Format: " .. data.original_format):SetIcon("icon16/application_xp_terminal.png") else scmenu:AddOption("Format: Unknown"):SetIcon("icon16/application_xp_terminal.png") end
			
			scmenu:Open()
		end)
		moreBtn:SetSize(40, 20)
		moreBtn:SetParent(panel)
		moreBtn:MoveRightOf(openInSoundCloudBtn, 10)
		moreBtn:SetPos(moreBtn:GetX(), playButton:GetY())
		
		panel:SetTall(80)
		
		panel:DockMargin(0, 0, 0, 5)
		panel:Dock(TOP)
		
		return panel
	end
	
	concommand.Add("vermilion_soundcloud_browser", function()
		MODULE:BuildSoundCloudSearch()
	end)
	
	local tipLabel = nil
	local searchingLabel = nil
	
	MODULE:AddHook("Think", function()
		if(IsValid(tipLabel)) then
			tipLabel:SetTextColor(Color(255, 255, 255, 255 * math.Clamp(math.sin(CurTime() * 4), 0.5, 1)))
		end
		if(IsValid(searchingLabel)) then
			searchingLabel:SetTextColor(Color(255, 255, 255, 255 * math.Clamp(math.sin(CurTime() * 4), 0.5, 1)))
		end
	end)
	
	function MODULE:BuildSoundCloudSearch()
		local panel = VToolkit:CreateFrame({
			size = { 600, 600 },
			pos = { (ScrW() - 600) / 2, (ScrH() - 600) / 2 },
			title = ""
		})
		panel.btnClose:SetVisible(false)
		panel.btnMaxim:SetVisible(false)
		panel.btnMinim:SetVisible(false)
		panel:DockPadding(5, 5, 5, 5)
		
		local searchbox = VToolkit:CreateTextbox()
		searchbox:SetPos(0, 0)
		searchbox:SetSize(600, 50)
		searchbox:SetParent(panel)
		searchbox:SetFont("DermaLarge")
		searchbox:SetUpdateOnType(true)
		searchbox:SetPlaceholderText("Search SoundCloud...")
		searchbox:Dock(TOP)
		searchbox:DockMargin(0, 0, 0, 5)
		
		local resultBox = vgui.Create("DScrollPanel")
		resultBox:SetPos(0, 50)
		resultBox:SetSize(600, 500)
		resultBox:SetParent(panel)
		resultBox:Dock(FILL)
		
		
		timer.Simple(0.08, function()
			resultBox.pnlCanvas:SetTall(resultBox:GetTall())
			resultBox.pnlCanvas:SetPos(0, 0)
			resultBox.VBar:SetUp(resultBox:GetTall(), resultBox.pnlCanvas:GetTall())
			tipLabel = vgui.Create("DLabel")
			tipLabel:SetFont("DermaLarge")
			tipLabel:SetText("Tip: use \"@user:\" to search for users.")
			tipLabel:SizeToContents()
			tipLabel:SetParent(resultBox)
			tipLabel:Center()
		end)
		
		local valid = false
		
		searchbox.OnChange = function()
			resultBox:Clear()
			for i,k in pairs(resultBox.pnlCanvas:GetChildren()) do
				k:SetParent(nil)
			end
			for i,k in pairs(resultBox:GetChildren()) do
				if(k != resultBox.pnlCanvas and k != resultBox.VBar) then k:SetParent(nil) end
			end
			resultBox.pnlCanvas:SetTall(resultBox:GetTall())
			resultBox.pnlCanvas:SetPos(0, 0)
			resultBox.VBar:SetUp(resultBox:GetTall(), resultBox.pnlCanvas:GetTall())
			
			local val = searchbox:GetValue()
			if(val == nil or val == "") then
				timer.Destroy("Vermilion_SC_Update")
				valid = false
				tipLabel = vgui.Create("DLabel")
				tipLabel:SetFont("DermaLarge")
				tipLabel:SetText("Tip: use \"@user:\" to search for users.")
				tipLabel:SizeToContents()
				tipLabel:SetParent(resultBox)
				tipLabel:Center()
				return
			end
			valid = true
			if(val != searchbox.OldVal) then
				searchbox.OldVal = val
				timer.Create("Vermilion_SC_Update", 0.3, 1, function()
					searchingLabel = vgui.Create("DLabel")
					searchingLabel:SetFont("DermaLarge")
					searchingLabel:SetText("Searching...")
					searchingLabel:SizeToContents()
					searchingLabel:SetParent(resultBox)
					searchingLabel:Center()
					if(string.StartWith(val, "@user:")) then
						SoundCloud.Users:GetTracks(string.Replace(val, "@user:", ""), function(data)
							if(not IsValid(searchbox)) then return end
							if(not IsValid(resultBox)) then return end
							if(valid and val == searchbox:GetValue()) then
								if(IsValid(searchingLabel)) then
									searchingLabel:Remove()
								end
								for i,k in pairs(data) do
									local dataPanel = buildTrackResult(k.title, k.user.username, k.duration, k.genre, k.created_at, k.id, k, i)
									if(not IsValid(dataPanel)) then continue end
									dataPanel:SetWide(resultBox:GetWide())
									dataPanel:SetParent(resultBox)
								end
								resultTime = 0
								resultBox:PerformLayout()
							end
						end, function(err)
							if(not IsValid(searchbox)) then return end
							if(not IsValid(resultBox)) then return end
							if(valid and val == searchbox:GetValue()) then
								if(IsValid(searchingLabel)) then
									searchingLabel:SetText("Nothing Found!")
									searchingLabel:SizeToContents()
									resultBox.pnlCanvas:SetTall(resultBox:GetTall())
									resultBox.pnlCanvas:SetPos(0, 0)
									resultBox.VBar:SetUp(resultBox:GetTall(), resultBox.pnlCanvas:GetTall())
									searchingLabel:Center()
								end
							end
						end)
						return
					end
					SoundCloud.Tracks:Search(val, function(data)
						if(not IsValid(searchbox)) then return end
						if(not IsValid(resultBox)) then return end
						if(valid and val == searchbox:GetValue()) then
							if(IsValid(searchingLabel)) then
								searchingLabel:Remove()
							end
							for i,k in pairs(data) do
								local dataPanel = buildTrackResult(k.title, k.user.username, k.duration, k.genre, k.created_at, k.id, k)
								if(not IsValid(dataPanel)) then continue end
								dataPanel:SetWide(resultBox:GetWide())
								dataPanel:SetParent(resultBox)
							end
							resultTime = 0
							resultBox:PerformLayout()
						end
					end, function(err)
						if(not IsValid(searchbox)) then return end
						if(not IsValid(resultBox)) then return end
						if(valid and val == searchbox:GetValue()) then
							if(IsValid(searchingLabel)) then
								searchingLabel:SetText("Nothing Found!")
								searchingLabel:SizeToContents()
								resultBox.pnlCanvas:SetTall(resultBox:GetTall())
								resultBox.pnlCanvas:SetPos(0, 0)
								resultBox.VBar:SetUp(resultBox:GetTall(), resultBox.pnlCanvas:GetTall())
								searchingLabel:Center()
							end
						end
					end)
				end)
			end
		end
		
		local btnBar = vgui.Create("DPanel")
		btnBar:SetDrawBackground(false)
		btnBar:SetTall(32)
		btnBar:Dock(BOTTOM)
		btnBar:DockMargin(0, 5, 0, 0)
		btnBar:SetParent(panel)
		
		local cbtn = VToolkit:CreateButton("Close", function()
			panel:Close()
		end)
		cbtn:SetParent(btnBar)
		cbtn:SetTall(20)
		cbtn:Dock(LEFT)
		
		local playlistButton = VToolkit:CreateButton("Playlists...", function()
			
		end)
		playlistButton:SetParent(btnBar)
		playlistButton:Dock(RIGHT)
		playlistButton:SetTall(20)
		
		
		local sc_logo = vgui.Create("DImage")
		sc_logo:SetImage("vermilion/powered_by_soundcloud.png")
		sc_logo:SetSize(104, 32)
		sc_logo:SetPos((600 - 104) / 2, 0)
		sc_logo:SetParent(btnBar)
		
		
		panel:MakePopup()
		--panel:DoModal()
		panel:SetAutoDelete(true)
		
		searchbox:RequestFocus()
	end
	
end