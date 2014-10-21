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
MODULE.Name = "Rank Editor"
MODULE.ID = "rank_editor"
MODULE.Description = "Edits ranks"
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_ranks"
}
MODULE.NetworkStrings = {
	"VGetPermissions",
	"VGivePermission",
	"VRevokePermission",
	
	"VAddRank",
	"VRemoveRank",
	"VRenameRank",
	"VMoveRank",
	"VSetRankDefault",
	"VChangeRankColour",
	"VChangeRankIcon",
	"VAssignRank"
}

function MODULE:InitServer()
	
	self:NetHook("VGetPermissions", function(vplayer)
		local rank = net.ReadString()
		local rankData = Vermilion:GetRank(rank)
		if(rankData != nil) then
			MODULE:NetStart("VGetPermissions")
			net.WriteString(rank)
			net.WriteTable(rankData.Permissions)
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VGivePermission", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rank = net.ReadString()
			local permission = net.ReadString()
			
			Vermilion:GetRank(rank):AddPermission(permission)
		end
	end)
	
	self:NetHook("VRevokePermission", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rank = net.ReadString()
			local permission = net.ReadString()
			
			Vermilion:GetRank(rank):RevokePermission(permission)
		end
	end)
	
	self:NetHook("VAddRank", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local newRank = net.ReadString()
			Vermilion:AddRank(newRank, nil, false, Color(0, 0, 0), "user_suit")
		end
	end)
	
	self:NetHook("VChangeRankColour", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rankName = net.ReadString()
			local colour = net.ReadColor()
			
			Vermilion:GetRank(rankName):SetColour(colour)
		end
	end)
	
	self:NetHook("VMoveRank", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rnk = net.ReadString()
			local dir = net.ReadBoolean()
			
			if(dir) then
				Vermilion:GetRank(rnk):MoveUp()
			else
				Vermilion:GetRank(rnk):MoveDown()
			end
		end
	end)
	
	self:NetHook("VRemoveRank", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rnk = net.ReadString()
			
			Vermilion:GetRank(rnk):Delete()
		end
	end)
	
	self:NetHook("VRenameRank", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rnk = net.ReadString()
			local new = net.ReadString()
			
			Vermilion:GetRank(rnk):Rename(new)
		end
	end)
	
	self:NetHook("VSetRankDefault", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local new = net.ReadString()
			
			Vermilion:SetData("default_rank", new)
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
		end
	end)
	
	self:NetHook("VChangeRankIcon", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local rankName = net.ReadString()
			local icon = net.ReadString()
			
			Vermilion:GetRank(rankName):SetIcon(icon)
		end
	end)
	
	self:NetHook("VAssignRank", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_ranks")) then
			local ply = net.ReadEntity()
			local newRank = net.ReadString()
			
			if(IsValid(ply)) then
				Vermilion:GetUser(ply):SetRank(newRank)
			end
		end
	end)
	
end

