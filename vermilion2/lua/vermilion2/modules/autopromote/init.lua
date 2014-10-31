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
MODULE.Name = "Auto-Promote"
MODULE.ID = "auto_promote"
MODULE.Description = "Automatically promotes users to different ranks depending on playtime. This is a direct port from Vermilion 1 and is probably buggy. I'll fix that later."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_autopromote"
}
MODULE.NetworkStrings = {
	"VGetAutoPromoteListing",
	"VSetAutoPromoteListing"
}

function MODULE:InitServer()

	-- automatically alter the promotion listings whenever a rank is deleted or renamed.

	self:AddHook(Vermilion.Event.RankDeleted, function(name)
		for i,k in pairs(MODULE:GetData("promotion_listings", {}, true)) do
			if(k.Rank == name or k.ToRank == name) then
				table.RemoveByValue(MODULE:GetData("promotion_listings", {}, true), k)
			end
		end
	end)
	
	self:AddHook(Vermilion.Event.RankRenamed, function(oldname, newname)
		for i,k in pairs(MODULE:GetData("promotion_listings", {}, true)) do
			if(k.Rank == oldname) then k.Rank = newname end
			if(k.ToRank == oldname) then k.ToRank = newname end
		end
	end)
	
	timer.Create("V-AutoPromote", 10, 0, function()
		local promotionData = MODULE:GetData("promotion_listings", {}, true)
		for i,k in pairs(player.GetHumans()) do
			local vdata = Vermilion:GetUser(k)
			local rank = vdata:GetRank()
			for i1,k1 in pairs(promotionData) do
				if(k1.Rank == rank.Name) then
					if(vdata.Playtime >= k1.Playtime) then
						vdata:SetRank(k1.ToRank)
						Vermilion:BroadcastNoficiation(k:GetName() .. " was automatically promoted to " .. k1.ToRank .. " after playing for " .. k1.PlaytimeString .. "!")
					end
					break
				end
			end
		end
	end)
	
	self:NetHook("VGetAutoPromoteListing", function(vplayer)
		MODULE:NetStart("VGetAutoPromoteListing")
		net.WriteTable(MODULE:GetData("promotion_listings", {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VSetAutoPromoteListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_autopromote")) then
			MODULE:SetData("promotion_listings", net.ReadTable())
		end
	end)
	
end

function MODULE:InitClient()
	self:NetHook("VGetAutoPromoteListing", function()
		local panel = Vermilion.Menu.Pages["autopromote"].Panel
		if(IsValid(panel)) then
			panel.PromotionTable:Clear()
			local tab = net.ReadTable()
			for i,k in pairs(tab) do
				panel.PromotionTable:AddLine(k.Rank, k.ToRank, k.PlaytimeString).TotalTime = k.Playtime
			end
		end
	end)

	Vermilion.Menu:AddCategory("ranks", 3)

	Vermilion.Menu:AddPage({
			ID = "autopromote",
			Name = "Auto-Promote",
			Order = 6,
			Category = "ranks",
			Size = { 785, 540 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_autopromote")
			end,
			Builder = function(panel)
				local listings = VToolkit:CreateList({"From Rank", "To Rank", "After Playing For"}, false)
				listings:SetPos(10, 30)
				listings:SetSize(765, 320)
				listings:SetParent(panel)
				
				panel.PromotionTable = listings
				
				local listingsLabel = VToolkit:CreateHeaderLabel(listings, "Auto-Promotion Listings")
				listingsLabel:SetParent(panel)
				
				local removeListing = VToolkit:CreateButton("Remove Listing", function()
					if(table.Count(listings:GetSelected()) == 0) then
						VToolkit:CreateErrorDialog("Must select at least one listing to remove.")
						return
					end
					local tab = {}
					for i,k in pairs(listings:GetLines()) do
						local add = true
						for i1,k1 in pairs(listings:GetSelected()) do
							if(k1 == k) then add = false break end
						end
						if(add) then
							table.insert(tab, { k:GetValue(1), k:GetValue(2), k:GetValue(3), k.TotalTime })
						end
					end
					listings:Clear()
					for i,k in pairs(tab) do
						listings:AddLine(k[1], k[2], k[3]).TotalTime = k[4]
					end
					panel.UnsavedChanges = true
				end)
				removeListing:SetPos(670, 360)
				removeListing:SetSize(105, 30)
				removeListing:SetParent(panel)
				
				local saveListings = VToolkit:CreateButton("Save Listings", function()
					local tab = {}
					for i,k in pairs(listings:GetLines()) do
						table.insert(tab, { Rank = k:GetValue(1), ToRank = k:GetValue(2), PlaytimeString = k:GetValue(3), Playtime = k.TotalTime})
					end
					MODULE:NetStart("VSetAutoPromoteListing")
					net.WriteTable(tab)
					net.SendToServer()
					panel.UnsavedChanges = false
				end)
				saveListings:SetPos(555, 360)
				saveListings:SetSize(105, 30)
				saveListings:SetParent(panel)
				
				local fromRankLabel = VToolkit:CreateLabel("From Rank: ")
				fromRankLabel:SetPos(10, 402)
				fromRankLabel:SetDark(true)
				fromRankLabel:SetParent(panel)
				
				local fromRankCombo = VToolkit:CreateComboBox()
				fromRankCombo:SetPos(fromRankLabel:GetWide() + 20, 400)
				fromRankCombo:SetSize(200, 20)
				fromRankCombo:SetParent(panel)
				fromRankCombo:SetValue("From Rank")
				fromRankCombo.OnSelect = function(panel, index, value)
					fromRankCombo.SelectedValue = value
				end
				panel.FromRankCombo = fromRankCombo
				
				local toRankLabel = VToolkit:CreateLabel("To Rank: ")
				toRankLabel:SetPos(10, 432)
				toRankLabel:SetDark(true)
				toRankLabel:SetParent(panel)
				
				local toRankCombo = VToolkit:CreateComboBox()
				toRankCombo:SetPos(toRankLabel:GetWide() + 20, 430)
				toRankCombo:SetSize(200, 20)
				toRankCombo:SetParent(panel)
				toRankCombo:SetValue("To Rank")
				toRankCombo.OnSelect = function(panel, index, value)
					toRankCombo.SelectedValue = value
				end
				panel.ToRankCombo = toRankCombo
				
				local timeLabel = VToolkit:CreateLabel("After Playing For (running total since first ever spawn, not since last promotion):")
				timeLabel:SetPos(10, 460)
				timeLabel:SetDark(true)
				timeLabel:SetParent(panel)
				
				local daysLabel = VToolkit:CreateLabel("Days:")
				daysLabel:SetPos(10 + ((64 - daysLabel:GetWide()) / 2), 480)
				daysLabel:SetParent(panel)
				
				local daysWang = VToolkit:CreateNumberWang(0, 999)
				daysWang:SetPos(10, 495)
				daysWang:SetParent(panel)
				
				
				
				local hoursLabel = VToolkit:CreateLabel("Hours:")
				hoursLabel:SetPos(84 + ((64 - hoursLabel:GetWide()) / 2), 480)
				hoursLabel:SetParent(panel)
				
				local hoursWang = VToolkit:CreateNumberWang(0, 24)
				hoursWang:SetPos(84, 495)
				hoursWang:SetParent(panel)
				hoursWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 24) then
						wang:SetValue(0)
						daysWang:SetValue(daysWang:GetValue() + 1)
					end
				end
				
				
				
				local minsLabel = VToolkit:CreateLabel("Minutes:")
				minsLabel:SetPos(158 + ((64 - minsLabel:GetWide()) / 2), 480)
				minsLabel:SetParent(panel)
				
				local minsWang = VToolkit:CreateNumberWang(0, 60)
				minsWang:SetPos(158, 495)
				minsWang:SetParent(panel)
				minsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						hoursWang:SetValue(hoursWang:GetValue() + 1)
					end
				end
				
				
				
				local secondsLabel = VToolkit:CreateLabel("Seconds:")
				secondsLabel:SetPos(232 + ((64 - secondsLabel:GetWide()) / 2), 480)
				secondsLabel:SetParent(panel)
				
				local secondsWang = VToolkit:CreateNumberWang(0, 60)
				secondsWang:SetPos(232, 495)
				secondsWang:SetParent(panel)
				secondsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						minsWang:SetValue(minsWang:GetValue() + 1)
					end
				end
				
				local addListingButton = VToolkit:CreateButton("Add Listing", function()
					if(fromRankCombo.SelectedValue == nil or toRankCombo.SelectedValue == nil) then
						VToolkit:CreateErrorDialog("Please input the initial rank and the target rank correctly!")
						return
					end
					if(fromRankCombo.SelectedValue == toRankCombo.SelectedValue) then
						VToolkit:CreateErrorDialog("Must select two different ranks.")
						return
					end
					local time = 0
					-- seconds per year = 31557600
					-- average seconds per month = 2592000 
					-- seconds per week = 604800
					-- seconds per day = 86400
					-- seconds per hour = 3600
					
					time = time + (secondsWang:GetValue())
					time = time + (minsWang:GetValue() * 60)
					time = time + (hoursWang:GetValue() * 3600)
					time = time + (daysWang:GetValue() * 86400)
					
					if(time == 0) then
						VToolkit:CreateErrorDialog("Must have playtime greater than zero.")
						return
					end
					
					listings:AddLine(fromRankCombo.SelectedValue, toRankCombo.SelectedValue, tostring(daysWang:GetValue()) .. "d " .. tostring(hoursWang:GetValue()) .. "h " .. tostring(minsWang:GetValue()) .. "m " .. tostring(secondsWang:GetValue()) .. "s").TotalTime = time
					panel.UnsavedChanges = true
				end)
				addListingButton:SetPos(306, 485)
				addListingButton:SetSize(105, 30)
				addListingButton:SetParent(panel)
				
				local lab = VToolkit:CreateLabel("Note to self: update the interface. Porting stuff directly from V1 is BAD.")
				lab:SetPos(440, 485)
				lab:SetParent(panel)
				
				MODULE:AddHook(Vermilion.Event.MENU_CLOSING, function()
					if(panel.UnsavedChanges) then
						VToolkit:CreateConfirmDialog("There are unsaved changes in the Auto-Promote settings! Really close?", function()
							Vermilion.Menu:Close(true)
							panel.UnsavedChanges = false
						end, { Confirm = "Yes", Deny = "No", Default = false })
						return false
					end
				end)
			
			end,
			Updater = function(panel)
				MODULE:NetCommand("VGetAutoPromoteListing")
				panel.FromRankCombo:Clear()
				panel.ToRankCombo:Clear()
				for i,k in pairs(Vermilion.Data.RankOverview) do
					if(k.Name != "owner") then panel.FromRankCombo:AddChoice(k.Name) end
					panel.ToRankCombo:AddChoice(k.Name)
				end
			end
		})
end

Vermilion:RegisterModule(MODULE)