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
MODULE.Name = "Automatic Broadcast"
MODULE.ID = "autobroadcast"
MODULE.Description = "Allows defined messages to be broadcast through the chat using an interval."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_auto_broadcast"
}
MODULE.NetworkStrings = {
	"VGetAutoBroadcastListing",
	"VAddAutoBroadcastListing",
	"VDelAutoBroadcastListing"
}
MODULE.APIFuncs = {
	{ 
		Name = "CreateNewAutoBroadcast",
		Parameters = {
			{ Name = "text", Type = "String", Desc = "The text to be broadcast" },
			{ Name = "interval", Type = "Number", Desc = "The interval to broadcast it at (seconds)" },
			{ Name = "displayinterval", Type = "String", Desc = "The interval summary to be displayed on the listings page" }
		},
		Desc = "Creates a new broadcast message"
	}
}

function MODULE:InitServer()
	function MODULE:CreateNewAutoBroadcast(text, interval, displayinterval)
		assert(text != nil and interval != nil and displayinterval != nil)
		MODULE:GetData("listings", { Text = text, Interval = interval, IntervalString = displayinterval })
	end

	timer.Create("Vermilion_AutoBroadcast", 1, 0, function()
		local messages = MODULE:GetData("listings", {}, true)
		for i,k in pairs(messages) do
			if(k.Timeout == nil) then
				k.Timeout = k.Interval
				continue
			end
			k.Timeout = k.Timeout - 1
			if(k.Timeout <= 0) then
				PrintMessage(HUD_PRINTTALK, "[Vermilion] " .. k.Text)
				k.Timeout = k.Interval
			end
		end
	end)
	
	self:NetHook("VGetAutoBroadcastListing", function(vplayer)
		MODULE:NetStart("VGetAutoBroadcastListing")
		net.WriteTable(MODULE:GetData("listings", {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VAddAutoBroadcastListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_auto_broadcast")) then
			table.insert(MODULE:GetData("listings", {}, true), net.ReadTable())
		end
	end)
	
	self:NetHook("VDelAutoBroadcastListing", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_auto_broadcast")) then
			local target = net.ReadInt(32)
			MODULE:GetData("listings", {}, true)[target] = nil
		end
	end)
end

function MODULE:InitClient()

	self:NetHook("VGetAutoBroadcastListing", function()
		local panel = Vermilion.Menu.Pages["autobroadcast"].Panel
		if(IsValid(panel)) then
			panel.MessageTable:Clear()
			for i,k in pairs(net.ReadTable()) do
				panel.MessageTable:AddLine(k.Text, k.IntervalString).TotalTime = k.Interval
			end
		end
	end)
	
	Vermilion.Menu:AddCategory("server", 2)
	
	Vermilion.Menu:AddPage({
			ID = "autobroadcast",
			Name = "Auto-Broadcast",
			Order = 6,
			Category = "server",
			Size = { 785, 540 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_auto_broadcast")
			end,
			Builder = function(panel)
				local listings = VToolkit:CreateList(MODULE:TranslateTable({ "list:text", "list:interval" }), false)
				listings:SetPos(10, 30)
				listings:SetSize(765, 460)
				listings:SetParent(panel)
				
				listings.Columns[2]:SetFixedWidth(100)
				
				panel.MessageTable = listings
				
				local listingsLabel = VToolkit:CreateHeaderLabel(listings, MODULE:TranslateStr("list:title"))
				listingsLabel:SetParent(panel)
				
				local removeListing = VToolkit:CreateButton(MODULE:TranslateStr("remove"), function()
					if(table.Count(listings:GetSelected()) == 0) then
						VToolkit:CreateErrorDialog(MODULE:TranslateStr("remove:g1"))
						return
					end
					local tab = {}
					local rtab = {}
					for i,k in pairs(listings:GetLines()) do
						local add = true
						for i1,k1 in pairs(listings:GetSelected()) do
							if(k1 == k) then add = false break end
						end
						if(add) then
							table.insert(tab, { k:GetValue(1), k:GetValue(2), k.TotalTime })
						else
							table.insert(rtab, i)
						end
					end
					for i,k in pairs(rtab) do
						MODULE:NetStart("VDelAutoBroadcastListing")
						net.WriteInt(k, 32)
						net.SendToServer()
					end
					
					listings:Clear()
					for i,k in pairs(tab) do
						listings:AddLine(k[1], k[2]).TotalTime = k[3]
					end
				end)
				removeListing:SetPos(670, 500)
				removeListing:SetSize(105, 30)
				removeListing:SetParent(panel)

				
				
				
				local addMessagePanel = vgui.Create("DPanel")
				addMessagePanel:SetTall(panel:GetTall())
				addMessagePanel:SetWide((panel:GetWide() / 2) + 55)
				addMessagePanel:SetPos(panel:GetWide(), 0)
				addMessagePanel:SetParent(panel)
				panel.AddMessagePanel = addMessagePanel
				local cAMPanel = VToolkit:CreateButton(MODULE:TranslateStr("close"), function()
					addMessagePanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				cAMPanel:SetPos(10, 10)
				cAMPanel:SetSize(50, 20)
				cAMPanel:SetParent(addMessagePanel)
				
				local addMessageButton = VToolkit:CreateButton(MODULE:TranslateStr("new"), function()
					addMessagePanel:MoveTo((panel:GetWide() / 2) - 50, 0, 0.25, 0, -3)
				end)
				addMessageButton:SetPos(10, 500)
				addMessageButton:SetSize(105, 30)
				addMessageButton:SetParent(panel)
				
				
				local messageBox = VToolkit:CreateTextbox("")
				messageBox:SetPos(10, 40)
				messageBox:SetSize(425, 410)
				messageBox:SetParent(addMessagePanel)
				messageBox:SetMultiline(true)
				
				
				
				local timeLabel = VToolkit:CreateLabel(MODULE:TranslateStr("new:interval"))
				timeLabel:SetPos(10, 470)
				timeLabel:SetDark(true)
				timeLabel:SetParent(addMessagePanel)
				
				
				
				local daysLabel = VToolkit:CreateLabel(MODULE:TranslateStr("dayslabel"))
				daysLabel:SetPos(10 + ((64 - daysLabel:GetWide()) / 2), 490)
				daysLabel:SetParent(addMessagePanel)
				
				local daysWang = VToolkit:CreateNumberWang(0, 999)
				daysWang:SetPos(10, 505)
				daysWang:SetParent(addMessagePanel)
				
				
				
				local hoursLabel = VToolkit:CreateLabel(MODULE:TranslateStr("hourslabel"))
				hoursLabel:SetPos(84 + ((64 - hoursLabel:GetWide()) / 2), 490)
				hoursLabel:SetParent(addMessagePanel)
				
				local hoursWang = VToolkit:CreateNumberWang(0, 24)
				hoursWang:SetPos(84, 505)
				hoursWang:SetParent(addMessagePanel)
				hoursWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 24) then
						wang:SetValue(0)
						daysWang:SetValue(daysWang:GetValue() + 1)
					end
				end
				
				
				
				local minsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("minuteslabel"))
				minsLabel:SetPos(158 + ((64 - minsLabel:GetWide()) / 2), 490)
				minsLabel:SetParent(addMessagePanel)
				
				local minsWang = VToolkit:CreateNumberWang(0, 60)
				minsWang:SetPos(158, 505)
				minsWang:SetParent(addMessagePanel)
				minsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						hoursWang:SetValue(hoursWang:GetValue() + 1)
					end
				end
				
				
				
				local secondsLabel = VToolkit:CreateLabel(MODULE:TranslateStr("secondslabel"))
				secondsLabel:SetPos(232 + ((64 - secondsLabel:GetWide()) / 2), 490)
				secondsLabel:SetParent(addMessagePanel)
				
				local secondsWang = VToolkit:CreateNumberWang(0, 60)
				secondsWang:SetPos(232, 505)
				secondsWang:SetParent(addMessagePanel)
				secondsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						minsWang:SetValue(minsWang:GetValue() + 1)
					end
				end
				
				local addListingButton = VToolkit:CreateButton(MODULE:TranslateStr("new:add"), function()
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
						VToolkit:CreateErrorDialog(MODULE:TranslateStr("new:gz"))
						return
					end
					
					local ln = listings:AddLine(messageBox:GetValue(), tostring(daysWang:GetValue()) .. "d " .. tostring(hoursWang:GetValue()) .. "h " .. tostring(minsWang:GetValue()) .. "m " .. tostring(secondsWang:GetValue()) .. "s")
					ln.TotalTime = time
					
					MODULE:NetStart("VAddAutoBroadcastListing")
					net.WriteTable({ Text = ln:GetValue(1), IntervalString = ln:GetValue(2), Interval = ln.TotalTime})
					net.SendToServer()
					
					messageBox:SetValue("")
					addMessagePanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				addListingButton:SetPos(326, 495)
				addListingButton:SetSize(105, 30)
				addListingButton:SetParent(addMessagePanel)
			end,
			Updater = function(panel)
				MODULE:NetCommand("VGetAutoBroadcastListing")
				panel.AddMessagePanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
			end
		})
end

Vermilion:RegisterModule(MODULE)