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
MODULE.Name = "Vehicle Limits"
MODULE.ID = "limit_vehicle"
MODULE.Description = "Prevent players from spawning certain vehicles."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"manage_vehicle_limits"
}
MODULE.NetworkStrings = {
	"VGetVehicleLimits",
	"VBlockVehicle",
	"VUnblockVehicle"
}

function MODULE:InitServer()

	
	self:AddHook("PlayerSpawnVehicle", function(vplayer, model, class, data)
		if(table.HasValue(MODULE:GetData(Vermilion:GetUser(vplayer):GetRankName(), {}, true), model)) then
			Vermilion:AddNotification(vplayer, "You cannot spawn this vehicle!", NOTIFY_ERROR)
			return false
		end
	end)
	
	
	
	self:NetHook("VGetVehicleLimits", function(vplayer)
		local rnk = net.ReadString()
		local data = MODULE:GetData(rnk, {}, true)
		if(data != nil) then
			MODULE:NetStart("VGetVehicleLimits")
			net.WriteString(rnk)
			net.WriteTable(data)
			net.Send(vplayer)
		else
			MODULE:NetStart("VGetVehicleLimits")
			net.WriteString(rnk)
			net.WriteTable({})
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VBlockVehicle", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_vehicle_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			if(not table.HasValue(MODULE:GetData(rnk, {}, true), weapon)) then
				table.insert(MODULE:GetData(rnk, {}, true), weapon)
			end
		end
	end)
	
	self:NetHook("VUnblockVehicle", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_vehicle_limits")) then
			local rnk = net.ReadString()
			local weapon = net.ReadString()
			table.RemoveByValue(MODULE:GetData(rnk, {}, true), weapon)
		end
	end)
	
end

