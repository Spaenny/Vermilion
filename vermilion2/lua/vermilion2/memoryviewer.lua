--[[
 Copyright 2014 Ned Hyett

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

local VermilionMem = {}

if(CLIENT) then
	local function repeatParseTree(tab, cnode)
		for i,k in pairs(tab) do
			if(istable(k)) then
				local nnode = cnode:AddNode(i)
				nnode:SetIcon("icon16/folder.png")
				repeatParseTree(k, nnode)
			else
				local tnode = cnode:AddNode(i)
				tnode:SetIcon("icon16/page.png")
				if(k == "FUNCTION") then
					tnode:SetIcon("icon16/script.png")
					tnode:AddNode("Type: function")
				elseif(k == "IMATERIAL") then
					tnode:AddNode("Type: function")
				elseif(k == "LARGE TABLE") then
					tnode:AddNode("Type: table")
					tnode:SetIcon("icon16/folder.png")
				else
					tnode:AddNode("Type: " .. type(k))
				end
				tnode:AddNode("Value: " .. tostring(k))
			end
		end
	end

	net.Receive("VermilionMem", function()
		local tree = VermilionMem.Tree
		if(VermilionMem.BaseNode != nil) then
			VermilionMem.BaseNode:Remove()
		end
		local baseNode = tree:AddNode("Vermilion")
		repeatParseTree(net.ReadTable(), baseNode)
		VermilionMem.BaseNode = baseNode
	end)
	
	concommand.Add("vermilion_memory", function()
		local panel = VToolkit:CreateFrame({
			['size'] = { 600, 600 },
			['pos'] = { (ScrW() / 2) - 300, (ScrH() / 2) - 300 },
			['closeBtn'] = true,
			['draggable'] = true,
			['title'] = "Vermilion - Memory Viewer",
			['bgBlur'] = true
		})
		panel:MakePopup()
		panel:DoModal()
		panel:SetAutoDelete(true)
		
		local refresh = VToolkit:CreateButton("Refresh", function()
			net.Start("VermilionMem")
			net.SendToServer()
		end)
		refresh:Dock(RIGHT)
		refresh:SetTall(25)
		refresh:SetParent(panel)
		
		local tree = vgui.Create("DTree")
		VermilionMem.Tree = tree
		tree:Dock(FILL)
		tree:SetParent(panel)
	end)
else
	util.AddNetworkString("VermilionMem")
	
	local function trimData(tab)
		for i,k in pairs(tab) do
			if(istable(k)) then
				if(table.Count(k) > 100) then
					tab[i] = "LARGE TABLE"
				else
					trimData(k)
				end
			elseif(isfunction(k)) then
				tab[i] = "FUNCTION"
			elseif(type(k) == "IMaterial") then
				tab[i] = "IMATERIAL"
			end
		end
	end
	
	net.Receive("VermilionMem", function(len, vplayer)
		if(not Vermilion:HasPermission(vplayer, "*")) then return end
		local data = table.Copy(Vermilion)
		trimData(data)
		net.Start("VermilionMem")
		net.WriteTable(data)
		net.Send(vplayer)
	end)
	
end