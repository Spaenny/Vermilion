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
MODULE.Name = "NPC Limits"
MODULE.ID = "limit_npc"
MODULE.Description = "Prevent players from using certain NPCs."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_npc_limits"
}
MODULE.NetworkStrings = {
	"VGetNPCLimits",
	"VBlockNPC",
	"VUnblockNPC"
}

function MODULE:InitServer()

	
	self:AddHook("PlayerSpawnNPC", function(vplayer, npc_type)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), npc_type)) then
			Vermilion:AddNotification(vplayer, "You cannot spawn this NPC!", NOTIFY_ERROR)
			return false
		end
	end)
	
	
	
	self:NetHook("VGetNPCLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			MODULE:NetStart("VGetNPCLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			MODULE:NetStart("VGetNPCLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VBlockNPC", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_npc_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), weapon)) then
				table.insert(MODULE:GetData(rnk, {}, true), weapon)
			end
		end
	end)
	
	self:NetHook("VUnblockNPC", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_npc_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, {}, true), weapon)
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetNPCLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_npc"].Panel.RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_npc"].Panel.RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_npc"].Panel.RankBlockList
		local npcs = Vermilion.Menu.Pages["limit_npc"].Panel.NPCs
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(npcs) do
					if(k1.ClassName == k) then
						blocklist:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_npc",
			Name = "NPCs",
			Order = 5,
			Category = "limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_npc_limits")
			end,
			Builder = function(panel)
				local blockNPC = nil
				local unblockNPC = nil
				local rankList = nil
				local allNPCs = nil
				local rankBlockList = nil
							
				
				rankList = VToolkit:CreateList({ "Name" }, false, false)
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					blockNPC:SetDisabled(not (self:GetSelected()[1] != nil and allNPCs:GetSelected()[1] != nil))
					unblockNPC:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					MODULE:NetStart("VGetNPCLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({ "Name" })
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(240, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				panel.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked NPCs")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockNPC:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				
				allNPCs = VToolkit:CreateList({"Name"})
				allNPCs:SetPos(panel:GetWide() - 250, 30)
				allNPCs:SetSize(240, panel:GetTall() - 40)
				allNPCs:SetParent(panel)
				panel.AllNPCs = allNPCs
				
				local allNPCsHeader = VToolkit:CreateHeaderLabel(allNPCs, "All NPCs")
				allNPCsHeader:SetParent(panel)
				
				function allNPCs:OnRowSelected(index, line)
					blockNPC:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allNPCs)
				
				
				blockNPC = VToolkit:CreateButton("Block NPC", function()
					for i,k in pairs(allNPCs:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankBlockList:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankBlockList:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						MODULE:NetStart("VBlockNPC")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				blockNPC:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 100)
				blockNPC:SetWide(panel:GetWide() - 20 - select(1, allNPCs:GetWide()) - select(1, blockNPC:GetPos()))
				blockNPC:SetParent(panel)
				blockNPC:SetDisabled(true)
				
				unblockNPC = VToolkit:CreateButton("Unblock NPC", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						MODULE:NetStart("VUnblockNPC")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockNPC:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 130)
				unblockNPC:SetWide(panel:GetWide() - 20 - select(1, allNPCs:GetWide()) - select(1, unblockNPC:GetPos()))
				unblockNPC:SetParent(panel)
				unblockNPC:SetDisabled(true)
				
				panel.BlockNPC = blockNPC
				panel.UnblockNPC = unblockNPC
				
				
			end,
			Updater = function(panel)
				if(panel.NPCs == nil) then
					panel.NPCs = {}
					for i,k in pairs(list.Get("NPC")) do
						table.insert(panel.NPCs, { Name = k.Name, ClassName = k.Class })
					end
				end
				if(table.Count(panel.AllNPCs:GetLines()) == 0) then
					for i,k in pairs(panel.NPCs) do
						local ln = panel.AllNPCs:AddLine(k.Name)
						ln.ClassName = k.ClassName
					end
				end
				Vermilion:PopulateRankTable(panel.RankList, false, true)
				panel.RankBlockList:Clear()
				panel.BlockNPC:SetDisabled(true)
				panel.UnblockNPC:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)