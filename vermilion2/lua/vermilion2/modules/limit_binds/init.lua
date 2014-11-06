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
MODULE.Name = "Keybind Blocker"
MODULE.ID = "bindcontrol"
MODULE.Description = "Stops clients from abusing keybinds such as \"say\"."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_keybinds"
}
MODULE.NetworkStrings = {
	"VBindBlockUpdate",
	"VBindListLoad",
	"VAddBindBlock",
	"VRemoveBindBlock"
}
-- Client side list
MODULE.BannedBinds = {}


function MODULE:BroadcastNewBinds()
	for i,k in pairs(player.GetAll()) do
		MODULE:NetStart("VBindBlockUpdate")
		net.WriteTable(self:GetData(Vermilion:GetUser(k):GetRankName(), {}, true))
		net.Send(k)
	end
end

function MODULE:InitServer()
	
	self:NetHook("VBindBlockUpdate", function(vplayer)
		MODULE:NetStart("VBindBlockUpdate")
		net.WriteTable(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook(Vermilion.Event.PlayerChangeRank, function(data, old, new)
		if(IsValid(data:GetEntity())) then
			MODULE:NetStart("VBindBlockUpdate")
			net.WriteTable(MODULE:GetData(new, {}, true))
			net.Send(data:GetEntity())
		end
	end)
	
	self:NetHook("VBindListLoad", function(vplayer)
		local rank = net.ReadString()
		if(not Vermilion:HasRank(rank)) then
			return -- bad rank name
		end
		MODULE:NetStart("VBindListLoad")
		net.WriteTable(MODULE:GetData(rank, {}, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VAddBindBlock", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_keybinds")) then
			local rank = net.ReadString()
			local bind = net.ReadString()
			
			table.insert(MODULE:GetData(rank, {}, true), bind)
			
			MODULE:BroadcastNewBinds()
		end
	end)
	
	self:NetHook("VRemoveBindBlock", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_keybinds")) then
			local rank = net.ReadString()
			local bind = net.ReadString()
			
			table.RemoveByValue(MODULE:GetData(rank, {}, true), bind)
			
			MODULE:BroadcastNewBinds()
		end
	end)
	
	
	
end

function MODULE:InitClient()
	
	self:NetHook("VBindBlockUpdate", function()
		MODULE.BannedBinds = net.ReadTable()
	end)
	
	self:AddHook("PlayerBindPress", function(vplayer, bind, pressed)
		for i,k in pairs(MODULE.BannedBinds) do
			if(string.find(bind, k)) then return true end
		end
	end)
	
	self:NetHook("VBindListLoad", function()
		local paneldata = Vermilion.Menu.Pages["bindcontrol"]
		paneldata.RankBlockList:Clear()
		for i,k in pairs(net.ReadTable()) do
			paneldata.RankBlockList:AddLine(k)
		end
	end)
	
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		MODULE:NetCommand("VBindBlockUpdate")
	end)
	
	Vermilion.Menu:AddCategory("player", 4)
	
	Vermilion.Menu:AddPage({
			ID = "bindcontrol",
			Name = "Bind Blocker",
			Order = 5,
			Category = "player",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_keybinds")
			end,
			Builder = function(panel, paneldata)
				local blockBind = nil
				local unblockBind = nil
				local rankList = nil
				local rankBlockList = nil
			
				rankList = VToolkit:CreateList({
					cols = {
						"Name"
					},
					multiselect = false,
					sortable = false,
					centre = true
				})
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				paneldata.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					blockBind:SetDisabled(self:GetSelected()[1] == nil)
					unblockBind:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					MODULE:NetStart("VBindListLoad")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({
					cols = {
						"Bind"
					}
				})
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(500, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				paneldata.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked Keybinds")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockBind:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				local addBlockPanel = vgui.Create("DPanel")
				addBlockPanel:SetTall(panel:GetTall())
				addBlockPanel:SetWide((panel:GetWide() / 2) + 55)
				addBlockPanel:SetPos(panel:GetWide(), 0)
				addBlockPanel:SetParent(panel)
				paneldata.AddBlockPanel = addBlockPanel
				local cABPanel = VToolkit:CreateButton("Close", function()
					addBlockPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				cABPanel:SetPos(10, 10)
				cABPanel:SetSize(50, 20)
				cABPanel:SetParent(addBlockPanel)
				
				local blocktext = VToolkit:CreateTextbox("")
				blocktext:Dock(TOP)
				blocktext:DockMargin(10, 50, 15, 5)
				blocktext:SetTall(20)
				blocktext:SetParent(addBlockPanel)
				
				local addBlockText = VToolkit:CreateButton("Add", function()
					if(blocktext:GetValue() == "") then return end
					rankBlockList:AddLine(blocktext:GetValue())
					MODULE:NetStart("VAddBindBlock")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.WriteString(blocktext:GetValue())
					net.SendToServer()
					blocktext:SetValue("")
					addBlockPanel:MoveTo(panel:GetWide(), 0, 0.25, 0, -3)
				end)
				addBlockText:Dock(TOP)
				addBlockText:DockMargin(10, 5, 15, 5)
				addBlockText:SetTall(20)
				addBlockText:SetParent(addBlockPanel)
				
				
				blockBind = VToolkit:CreateButton("Block Bind", function()
					addBlockPanel:MoveTo((panel:GetWide() / 2) - 50, 0, 0.25, 0, -3)
				end)
				blockBind:SetPos(rankBlockList:GetX() + rankBlockList:GetWide() + 10, 100)
				blockBind:SetWide(panel:GetWide() - 10 - blockBind:GetX())
				blockBind:SetParent(panel)
				blockBind:SetDisabled(true)
				
				unblockBind = VToolkit:CreateButton("Unblock Bind", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						MODULE:NetStart("VRemoveBindBlock")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k:GetValue(1))
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockBind:SetPos(rankBlockList:GetX() + rankBlockList:GetWide() + 10, 130)
				unblockBind:SetWide(panel:GetWide() - 10 - unblockBind:GetX())
				unblockBind:SetParent(panel)
				unblockBind:SetDisabled(true)
				
				paneldata.BlockBind = blockBind
				paneldata.UnblockBind = unblockBind
				
				addBlockPanel:MoveToFront()
				
				
			end,
			Updater = function(panel, paneldata)
				Vermilion:PopulateRankTable(paneldata.RankList, false, true)
				paneldata.RankBlockList:Clear()
				paneldata.BlockBind:SetDisabled(true)
				paneldata.UnblockBind:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)