function MODULE:InitClient()
	self:NetHook("VGetPermissions", function()
		local rank = net.ReadString()
		if(not IsValid(MODULE.PermissionEditorPanel)) then return end
		if(rank == MODULE.PermissionEditorPanel.RankList:GetSelected()[1]:GetValue(1)) then
			local permissions = net.ReadTable()
			local rnkPList = MODULE.PermissionEditorPanel.RankPermissions
			rnkPList:Clear()
			for i,k in pairs(permissions) do
				rnkPList:AddLine(k, Vermilion:LookupPermissionOwner(k))
			end
		end
	end)
	
	self:AddHook(Vermilion.Event.CLIENT_GOT_RANK_OVERVIEWS, function()
		local rank_overview_list = Vermilion.Menu.Pages["rank_editor"].Panel.RankList
		if(IsValid(rank_overview_list)) then
			Vermilion:PopulateRankTable(rank_overview_list, true, true)
		end
		rank_overview_list:OnRowSelected()
		local permission_editor_list = Vermilion.Menu.Pages["permission_editor"].Panel.RankList
		if(IsValid(permission_editor_list)) then
			Vermilion:PopulateRankTable(permission_editor_list)
		end
	end)
	
	self:AddHook("PlayerInitialSpawn", function(name, steamid, rank, entindex)
		local player_list = Vermilion.Menu.Pages["rank_assignment"].Panel.PlayerList
		if(IsValid(player_list)) then
			player_list:AddLine(name, rank).EntityID = entindex
		end
	end)


	Vermilion.Menu:AddCategory("ranks", 3)

	Vermilion.Menu:AddPage({
			ID = "rank_editor",
			Name = "Rank Editor",
			Order = 0,
			Category = "ranks",
			Size = { 600, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_ranks")
			end,
			Builder = function(panel)
				local rankList = nil
				
				local addRank = VToolkit:CreateButton("Add", function()
					VToolkit:CreateTextInput("Enter the name for the new rank:", function(text)
						local has = false
						for i,k in pairs(rankList:GetLines()) do
							if(k:GetValue(1) == text) then
								has = true
								break
							end
						end
						if(has) then
							VToolkit:CreateErrorDialog("This rank already exists!")
							return
						end
						MODULE:NetStart("VAddRank")
						net.WriteString(text)
						net.SendToServer()
						VToolkit:CreateDialog("Success", "Rank created!")
					end)
				end)
				addRank:SetPos(320, 30)
				addRank:SetSize(panel:GetWide() - 330, 30)
				addRank:SetParent(panel)
				
				local addImg = vgui.Create("DImage")
				addImg:SetImage("icon16/add.png")
				addImg:SetSize(16, 16)
				addImg:SetParent(addRank)
				addImg:SetPos(10, (addRank:GetTall() - 16) / 2)
				
				local delRank = VToolkit:CreateButton("Delete", function()
					local rnk = rankList:GetSelected()[1]
					if(not rnk.Protected) then
						VToolkit:CreateConfirmDialog("Really delete the rank \"" .. rnk:GetValue(1) .. "\"?", function()
							MODULE:NetStart("VRemoveRank")
							net.WriteString(rnk:GetValue(1))
							net.SendToServer()
							VToolkit:CreateDialog("Success", "Rank deleted!")
						end)
					else
						VToolkit:CreateErrorDialog("This is a protected rank!")
					end
				end)
				delRank:SetPos(320, 70)
				delRank:SetSize(panel:GetWide() - 330, 30)
				delRank:SetParent(panel)
				delRank:SetDisabled(true)
				
				local remImg = vgui.Create("DImage")
				remImg:SetImage("icon16/delete.png")
				remImg:SetSize(16, 16)
				remImg:SetParent(delRank)
				remImg:SetPos(10, (delRank:GetTall() - 16) / 2)
				
				local renameRank = VToolkit:CreateButton("Rename", function()
					local rnk = rankList:GetSelected()[1]
					if(not rnk.Protected) then
						VToolkit:CreateTextInput("Enter the new name for the \"" .. rnk:GetValue(1) .. "\" rank:", function(text)
							local has = false
							for i,k in pairs(rankList:GetLines()) do
								if(k:GetValue(1) == text) then
									has = true
									break
								end
							end
							if(not has) then
								MODULE:NetStart("VRenameRank")
								net.WriteString(rnk:GetValue(1))
								net.WriteString(text)
								net.SendToServer()
								VToolkit:CreateDialog("Success", "Rank renamed!")
							else
								VToolkit:CreateErrorDialog("This rank already exists!")
							end
						end)
					else
						VToolkit:CreateErrorDialog("This is a protected rank!")
					end
				end)
				renameRank:SetPos(320, 110)
				renameRank:SetSize(panel:GetWide() - 330, 30)
				renameRank:SetParent(panel)
				renameRank:SetDisabled(true)
				
				local renImg = vgui.Create("DImage")
				renImg:SetImage("icon16/textfield_rename.png")
				renImg:SetSize(16, 16)
				renImg:SetParent(renameRank)
				renImg:SetPos(10, (renameRank:GetTall() - 16) / 2)
				
				local moveUp = VToolkit:CreateButton("Move Up", function()
					local rnk = rankList:GetSelected()[1]
					if(not rnk.Protected) then
						if(rnk:GetID() == 2) then
							VToolkit:CreateErrorDialog("This rank cannot be moved up.")
						else
							MODULE:NetStart("VMoveRank")
							net.WriteString(rnk:GetValue(1))
							net.WriteBoolean(true) -- Up
							net.SendToServer()
						end
					else
						VToolkit:CreateErrorDialog("This is a protected rank!")
					end
				end)
				moveUp:SetPos(320, 150)
				moveUp:SetSize(panel:GetWide() - 330, 30)
				moveUp:SetParent(panel)
				moveUp:SetDisabled(true)
				
				local upImg = vgui.Create("DImage")
				upImg:SetImage("icon16/arrow_up.png")
				upImg:SetSize(16, 16)
				upImg:SetParent(moveUp)
				upImg:SetPos(10, (moveUp:GetTall() - 16) / 2)
				
				local moveDown = VToolkit:CreateButton("Move Down", function()
					local rnk = rankList:GetSelected()[1]
					if(not rnk.Protected) then
						if(rnk:GetID() == table.Count(rankList:GetLines())) then
							VToolkit:CreateErrorDialog("This rank cannot be moved down.")
						else
							MODULE:NetStart("VMoveRank")
							net.WriteString(rnk:GetValue(1))
							net.WriteBoolean(false) -- Down
							net.SendToServer()
						end
					else
						VToolkit:CreateErrorDialog("This is a protected rank!")
					end
				end)
				moveDown:SetPos(320, 190)
				moveDown:SetSize(panel:GetWide() - 330, 30)
				moveDown:SetParent(panel)
				moveDown:SetDisabled(true)
				
				local downImg = vgui.Create("DImage")
				downImg:SetImage("icon16/arrow_down.png")
				downImg:SetSize(16, 16)
				downImg:SetParent(moveDown)
				downImg:SetPos(10, (moveDown:GetTall() - 16) / 2)
				
				local setDefault = VToolkit:CreateButton("Set As Default", function()
					local rnk = rankList:GetSelected()[1]
					local cont = function()
						MODULE:NetStart("VSetRankDefault")
						net.WriteString(rnk:GetValue(1))
						net.SendToServer()
						VToolkit:CreateDialog("Success", "Rank set as default!")
					end
					if(rnk.Protected) then
						VToolkit:CreateConfirmDialog("Are you sure you want to set a protected rank as the default rank?", cont)
					else
						cont()
					end
				end)
				setDefault:SetPos(320, 230)
				setDefault:SetSize(panel:GetWide() - 330, 30)
				setDefault:SetParent(panel)
				setDefault:SetDisabled(true)
				
				local defImg = vgui.Create("DImage")
				defImg:SetImage("icon16/accept.png")
				defImg:SetSize(16, 16)
				defImg:SetParent(setDefault)
				defImg:SetPos(10, (setDefault:GetTall() - 16) / 2)
				
				local setColour = VToolkit:CreateButton("Set Colour", function()
					local frame = VToolkit:CreateFrame({
						size = { 400, 270 },
						pos = { (ScrW() - 400) / 2, (ScrH() - 270) / 2 },
						closeBtn = false,
						draggable = true,
						title = "Set Rank Colour - " .. rankList:GetSelected()[1]:GetValue(1)
					})
					frame:DoModal()
					frame:MakePopup()
					frame:SetAutoDelete(true)
					
					local rankName = rankList:GetSelected()[1]:GetValue(1)
					
					local mixer = VToolkit:CreateColourMixer(true, false, true, Vermilion:GetRankColour(rankName), function(colour)
						
					end)
					mixer:SetPos(10, 30)
					mixer:SetParent(frame)
					
					local ok = VToolkit:CreateButton("Save", function()
						MODULE:NetStart("VChangeRankColour")
						net.WriteString(rankName)
						net.WriteColor(mixer:GetColor())
						net.SendToServer()
						frame:Remove()
					end)
					ok:SetPos(300, 30)
					ok:SetSize(80, 20)
					ok:SetParent(frame)
					
					
					local cancel = VToolkit:CreateButton("Cancel", function()
						frame:Remove()
					end)
					cancel:SetPos(300, 60)
					cancel:SetSize(80, 20)
					cancel:SetParent(frame)
				end)
				setColour:SetPos(320, 270)
				setColour:SetSize(panel:GetWide() - 330, 30)
				setColour:SetParent(panel)
				setColour:SetDisabled(true)
				
				local colourImg = vgui.Create("DImage")
				colourImg:SetImage("icon16/color_wheel.png")
				colourImg:SetSize(16, 16)
				colourImg:SetParent(setColour)
				colourImg:SetPos(10, (setColour:GetTall() - 16) / 2)
				
				local setIcon = VToolkit:CreateButton("Set Icon", function()
					local frame = VToolkit:CreateFrame({
						size = { 400, 270 },
						pos = { (ScrW() - 400) / 2, (ScrH() - 270) / 2 },
						closeBtn = false,
						draggable = true,
						title = "Set Rank Icon - " .. rankList:GetSelected()[1]:GetValue(1)
					})
					frame:DoModal()
					frame:MakePopup()
					frame:SetAutoDelete(true)
					
					local rankName = rankList:GetSelected()[1]:GetValue(1)
					
					local icnBrowser = vgui.Create("DIconBrowser")
					icnBrowser:SetPos(10, 30)
					icnBrowser:SetSize(280, 230)
					icnBrowser:SetParent(frame)
					icnBrowser:SelectIcon(Vermilion:GetRankIcon(rankName))
					
					local ok = VToolkit:CreateButton("Save", function()
						MODULE:NetStart("VChangeRankIcon")
						net.WriteString(rankName)
						local icn = icnBrowser.m_strSelectedIcon
						icn = string.Replace(icn, "icon16/", "")
						icn = string.Replace(icn, ".png", "")
						net.WriteString(icn)
						net.SendToServer()
						frame:Remove()
					end)
					ok:SetPos(300, 30)
					ok:SetSize(80, 20)
					ok:SetParent(frame)
					
					
					local cancel = VToolkit:CreateButton("Cancel", function()
						frame:Remove()
					end)
					cancel:SetPos(300, 60)
					cancel:SetSize(80, 20)
					cancel:SetParent(frame)
				end)
				setIcon:SetPos(320, 310)
				setIcon:SetSize(panel:GetWide() - 330, 30)
				setIcon:SetParent(panel)
				setIcon:SetDisabled(true)
				
				local icnImg = vgui.Create("DImage")
				icnImg:SetImage("icon16/picture.png")
				icnImg:SetSize(16, 16)
				icnImg:SetParent(setIcon)
				icnImg:SetPos(10, (setIcon:GetTall() - 16) / 2)
				
				
				rankList = VToolkit:CreateList({ "Name", "Immunity", "Default" }, false, false)
				rankList:SetPos(10, 30)
				rankList:SetSize(300, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				rankList.Columns[2]:SetFixedWidth(59)
				rankList.Columns[3]:SetFixedWidth(52)
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					local enabled = self:GetSelected()[1] == nil
					delRank:SetDisabled(enabled)
					renameRank:SetDisabled(enabled)
					moveUp:SetDisabled(enabled)
					moveDown:SetDisabled(enabled)
					setDefault:SetDisabled(enabled)
					setColour:SetDisabled(enabled)
					setIcon:SetDisabled(enabled)
				end
				
			end,
			Updater = function(panel)
				Vermilion:PopulateRankTable(panel.RankList, true, true)
			end
		})
	
	Vermilion.Menu:AddPage({
			ID = "permission_editor",
			Name = "Permission Editor",
			Order = 1,
			Category = "ranks",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_ranks")
			end,
			Builder = function(panel)
				
				MODULE.PermissionEditorPanel = panel
				
				local allPermissions = nil
				local rankPermissions = nil
				local givePermission = nil
				local takePermission = nil
				local rankList = nil
				
				
				givePermission = VToolkit:CreateButton("Give Permission", function()
					for i,k in pairs(allPermissions:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankPermissions:GetLines()) do
							if(k1:GetValue(1) == k:GetValue(1)) then
								has = true
								break
							end
						end
						if(not has) then
							rankPermissions:AddLine(k:GetValue(1), k:GetValue(2))
						end
						MODULE:NetStart("VGivePermission")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k:GetValue(1))
						net.SendToServer()
					end
				end)
				givePermission:SetPos(480, 120)
				givePermission:SetSize(150, 20)
				givePermission:SetParent(panel)
				givePermission:SetEnabled(false)
				panel.GivePermission = givePermission
				
				takePermission = VToolkit:CreateButton("Revoke Permission", function()
					for i,k in pairs(rankPermissions:GetSelected()) do
						MODULE:NetStart("VRevokePermission")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k:GetValue(1))
						net.SendToServer()
						rankPermissions:RemoveLine(k:GetID())
					end
				end)
				takePermission:SetPos(480, 150)
				takePermission:SetSize(150, 20)
				takePermission:SetParent(panel)
				takePermission:SetEnabled(false)
				panel.TakePermission = takePermission
				
				
				
				rankList = VToolkit:CreateList({ "Name" }, false, false)
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					givePermission:SetEnabled(self:GetSelected()[1] != nil and allPermissions:GetSelected()[1] != nil)
					takePermission:SetEnabled(self:GetSelected()[1] != nil and rankPermissions:GetSelected()[1] != nil)
					MODULE:NetStart("VGetPermissions")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				
				rankPermissions = VToolkit:CreateList({ "Name", "Module" })
				rankPermissions:SetPos(220, 30)
				rankPermissions:SetSize(240, panel:GetTall() - 40)
				rankPermissions:SetParent(panel)
				panel.RankPermissions = rankPermissions
				
				local rankPermissionsHeader = VToolkit:CreateHeaderLabel(rankPermissions, "Rank Permissions")
				rankPermissionsHeader:SetParent(panel)
				
				function rankPermissions:OnRowSelected(index, line)
					takePermission:SetEnabled(self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil)
				end
				
				VToolkit:CreateSearchBox(rankPermissions)
				
				
				
				
				allPermissions = VToolkit:CreateList({"Name", "Module"})
				allPermissions:SetPos(panel:GetWide() - 250, 30)
				allPermissions:SetSize(240, panel:GetTall() - 40)
				allPermissions:SetParent(panel)
				panel.AllPermissions = allPermissions
				
				local allPermissionsHeader = VToolkit:CreateHeaderLabel(allPermissions, "All Permissions")
				allPermissionsHeader:SetParent(panel)
				
				function allPermissions:OnRowSelected(index, line)
					givePermission:SetEnabled(self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil)
				end
				
				VToolkit:CreateSearchBox(allPermissions)
				
			end,
			Updater = function(panel)
				Vermilion:PopulateRankTable(panel.RankList)
				panel.AllPermissions:Clear()
				for i,k in pairs(Vermilion.Data.Permissions) do
					panel.AllPermissions:AddLine(k.Permission, Vermilion:GetModule(k.Owner).Name)
				end
			end,
			Destroyer = function(panel)
				panel.GivePermission:SetEnabled(false)
				panel.TakePermission:SetEnabled(false)
				panel.RankPermissions:Clear()
				panel.RankList:Clear()
			end
		})
	
	Vermilion.Menu:AddPage({
			ID = "rank_assignment",
			Name = "Rank Assignment",
			Order = 2,
			Category = "ranks",
			Size = { 600, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_ranks")
			end,
			Builder = function(panel)
				local assignRank = nil
				local rankList = nil
				local playerList = VToolkit:CreateList({ "Name", "Rank" }, false, false)
				playerList:SetPos(10, 30)
				playerList:SetSize(200, panel:GetTall() - 40)
				playerList:SetParent(panel)
				panel.PlayerList = playerList
				
				local playerHeader = VToolkit:CreateHeaderLabel(playerList, "Active Players")
				playerHeader:SetParent(panel)
				
				function playerList:OnRowSelected(index, line)
					assignRank:SetDisabled(self:GetSelected()[1] == nil and rankList:GetSelected()[1] == nil)
				end
				
				VToolkit:CreateSearchBox(playerList)
				
				
				rankList = VToolkit:CreateList({ "Name" }, false, false)
				rankList:SetPos(220, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					assignRank:SetDisabled(self:GetSelected()[1] == nil and playerList:GetSelected()[1] == nil)
				end
				
				assignRank = VToolkit:CreateButton("Assign Rank", function()
					if(Vermilion.Data.Rank.Protected and Entity(playerList:GetSelected()[1].EntityID) == LocalPlayer()) then
						VToolkit:CreateConfirmDialog("Really modify your rank?", function()							
							MODULE:NetStart("VAssignRank")
							net.WriteEntity(Entity(playerList:GetSelected()[1].EntityID))
							net.WriteString(rankList:GetSelected()[1]:GetValue(1))
							net.SendToServer()
							playerList:GetSelected()[1]:SetValue(2, rankList:GetSelected()[1]:GetValue(1))
						end)
					else
						MODULE:NetStart("VAssignRank")
						net.WriteEntity(Entity(playerList:GetSelected()[1].EntityID))
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.SendToServer()
						playerList:GetSelected()[1]:SetValue(2, rankList:GetSelected()[1]:GetValue(1))
					end
				end)
				assignRank:SetPos(440, (panel:GetTall() - 20) / 2)
				assignRank:SetSize(panel:GetWide() - 460, 20)
				assignRank:SetParent(panel)
				assignRank:SetDisabled(true)
				
				panel.PlayerList = playerList
				
			end,
			Updater = function(panel)
				Vermilion:PopulateRankTable(panel.RankList, false, true)
				panel.PlayerList:Clear()
				for i,k in pairs(VToolkit.GetValidPlayers()) do
					panel.PlayerList:AddLine(k:GetName(), k:GetNWString("Vermilion_Rank", "player")).EntityID = k:EntIndex()
				end
			end
		})
		
	Vermilion.Menu:AddPage({
			ID = "rank_overview",
			Name = "Rank Overview",
			Order = 3,
			Category = "ranks",
			Size = { 600, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_ranks")
			end,
			Builder = function(panel)
				local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
				label:SetFont("DermaLarge")
				label:SizeToContents()
				label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
				label:SetParent(panel)
			end
		})
end

Vermilion:RegisterModule(MODULE)