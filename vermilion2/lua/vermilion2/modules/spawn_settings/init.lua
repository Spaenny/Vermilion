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
MODULE.Name = "Spawn Parameters"
MODULE.ID = "spawn_settings"
MODULE.Description = "Allows players to spawn with custom settings."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_spawn_settings"
}
MODULE.NetworkStrings = {
	"VRankSpawnLoad",
	"VRankSpawnAdd",
	"VRankSpawnDel",
	"VUpdateRule"
}

MODULE.DataTypes = {}

function MODULE:AddType(name, applyfunc, validator, formatter, default)
	self.DataTypes[name] = { ApplyFunc = applyfunc, Validator = validator, Formatter = formatter, Default = default }
end

function MODULE:InitShared()
	self:AddType("Health", function(vplayer, data)
		vplayer:SetHealth(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 100)
	
	self:AddType("Jump Power", function(vplayer, data)
		vplayer:SetJumpPower(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 200)
	
	self:AddType("Max Health", function(vplayer, data)
		vplayer.Vermilion_MaxHealth = data
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, nil)
	
	self:AddType("Run Speed", function(vplayer, data)
		vplayer:SetRunSpeed(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 500)
	
	self:AddType("Walk Speed", function(vplayer, data)
		vplayer:SetWalkSpeed(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 200)
	
	self:AddType("Armour", function(vplayer, data)
		vplayer:SetArmor(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 0)
end

function MODULE:InitServer()
	self:AddHook("PlayerSpawn", function(vplayer)
		timer.Simple(0.5, function()
			for i,k in pairs(MODULE.DataTypes) do
				k.ApplyFunc(vplayer, k.Default)
			end
			local userData = Vermilion:GetUser(vplayer)
			if(userData != nil) then
				local rankData = userData:GetRank()
				if(rankData != nil) then
					local rankName = rankData:GetName()
					for i,k in pairs(MODULE:GetData(rankName, {}, true)) do
						local typ = MODULE.DataTypes[i]
						typ.ApplyFunc(vplayer, k)
					end
				end
			end
		end)
	end)
	
	self:AddHook("PlayerTick", function(vplayer)
		if(not IsValid(vplayer)) then return end
		if(vplayer.Vermilion_MaxHealth != nil) then
			if(vplayer:Health() > vplayer.Vermilion_MaxHealth) then
				vplayer:SetHealth(vplayer.Vermilion_MaxHealth)
			end
		end
	end)
	
	self:NetHook("VRankSpawnLoad", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_settings")) then
			local rank = net.ReadString()
			local tab = {}
			for i,k in pairs(MODULE:GetData(rank, {}, true)) do
				table.insert(tab, { PrintName = i, Value = k })
			end
			MODULE:NetStart("VRankSpawnLoad")
			net.WriteTable(tab)
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VRankSpawnAdd", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_settings")) then
			local rank = net.ReadString()
			local prop = net.ReadString()
			local val = net.ReadInt(32)
			
			MODULE:GetData(rank, {}, true)[prop] = val
		end
	end)
	
	self:NetHook("VRankSpawnDel", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_settings")) then
			local rank = net.ReadString()
			local prop = net.ReadString()
			
			MODULE:GetData(rank, {}, true)[prop] = nil
		end
	end)
	
	self:NetHook("VUpdateRule", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_settings")) then
			local rank = net.ReadString()
			local prop = net.ReadString()
			local val = net.ReadInt(32)
			
			MODULE:GetData(rank, {}, true)[prop] = val
		end
	end)
end

function MODULE:InitClient()

	self:NetHook("VRankSpawnLoad", function()
		local paneldata = Vermilion.Menu.Pages["spawn_settings"]
		
		paneldata.RankRuleList:Clear()
		for i,k in pairs(net.ReadTable()) do
			paneldata.RankRuleList:AddLine(k.PrintName, k.Value)
		end
	end)
	
	Vermilion.Menu:AddCategory("player", 4)
	
	Vermilion.Menu:AddPage({
			ID = "spawn_settings",
			Name = "Spawn Parameters",
			Order = 4,
			Category = "player",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_spawn_settings")
			end,
			Builder = function(panel, paneldata)
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
				paneldata.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					addRule:SetDisabled(not (self:GetSelected()[1] != nil and allRules:GetSelected()[1] != nil))
					delRule:SetDisabled(not (self:GetSelected()[1] != nil and rankRuleList:GetSelected()[1] != nil))
					editRule:SetDisabled(not (self:GetSelected()[1] != nil and rankRuleList:GetSelected()[1] != nil))
					MODULE:NetStart("VRankSpawnLoad")
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
				paneldata.RankRuleList = rankRuleList
				
				local rankRuleListHeader = VToolkit:CreateHeaderLabel(rankRuleList, "Spawn Properties")
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
				paneldata.AllRules = allRules
				
				local allRulesHeader = VToolkit:CreateHeaderLabel(allRules, "All Properties")
				allRulesHeader:SetParent(panel)
				
				function allRules:OnRowSelected(index, line)
					addRule:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allRules)
				
				
				addRule = VToolkit:CreateButton("Add Property", function()
					for i,k in pairs(allRules:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankRuleList:GetLines()) do
							if(k:GetValue(1) == k1:GetValue(1)) then has = true break end
						end
						if(has) then continue end
						VToolkit:CreateTextInput("Enter the value for this property:", function(value)
							if(tonumber(value) == nil) then
								VToolkit:CreateErrorDialog("Invalid input - not a number!")
								return
							end
							local ln = rankRuleList:AddLine(k:GetValue(1), value)
							MODULE:NetStart("VRankSpawnAdd")
							net.WriteString(rankList:GetSelected()[1]:GetValue(1))
							net.WriteString(k:GetValue(1))
							net.WriteInt(tonumber(value), 32)
							net.SendToServer()
						end)
						
						
					end
				end)
				addRule:SetPos(select(1, rankRuleList:GetPos()) + rankRuleList:GetWide() + 10, 100)
				addRule:SetWide(panel:GetWide() - 20 - select(1, allRules:GetWide()) - select(1, addRule:GetPos()))
				addRule:SetParent(panel)
				addRule:SetDisabled(true)
				
				delRule = VToolkit:CreateButton("Remove Property", function()
					for i,k in pairs(rankRuleList:GetSelected()) do
						MODULE:NetStart("VRankSpawnDel")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k:GetValue(1))
						net.SendToServer()
						
						rankRuleList:RemoveLine(k:GetID())
					end
				end)
				delRule:SetPos(select(1, rankRuleList:GetPos()) + rankRuleList:GetWide() + 10, 130)
				delRule:SetWide(panel:GetWide() - 20 - select(1, allRules:GetWide()) - select(1, delRule:GetPos()))
				delRule:SetParent(panel)
				delRule:SetDisabled(true)
				
				editRule = VToolkit:CreateButton("Edit Property", function()
					VToolkit:CreateTextInput("Enter the new value for the \"" .. rankRuleList:GetSelected()[1]:GetValue(1) .. "\" property:", function(value)
						if(tonumber(value) == nil) then
							VToolkit:CreateErrorDialog("Invalid input - not a number!")
							return
						end
						rankRuleList:GetSelected()[1]:SetValue(2, value)
						MODULE:NetStart("VUpdateRule")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(rankRuleList:GetSelected()[1]:GetValue(1))
						net.WriteInt(tonumber(rankRuleList:GetSelected()[1]:GetValue(2)), 32)
						net.SendToServer()
					end)
				end)
				editRule:SetPos(select(1, rankRuleList:GetPos()) + rankRuleList:GetWide() + 10, 160)
				editRule:SetWide(panel:GetWide() - 20 - select(1, allRules:GetWide()) - select(1, editRule:GetPos()))
				editRule:SetParent(panel)
				editRule:SetDisabled(true)
				
				paneldata.AddRule = addRule
				paneldata.DelRule = delRule
				paneldata.EditRule = editRule
				
			end,
			Updater = function(panel, paneldata)
				if(table.Count(paneldata.AllRules:GetLines()) == 0) then
					for i,k in pairs(MODULE.DataTypes) do
						paneldata.AllRules:AddLine(i, k.Default)
					end
				end
				Vermilion:PopulateRankTable(paneldata.RankList, false, true)
				paneldata.RankRuleList:Clear()
				paneldata.AddRule:SetDisabled(true)
				paneldata.DelRule:SetDisabled(true)
				paneldata.EditRule:SetDisabled(true)
			end
		})
end

Vermilion:RegisterModule(MODULE)