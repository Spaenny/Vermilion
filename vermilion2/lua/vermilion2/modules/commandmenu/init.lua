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
MODULE.Name = "Player Management Menu"
MODULE.ID = "playermanagement"
MODULE.Description = "<insert useful and informative description here>"
MODULE.Author = "Ned"
MODULE.Permissions = {
	"view_command_menu"
}

MODULE.Tree = {}

function MODULE:InitServer()
	
end

function MODULE:InitClient()
	Vermilion.Menu:AddCategory("player", 4)
	
	Vermilion.Menu:AddPage({
		ID = "playermanagement",
		Name = "Execute Commands",
		Order = 3,
		Category = "player",
		Size = { 800, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("view_command_menu")
		end,
		Builder = function(panel, paneldata)
			local stage = vgui.Create("DPanel")
			stage:SetDrawBackground(false)
			stage:SetParent(panel)
			stage:Dock(FILL)
			
			local lst = VToolkit:CreateCategoryList(true)
			paneldata.List = lst
			
			local cats = {}
			
			for i,k in SortedPairsByMemberValue(MODULE.Tree, "Category") do
				if(cats[k.Category] == nil) then
					cats[k.Category] = lst:Add(k.Category)
				end
			end
			
			local animating = false
			local time = 0.2
			
			for i,k in pairs(MODULE.Tree) do
				local cat = cats[k.Category]
				local btn = cat:Add(k.Name)
				btn.OldDCI = btn.DoClickInternal
				btn.DoClickInternal = function()
					if(animating) then return end
					animating = true
					local wait = time + 0.01
					if(table.Count(stage:GetChildren()) == 0) then wait = 0 end
					for i,k in pairs(stage:GetChildren()) do
						k:MoveTo(0 - k:GetWide(), 0, time, 0, -3)
					end
					timer.Simple(wait, function()
						stage:Clear()
						
						local playerlistrt = nil
						local s2panel = nil
						
						if(k.Tree.Stage1 == "PLAYERLIST") then
							local playerlistd = vgui.Create("DPanel")
							playerlistd:SetPos(-300, 0)
							playerlistd:SetSize(300, 560)
							playerlistd:SetParent(stage)
							playerlistd:SetDrawBackground(false)
							playerlistd:DockPadding(5, 5, 5, 5)
							
							local playerlist = VToolkit:CreateList({
								cols = {
									"Name",
									"Rank"
								}
							})
							playerlist:Dock(FILL)
							playerlist:SetParent(playerlistd)
							playerlistrt = playerlist
							
							for i,k in pairs(VToolkit.GetValidPlayers()) do
								playerlist:AddLine(k:GetName(), k:GetNWString("Vermilion_Rank")).EntityID = k:EntIndex()
							end
							
							function playerlist:OnRowSelected(index, ln)
								if(IsValid(s2panel)) then s2panel:MoveTo(playerlistd:GetWide(), 0, time, 0, -3) end
							end
							
							playerlistd:MoveTo(0, 0, time, 0, -3, function() animating = false end)
							
						else
							local paneld = vgui.Create("DPanel")
							paneld.OldAdd = paneld.Add
							function paneld:Add(panel)
								panel:Dock(TOP)
								panel:DockMargin(0, 0, 0, 5)
								self:OldAdd(panel)
							end
							paneld:SetPos(-300, 0)
							paneld:SetSize(300, 560)
							paneld:DockPadding(5, 5, 5, 5)
							paneld:SetDrawBackground(false)
							k.Tree.Stage1(paneld)
							paneld:SetParent(stage)
							paneld:MoveToBack()
							paneld:MoveTo(0, 0, time, 0, -3, function() animating = false end)
						end
						
						if(k.Tree.Stage2 != nil) then
							local paneld = vgui.Create("DPanel")
							paneld.OldAdd = paneld.Add
							function paneld:Add(panel)
								panel:Dock(TOP)
								panel:DockMargin(0, 0, 0, 5)
								self:OldAdd(panel)
							end
							paneld:SetPos(-300, 0)
							paneld:SetSize(300, 560)
							paneld:DockPadding(5, 5, 5, 5)
							paneld:SetDrawBackground(false)
							k.Tree.Stage2(paneld, playerlistrt)
							paneld:SetParent(stage)
							paneld:MoveToBack()
							s2panel = paneld
						end
					end)
					
					
					btn.OldDCI()
				end
			end
			
			
			lst:SetParent(panel)
			lst:Dock(LEFT)
			lst:SetWide(200)
		end
	})
	
	function MODULE:AddDefinition(name, category, tree)
		table.insert(self.Tree, { Name = name, Category = category, Tree = tree })
	end
	
	function MODULE:SendChat(text)
		net.Start("VFakeChat")
		net.WriteString(text)
		net.SendToServer()
	end
end

Vermilion:RegisterModule(MODULE)