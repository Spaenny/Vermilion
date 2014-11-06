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
MODULE.Name = "Toolgun Limits"
MODULE.ID = "limit_toolgun"
MODULE.Description = "Prevent players from using certain tools."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_toolgun_limits"
}
MODULE.NetworkStrings = {
	"VGetToolgunLimits",
	"VBlockTool",
	"VUnblockTool"
}

function MODULE:InitServer()
	
	self:AddHook("CanTool", function(vplayer, tr, tool)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), tool)) then
			Vermilion:AddNotification(vplayer, "You cannot use this toolgun mode!", NOTIFY_ERROR)
			return false
		end
	end)
	
	self:NetHook("VGetToolgunLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			MODULE:NetStart("VGetToolgunLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			MODULE:NetStart("VGetToolgunLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VBlockTool", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_toolgun_limits")) then
			local rnk = net.ReadString()
			local tool = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), tool)) then
				table.insert(MODULE:GetData(rnk, {}, true), tool)
			end
		end
	end)
	
	self:NetHook("VUnblockTool", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_toolgun_limits")) then
			local rnk = net.ReadString()
			local tool = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, {}, true), tool)
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetToolgunLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_toolgun"].RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_toolgun"].RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_toolgun"].RankBlockList
		local tools = Vermilion.Menu.Pages["limit_toolgun"].Tools
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(tools) do
					if(k1.ClassName == k) then
						blocklist:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_toolgun",
			Name = "Tools",
			Order = 2,
			Category = "limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_toolgun_limits")
			end,
			Builder = function(panel, paneldata)
				local blockTool = nil
				local unblockTool = nil
				local rankList = nil
				local allTools = nil
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
					blockTool:SetDisabled(not (self:GetSelected()[1] != nil and allTools:GetSelected()[1] != nil))
					unblockTool:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					MODULE:NetStart("VGetToolgunLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({
					cols = {
						"Name"
					}
				})
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(240, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				paneldata.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked Tools")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockTool:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				
				allTools = VToolkit:CreateList({
					cols = {
						"Name"
					}
				})
				allTools:SetPos(panel:GetWide() - 250, 30)
				allTools:SetSize(240, panel:GetTall() - 40)
				allTools:SetParent(panel)
				paneldata.AllTools = allTools
				
				local allToolsHeader = VToolkit:CreateHeaderLabel(allTools, "All Tools")
				allToolsHeader:SetParent(panel)
				
				function allTools:OnRowSelected(index, line)
					blockTool:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allTools)
				
				
				blockTool = VToolkit:CreateButton("Block Tool", function()
					for i,k in pairs(allTools:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankBlockList:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankBlockList:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						MODULE:NetStart("VBlockTool")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				blockTool:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 100)
				blockTool:SetWide(panel:GetWide() - 20 - select(1, allTools:GetWide()) - select(1, blockTool:GetPos()))
				blockTool:SetParent(panel)
				blockTool:SetDisabled(true)
				
				unblockTool = VToolkit:CreateButton("Unblock Tool", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						MODULE:NetStart("VUnblockTool")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockTool:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 130)
				unblockTool:SetWide(panel:GetWide() - 20 - select(1, allTools:GetWide()) - select(1, unblockTool:GetPos()))
				unblockTool:SetParent(panel)
				unblockTool:SetDisabled(true)
				
				paneldata.BlockTool = blockTool
				paneldata.UnblockTool = unblockTool
				
				
			end,
			Updater = function(panel, paneldata)
				if(paneldata.Tools == nil) then
					paneldata.Tools = {}
					if(weapons.Get("gmod_tool") != nil) then
						for i,k in pairs(weapons.Get("gmod_tool").Tool) do
							local PrintName = k.Name
							if(k.Name == nil) then PrintName = i end
							if(string.StartWith(PrintName, "#")) then
								PrintName = language.GetPhrase(string.Replace(PrintName, "#", ""))
							end
							table.insert(paneldata.Tools, { Name = PrintName, ClassName = i })
						end
					end
				end
				if(table.Count(paneldata.AllTools:GetLines()) == 0) then
					for i,k in pairs(paneldata.Tools) do
						local ln = paneldata.AllTools:AddLine(k.Name)
						ln.ClassName = k.ClassName
					end
				end
				Vermilion:PopulateRankTable(paneldata.RankList, false, true)
				paneldata.RankBlockList:Clear()
				paneldata.BlockTool:SetDisabled(true)
				paneldata.UnblockTool:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)