function MODULE:InitClient()

	self:NetHook("VGetVehicleLimits", function()
		if(not IsValid(Vermilion.Menu.Pages["limit_vehicle"].Panel.RankList)) then return end
		if(net.ReadString() != Vermilion.Menu.Pages["limit_vehicle"].Panel.RankList:GetSelected()[1]:GetValue(1)) then return end
		local data = net.ReadTable()
		local blocklist = Vermilion.Menu.Pages["limit_vehicle"].Panel.RankBlockList
		local vehicles = Vermilion.Menu.Pages["limit_vehicle"].Panel.Vehicles
		if(IsValid(blocklist)) then
			blocklist:Clear()
			for i,k in pairs(data) do
				for i1,k1 in pairs(vehicles) do
					if(k1.ClassName == k) then
						blocklist:AddLine(k1.Name).ClassName = k
					end
				end
			end
		end
	end)

	Vermilion.Menu:AddCategory("limits", 5)
	
	Vermilion.Menu:AddPage({
			ID = "limit_vehicle",
			Name = "Vehicles",
			Order = 6,
			Category = "limits",
			Size = { 900, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_vehicle_limits")
			end,
			Builder = function(panel)
				local blockVehicle = nil
				local unblockVehicle = nil
				local rankList = nil
				local allVehicles = nil
				local rankBlockList = nil
				
				panel.PreviewPanel = VToolkit:CreatePreviewPanel("model", panel, function(ent)
					if(panel.PreviewPanel.EntityClass != "prop_vehicle_prisoner_pod") then
						ent:SetPos(Vector(-120, -120, 0))
					end
				end)
				
				rankList = VToolkit:CreateList({ "Name" }, false, false)
				rankList:SetPos(10, 30)
				rankList:SetSize(200, panel:GetTall() - 40)
				rankList:SetParent(panel)
				panel.RankList = rankList
				
				local rankHeader = VToolkit:CreateHeaderLabel(rankList, "Ranks")
				rankHeader:SetParent(panel)
				
				function rankList:OnRowSelected(index, line)
					blockVehicle:SetDisabled(not (self:GetSelected()[1] != nil and allVehicles:GetSelected()[1] != nil))
					unblockVehicle:SetDisabled(not (self:GetSelected()[1] != nil and rankBlockList:GetSelected()[1] != nil))
					MODULE:NetStart("VGetVehicleLimits")
					net.WriteString(rankList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
				end
				
				rankBlockList = VToolkit:CreateList({ "Name" })
				rankBlockList:SetPos(220, 30)
				rankBlockList:SetSize(240, panel:GetTall() - 40)
				rankBlockList:SetParent(panel)
				panel.RankBlockList = rankBlockList
				
				local rankBlockListHeader = VToolkit:CreateHeaderLabel(rankBlockList, "Blocked Vehicles")
				rankBlockListHeader:SetParent(panel)
				
				function rankBlockList:OnRowSelected(index, line)
					unblockVehicle:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(rankBlockList)
				
				
				allVehicles = VToolkit:CreateList({"Name"})
				allVehicles:SetPos(panel:GetWide() - 250, 30)
				allVehicles:SetSize(240, panel:GetTall() - 40)
				allVehicles:SetParent(panel)
				panel.AllVehicles = allVehicles
				
				local allVehiclesHeader = VToolkit:CreateHeaderLabel(allVehicles, "All Vehicles")
				allVehiclesHeader:SetParent(panel)
				
				function allVehicles:OnRowSelected(index, line)
					blockVehicle:SetDisabled(not (self:GetSelected()[1] != nil and rankList:GetSelected()[1] != nil))
				end
				
				VToolkit:CreateSearchBox(allVehicles)
				
				
				blockVehicle = VToolkit:CreateButton("Block Vehicle", function()
					for i,k in pairs(allVehicles:GetSelected()) do
						local has = false
						for i1,k1 in pairs(rankBlockList:GetLines()) do
							if(k.ClassName == k1.ClassName) then has = true break end
						end
						if(has) then continue end
						rankBlockList:AddLine(k:GetValue(1)).ClassName = k.ClassName
						
						MODULE:NetStart("VBlockVehicle")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
					end
				end)
				blockVehicle:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 100)
				blockVehicle:SetWide(panel:GetWide() - 20 - select(1, allVehicles:GetWide()) - select(1, blockVehicle:GetPos()))
				blockVehicle:SetParent(panel)
				blockVehicle:SetDisabled(true)
				
				unblockVehicle = VToolkit:CreateButton("Unblock Vehicle", function()
					for i,k in pairs(rankBlockList:GetSelected()) do
						MODULE:NetStart("VUnblockVehicle")
						net.WriteString(rankList:GetSelected()[1]:GetValue(1))
						net.WriteString(k.ClassName)
						net.SendToServer()
						
						rankBlockList:RemoveLine(k:GetID())
					end
				end)
				unblockVehicle:SetPos(select(1, rankBlockList:GetPos()) + rankBlockList:GetWide() + 10, 130)
				unblockVehicle:SetWide(panel:GetWide() - 20 - select(1, allVehicles:GetWide()) - select(1, unblockVehicle:GetPos()))
				unblockVehicle:SetParent(panel)
				unblockVehicle:SetDisabled(true)
				
				panel.BlockVehicle = blockVehicle
				panel.UnblockVehicle = unblockVehicle
				
				
			end,
			Updater = function(panel)
				if(panel.Vehicles == nil) then
					panel.Vehicles = {}
					for i,k in pairs(list.Get("Vehicles")) do
						table.insert(panel.Vehicles, { Name = k.Name, ClassName = k.Model, StdClass = k.Class })
					end
				end
				if(table.Count(panel.AllVehicles:GetLines()) == 0) then
					for i,k in pairs(panel.Vehicles) do
						local ln = panel.AllVehicles:AddLine(k.Name)
						ln.ClassName = k.ClassName
						
						ln.ModelPath = k.ClassName
						
						ln.OldCursorMoved = ln.OnCursorMoved
						ln.OldCursorEntered = ln.OnCursorEntered
						ln.OldCursorExited = ln.OnCursorExited
						
						function ln:OnCursorEntered()
							panel.PreviewPanel:SetVisible(true)
							panel.PreviewPanel.ModelView:SetModel(ln.ModelPath)
							panel.PreviewPanel.EntityClass = k.StdClass
							
							
							if(self.OldCursorEntered) then self:OldCursorEntered() end
						end
						
						function ln:OnCursorExited()
							panel.PreviewPanel:SetVisible(false)
							
							if(self.OldCursorExited) then self:OldCursorExited() end
						end
						
						function ln:OnCursorMoved(x,y)
							if(IsValid(panel.PreviewPanel)) then
								local x, y = input.GetCursorPos()
								panel.PreviewPanel:SetPos(x - 180, y - 117)
							end
							
							if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
						end
					end
				end
				Vermilion:PopulateRankTable(panel.RankList, false, true)
				panel.RankBlockList:Clear()
				panel.BlockVehicle:SetDisabled(true)
				panel.UnblockVehicle:SetDisabled(true)
			end
		})
	
end

Vermilion:RegisterModule(MODULE)