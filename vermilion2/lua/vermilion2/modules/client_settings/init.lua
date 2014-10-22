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
MODULE.Name = "Client Settings"
MODULE.ID = "client_settings"
MODULE.Description = "Allows the player to modify the operation of the Vermilion Client."
MODULE.Author = "Ned"
MODULE.Permissions = {

}

local categories = {
	{ Name = "Features", ID = "Features", Order = 1 },
	{ Name = "Graphics", ID = "Graphics", Order = 2 }
}
local options = {}

function MODULE:AddOption(convar, guitext, typ, category, otherdat)
	otherdat = otherdat or {}
	table.insert(options, table.Merge({ ConVar = convar, GuiText = guitext, Type = typ, Category = category }, otherdat))
end

function MODULE:InitServer()
	
end

function MODULE:InitClient()
	self:AddOption("vtoolkit_skin", "Skin (requires restart)", "Combobox", "Graphics", {
		Options = table.GetKeys(VToolkit.Skins)
	})

	Vermilion.Menu:AddPage({
		ID = "client_settings",
		Name = "Client Settings",
		Order = 0.5,
		Category = "basic",
		Size = { 600, 560 },
		Conditional = function(vplayer)
			return true
		end,
		Builder = function(panel)
			MODULE.UpdatingGUI = true
			MODULE.SettingsList = VToolkit:CreateCategoryList()
			MODULE.SettingsList:SetParent(panel)
			MODULE.SettingsList:SetPos(0, 0)
			MODULE.SettingsList:SetSize(600, 560)
			local sl = MODULE.SettingsList
			
			for i,k in SortedPairsByMemberValue(categories, "Order") do
				k.Impl = sl:Add(k.Name)
			end
			
			for i,k in pairs(options) do
				if(k.Type == "Combobox") then
					local panel = vgui.Create("DPanel")
				
					local label = VToolkit:CreateLabel(k.GuiText)
					label:SetDark(true)
					label:SetPos(10, 3 + 3)
					label:SetParent(panel)
					
					local combobox = VToolkit:CreateComboBox()
					combobox:SetPos(MODULE.SettingsList:GetWide() - 230, 3)
					combobox:SetParent(panel)
					for i1,k1 in pairs(k.Options) do
						combobox:AddChoice(k1)
					end
					combobox:SetWide(200)
					
					if(k.Incomplete) then
						local dimage = vgui.Create("DImage")
						dimage:SetImage("icon16/error.png")
						dimage:SetSize(16, 16)
						dimage:SetPos(select(1, combobox:GetPos()) - 25, 5)
						dimage:SetParent(panel)
						dimage:SetTooltip("Feature not implemented!")
					end
					
					function combobox:OnSelect(index)
						if(MODULE.UpdatingGUI) then return end
						if(k.SetAs == "text") then
							RunConsoleCommand(k.ConVar, self:GetOptionText(index))
						else
							RunConsoleCommand(k.ConVar, index)
						end
					end
					
					panel:SetSize(select(1, combobox:GetPos()) + combobox:GetWide() + 10, combobox:GetTall() + 5)
					panel:SetPaintBackground(false)
					
					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.Name == k.Category) then cat = cat1.Impl break end
					end
					
					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )
					
					panel:Dock(TOP)
					panel:SetParent(cat)
					
					
					if(tonumber(GetConVarString(k.ConVar)) == nil) then
						combobox:ChooseOptionID(table.KeyFromValue(k.Options, GetConVarString(k.ConVar)))
					else
						combobox:ChooseOptionID(GetConVarNumber(k.ConVar))
					end
					
					k.Impl = combobox
				elseif(k.Type == "Checkbox") then
					local panel = vgui.Create("DPanel")
					
					local cb = VToolkit:CreateCheckBox(k.GuiText, k.ConVar)
					cb:SetDark(true)
					cb:SetPos(10, 3)
					cb:SetParent(panel)
					
					
					panel:SetSize(cb:GetWide() + 10, cb:GetTall() + 5)
					if(k.Incomplete) then
						local dimage = vgui.Create("DImage")
						dimage:SetImage("icon16/error.png")
						dimage:SetSize(16, 16)
						dimage:SetPos(select(1, cb:GetPos()) + cb:GetWide() + 25, 5)
						dimage:SetParent(panel)
						dimage:SetTooltip("Feature not implemented!")
						panel:SetWide(panel:GetWide() + 25)
					end
					panel:SetPaintBackground(false)
					
					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.Name == k.Category) then cat = cat1.Impl break end
					end
					
					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )
					
					panel:Dock(TOP)
					panel:SetParent(cat)
					
					k.Impl = cb
				elseif(k.Type == "Slider") then
					local panel = vgui.Create("DPanel")
					
					local slider = VToolkit:CreateSlider(k.GuiText, k.Bounds.Min, k.Bounds.Max, 2)
					slider:SetPos(10, 3)
					slider:SetParent(panel)
					slider:SetWide(300)
					
					slider:SetValue(k.Default)
					
					function slider:OnChange(index)
						if(MODULE.UpdatingGUI) then return end
						net.Start("VServerUpdate")
						net.WriteTable({{ Module = k.Module, Name = k.Name, Value = index}})
						net.SendToServer()
					end
					
					panel:SetSize(slider:GetWide() + 10, slider:GetTall() + 5)
					panel:SetPaintBackground(false)
					
					local cat = nil
					for ir,cat1 in pairs(categories) do
						if(cat1.Name == k.Category) then cat = cat1.Impl break end
					end
					
					panel:SetContentAlignment( 4 )
					panel:DockMargin( 1, 0, 1, 0 )
					
					panel:Dock(TOP)
					panel:SetParent(cat)
					
					if(k.Permission != nil) then
						slider:SetEnabled(Vermilion:HasPermission(k.Permission))
					end
					k.Impl = slider
				elseif(k.Type == "Colour") then
					-- Implement Me!
				elseif(k.Type == "NumberWang") then
					-- Implement Me!
				elseif(k.Type == "Text") then
					-- Implement Me!
				end
			end
			MODULE.UpdatingGUI = false
		end,
		Updater = function(panel)
			MODULE.UpdatingGUI = true
			for i,k in pairs(options) do
				if(k.Type == "Combobox") then
					if(tonumber(GetConVarString(k.ConVar)) != nil) then
						k.Impl:ChooseOptionID(GetConVarNumber(k.ConVar))
					else
						k.Impl:ChooseOption(GetConVarString(k.ConVar))
					end
				elseif(k.Type == "Checkbox") then
					k.Impl:SetChecked(GetConVarNumber(k.ConVar))
				end
			end
			MODULE.UpdatingGUI = false
		end
	})
end

Vermilion:RegisterModule(MODULE)