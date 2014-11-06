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
MODULE.Name = "Spawn Limits"
MODULE.ID = "limit_spawn"
MODULE.Description = "Emulates the sbox_max convars but adds a rank-based system."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_spawn_limits",
	"no_spawn_limits"
}
MODULE.NetworkStrings = {
	"VGetSpawnLimits",
	"VAddRule",
	"VRemoveRule",
	"VGetRules",
	"VUpdateRule"
}

function MODULE:InitServer()

	self:NetHook("VGetRules", function(vplayer)
		MODULE:NetStart("VGetRules")
		local tab = {}
		for i,k in pairs(cleanup.GetTable()) do
			if(not GetConVar("sbox_max" .. k)) then continue end
			table.insert(tab, { BaseName = k, CVAR = "sbox_max" .. k, Default = GetConVarNumber("sbox_max" .. k) })
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VGetSpawnLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			MODULE:NetStart("VGetSpawnLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			MODULE:NetStart("VGetSpawnLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VAddRule", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_limits")) then
			local rnk = net.ReadString()
			local rule = net.ReadString()
			local value = net.ReadInt(32)
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), { Rule = rule, Value = value } )) then
				table.insert(MODULE:GetData(rnk, {}, true), { Rule = rule, Value = value })
			end
		end
	end)
	
	self:NetHook("VUpdateRule", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_limits")) then
			local rnk = net.ReadString()
			local rule = net.ReadString()
			local val = net.ReadInt(32)
			for i,k in pairs(MODULE:GetData(rnk, {}, true)) do
				if(k.Rule == rule) then
					k.Value = val
					break
				end
			end
		end
	end)
	
	self:NetHook("VRemoveRule", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_limits")) then
			local rnk = net.ReadString()
			local rule = net.ReadString()
			for i,k in pairs(MODULE:GetData(rnk, {}, true)) do
				if(k.Rule == rule) then
					table.RemoveByValue(MODULE:GetData(rnk, {}, true), k)
					break
				end
			end
		end
	end)
	
	self:AddHook(Vermilion.Event.CheckLimit, function(vplayer, typ)
		local mode = self:GetData("enable_limit_remover", 3, true)
		if(mode > 1) then
			if(mode == 2) then return true end
			if(mode == 3 and Vermilion:HasPermission(vplayer, "no_spawn_limits")) then return end
		end
		local rankLimit = nil
		for i,k in pairs(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true)) do
			if(k.Rule == typ) then
				rankLimit = k.Value
				break
			end
		end
		if(rankLimit != nil) then
			if(vplayer:GetCount(typ) >= rankLimit and rankLimit >= 0) then
				Vermilion:AddNotification(vplayer, "You have hit the " .. typ .. " limit!", NOTIFY_ERROR)
				return false
			end
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetRules", function()
		local rulePanel = Vermilion.Menu.Pages["limit_spawn"].Panel
		if(not IsValid(rulePanel)) then return end
		local data = net.ReadTable()
		rulePanel.AllRules:Clear()
		for i,k in pairs(data) do
			local localised = language.GetPhrase("Cleanup_" .. k.BaseName)
			if(string.StartWith(localised, "Cleanup_")) then localised = k.BaseName end
			local ln = rulePanel.AllRules:AddLine(localised, k.Default)
			ln.BaseName = k.BaseName
			ln.CVAR = k.CVAR
		end
		rulePanel.Rules = data
	end)

	self:NetHook("VGetSpawnLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_spawn"].Panel.RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_spawn"].Panel.RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_spawn"].Panel.RankRuleList
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				local localised = language.GetPhrase("Cleanup_" .. k.Rule)
				if(string.StartWith(localised, "Cleanup_")) then localised = k.Rule end
				local ln = blocklist:AddLine(localised, k.Value)
				ln.CVAR = "sbox_max" .. k.Rule
				ln.BaseName = k.Rule
			end
		end
	end)

	Vermilion.Menu:AddCategory("limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_spawn",
			Name = "Spawn Caps",
			Order = 8,
			Category = "limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_spawn_limits")
			end,
			Builder = function(panel)
				local addRule = nil
				local delRule = nil
				local editRule = nil
				local rankList = nil
				local allRules = nil
				local rankRuleList = nil
				
				
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
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					addRule:SetDisabled(not (self:GetSelected()[1] != nil and allRules:GetSelected()[1] != nil))
					delRule:SetDisabled(not (self:GetSelected()[1] != nil and rankRuleList:GetSelected()[1] != nil))
					editRule:SetDisabled(not (self:GetSelected()[1] != nil and rankRuleList:GetSelected()[1] != nil))
					MODULE:NetStart("VGetSpawnLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankRuleList = VToolkit:CreateList({
					cols = {
						"Name",
						"Value"
					}
				})
				rankRuleList:SetPos(220, 30)
				rankRuleList:SetSize(240, panel:GetTall() - 40)
				rankRuleList:SetParent(panel)
				panel.RankRuleList = rankRuleList
				
				local rankRuleListHeader = VToolkit:CreateHeaderLabel(rankRuleList, "Spawn Caps")
				rankRuleListHeader:SetParent(panel)
				
				function rankRuleList:OnRowSelected(index, line)
					delRule:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
					editRule:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankRuleList)
				
				
				allRules = VToolkit:CreateList({
					cols = {
						"Name",
						"Default"
					},
					multiselect = false
				})
				allRules:SetPos(panel:GetWide() - 250, 30)
				allRules:SetSize(240, panel:GetTall() - 40)
				allRules:SetParent(panel)
				panel.AllRules = allRules
				
				local allRulesHeader = VToolkit:CreateHeaderLabel(allRules, "All Caps")
				allRulesHeader:SetParent(panel)
				
				function allRules:OnRowSelected(index, line)
					addRule:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allRules)
				
				
				addRule = VToolkit:CreateButton("Add Cap", function()
					for i,k in pairs(allRules:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankRuleList:GetLines()) do
							if(k.CVAR == k1.CVAR) then has = true break end
						end
						if(has) then continue end
						VToolkit:CreateTextInput("Enter the value for this limit (-1 = no limit):", function(value)
							if(tonumber(value) == nil) then
								VToolkit:CreateErrorDialog("Invalid input - not a number!")
								return
							end
							local ln = rankRuleList:AddLine(k:GetValue(1), value)
							ln.CVAR = k.CVAR
							ln.BaseName = k.BaseName
							MODULE:NetStart("VAddRule")
							net.WriteString(rankList:GetSelected()[1]:GetValue(1))
							net.WriteString(k.BaseName)
							net.WriteInt(tonumber(value), 32)
							net.SendToServer()
						end)
						
						
					end
				end)
				addRule:SetPos(select(1, rankRuleList:GetPos()) + rankRuleList:GetWide() + 10, 100)
				addRule:SetWide(panel:GetWide() - 20 - select(1, allRules:GetWide()) - select(1, addRule:GetPos()))
				addRule:SetParent(panel)
				addRule:SetDisabled(true)
				
				delRule = VToolkit:CreateButton("Remove Cap", function()
					for i,k in pairs(rankRuleList:GetSelected()) do
						MODULE:NetStart("VRemoveRule")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.BaseName)
						net.SendToServer()
						
						rankRuleList:RemoveLine(k:GetID())
					end
				end)
				delRule:SetPos(select(1, rankRuleList:GetPos()) + rankRuleList:GetWide() + 10, 130)
				delRule:SetWide(panel:GetWide() - 20 - select(1, allRules:GetWide()) - select(1, delRule:GetPos()))
				delRule:SetParent(panel)
				delRule:SetDisabled(true)
				
				editRule = VToolkit:CreateButton("Edit Cap", function()
					VToolkit:CreateTextInput("Enter the new value for the \"" .. rankRuleList:GetSelected()[1]:GetValue(1) .. "\" limit (-1 = no limit):", function(value)
						if(tonumber(value) == nil) then
							VToolkit:CreateErrorDialog("Invalid input - not a number!")
							return
						end
						rankRuleList:GetSelected()[1]:SetValue(2, value)
						MODULE:NetStart("VUpdateRule")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(rankRuleList:GetSelected()[1].BaseName)
						net.WriteInt(tonumber(rankRuleList:GetSelected()[1]:GetValue(2)), 32)
						net.SendToServer()
					end)
				end)
				editRule:SetPos(select(1, rankRuleList:GetPos()) + rankRuleList:GetWide() + 10, 160)
				editRule:SetWide(panel:GetWide() - 20 - select(1, allRules:GetWide()) - select(1, editRule:GetPos()))
				editRule:SetParent(panel)
				editRule:SetDisabled(true)
				
				panel.AddRule = addRule
				panel.DelRule = delRule
				panel.EditRule = editRule
				
			end,
			Updater = function(panel)
				--if(table.Count(panel.AllRules:GetLines()) == 0) then
					MODULE:NetStart("VGetRules")
					net.SendToServer()
				--end
				Vermilion:PopulateRankTable(panel.RankList, false, true)
				panel.RankRuleList:Clear()
				panel.AddRule:SetDisabled(true)
				panel.DelRule:SetDisabled(true)
				panel.EditRule:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)