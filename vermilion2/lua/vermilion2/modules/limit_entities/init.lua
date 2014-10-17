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
MODULE.Name = "Entity Limits"
MODULE.ID = "limit_entities"
MODULE.Description = "Prevent players from spawning certain entities."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_entity_limits"
}
MODULE.NetworkStrings = {
	"VGetEntityLimits",
	"VBlockEntity",
	"VUnblockEntity"
}

function MODULE:InitServer()
	
	self:AddHook("PlayerSpawnSENT", function(vplayer, class)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), class)) then
			-- notify
			return false
		end
	end)
	
	self:NetHook("VGetEntityLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			net.Start("VGetEntityLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			net.Start("VGetEntityLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VBlockEntity", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_entity_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), weapon)) then
				table.insert(MODULE:GetData(rnk, {}, true), weapon)
			end
		end
	end)
	
	self:NetHook("VUnblockEntity", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_entity_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, {}, true), weapon)
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetEntityLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_entities"].Panel.RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_entities"].Panel.RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_entities"].Panel.RankBlockList
		local ents = Vermilion.Menu.Pages["limit_entities"].Panel.Entities
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(ents) do
					if(k1.ClassName == k) then
						blocklist:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("Limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_entities",
			Name = "Entities",
			Order = 4,
			Category = "Limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_entity_limits")
			end,
			Builder = function(panel)
				local blockEntity = nil
				local unblockEntity = nil
				local rankList = nil
				local allEntites = nil
				local rankBlockList = nil
			
				
				rankList = VToolkit:CreateList({ "Name" }, false, false)
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					blockEntity:SetDisabled(not (self:GetSelected()[1] != nil and allEntites:GetSelected()[1] != nil))
					unblockEntity:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					net.Start("VGetEntityLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({ "Name" })
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(240, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				panel.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked Entities")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockEntity:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				
				allEntites = VToolkit:CreateList({"Name"})
				allEntites:SetPos(panel:GetWide() - 250, 30)
				allEntites:SetSize(240, panel:GetTall() - 40)
				allEntites:SetParent(panel)
				panel.AllEntities = allEntites
				
				local allEntitesHeader = VToolkit:CreateHeaderLabel(allEntites, "All Entites")
				allEntitesHeader:SetParent(panel)
				
				function allEntites:OnRowSelected(index, line)
					blockEntity:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allEntites)
				
				
				blockEntity = VToolkit:CreateButton("Block Entity", function()
					for i,k in pairs(allEntites:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankBlockList:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankBlockList:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						net.Start("VBlockEntity")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				blockEntity:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 100)
				blockEntity:SetWide(panel:GetWide() - 20 - select(1, allEntites:GetWide()) - select(1, blockEntity:GetPos()))
				blockEntity:SetParent(panel)
				blockEntity:SetDisabled(true)
				
				unblockEntity = VToolkit:CreateButton("Unblock Entity", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						net.Start("VUnblockEntity")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockEntity:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 130)
				unblockEntity:SetWide(panel:GetWide() - 20 - select(1, allEntites:GetWide()) - select(1, unblockEntity:GetPos()))
				unblockEntity:SetParent(panel)
				unblockEntity:SetDisabled(true)
				
				panel.BlockEntity = blockEntity
				panel.UnblockEntity = unblockEntity
				
				
			end,
			Updater = function(panel)
				if(panel.Entities == nil) then
					panel.Entities = {}
					for i,k in pairs(list.Get("SpawnableEntities")) do
						table.insert(panel.Entities, { Name = k.PrintName, ClassName = k.ClassName })
					end
				end
				if(table.Count(panel.AllEntities:GetLines()) == 0) then
					for i,k in pairs(panel.Entities) do
						local ln = panel.AllEntities:AddLine(k.Name)
						ln.ClassName = k.ClassName
					end
				end
				Vermilion:PopulateRankTable(panel.RankList, false, true)
				panel.RankBlockList:Clear()
				panel.BlockEntity:SetDisabled(true)
				panel.UnblockEntity:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)