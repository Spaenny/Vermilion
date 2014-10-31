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
MODULE.Name = "Addon Validator"
MODULE.ID = "addon_validator"
MODULE.Description = "Checks if the client has all the addons that the server does."
MODULE.Author = "Ned"
MODULE.Permissions = {

}
MODULE.NetworkStrings = {
	"VAddonListRequest"
}

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "checkaddons",
		Description = "Brings up the addon validator again.",
		CanRunOnDS = false,
		Function = function(sender, text, log)
			if(not MODULE:GetData("enabled", true, true)) then return end
			MODULE:NetStart("VAddonListRequest")
			local tab = {}
			for i,k in pairs(engine.GetAddons()) do
				if(k.mounted) then table.insert(tab, k) end
			end
			net.WriteTable(tab)
			net.Send(sender)
		end
	})
end

function MODULE:InitShared()
	self:AddHook(Vermilion.Event.MOD_LOADED, "AddOption", function()
		if(Vermilion:GetModule("server_settings") != nil) then
			Vermilion:GetModule("server_settings"):AddOption("addon_validator", "enabled", "Enable Addon Validator", "Checkbox", "Misc", true)
		end
	end)
end

function MODULE:InitServer()
	self:NetHook("VAddonListRequest", function(vplayer)
		if(not MODULE:GetData("enabled", true, true)) then return end
		MODULE:NetStart("VAddonListRequest")
		local tab = {}
		for i,k in pairs(engine.GetAddons()) do
			if(k.mounted) then table.insert(tab, k) end
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
end

function MODULE:InitClient()
	
	CreateClientConVar("vermilion_addonnag_do_not_ask", 0, true, false)
	
	self:NetHook("VAddonListRequest", function()
		local serverAddons = net.ReadTable()
		local clientAddons = engine.GetAddons()
		
		local missingAddons = {}
		
		for i,k in pairs(serverAddons) do
			local has = false
			for i1,k1 in pairs(clientAddons) do
				if(k.wsid == k1.wsid) then
					has = true
					break
				end
			end
			if(not has) then table.insert(missingAddons, k) end
		end
		
		Vermilion.Log("Missing " .. tostring(table.Count(missingAddons)) .. " addons!")
		
		if(table.Count(missingAddons) > 0) then
			local frame = VToolkit:CreateFrame({
				["size"] = { 600, 600 },
				["pos"] = { (ScrW() / 2) - 300, (ScrH() / 2) - 300},
				["closeBtn"] = true,
				["draggable"] = false,
				["title"] = "Vermilion Addon Alert",
				["bgBlur"] = true
			})
			frame:MakePopup()
			frame:DoModal()
			frame:SetAutoDelete(true)
			frame:SetKeyboardInputEnabled(true)
			
			local panel = vgui.Create("DPanel", frame)
			panel:SetPos(10, 35)
			panel:SetSize(580, 555)
			
			local missingAddonsList = VToolkit:CreateList({ "Addon" }, false, true)
			missingAddonsList:SetPos(10, 120)
			missingAddonsList:SetSize(250, 420)
			missingAddonsList:SetParent(panel)
			
			for i,k in pairs(missingAddons) do
				local ln = missingAddonsList:AddLine(k.title)
				ln.wsid = k.wsid
			end
			
			local alertText = VToolkit:CreateLabel("Vermilion has detected that you are missing some addons.\n\nSubscribing to these addons will significantly decrease the time taken to connect to this server as you will not have to download the addons each time you connect, and will also solve any missing textures that you are seeing as a result of missing these addons!\n\nPlease consider fixing this by using the list below!")
			alertText:SetPos(10, 10)
			alertText:SetWide(panel:GetWide() - 20)
			alertText:SetParent(panel)
			alertText:SetAutoStretchVertical(true)
			alertText:SetWrap(true)
			
			
			local openInWSButton = VToolkit:CreateButton("Open Workshop Page", function(self)
				if(table.Count(missingAddonsList:GetSelected()) > 1) then
					VToolkit:CreateErrorDialog("Can only open the workshop page for one addon at a time!")
					return
				end
				if(table.Count(missingAddonsList:GetSelected()) == 0) then
					VToolkit:CreateErrorDialog("Must select at least one addon to open the workshop page for!")
					return
				end
				steamworks.ViewFile(missingAddonsList:GetSelected()[1].wsid)
			end)
			openInWSButton:SetPos(330, 180)
			openInWSButton:SetSize(180, 35)
			openInWSButton:SetParent(panel)
			
			
			local donotaskButton = VToolkit:CreateButton("Close and do not ask again", function(self)
				VToolkit:CreateConfirmDialog("Are you sure?\nThis will take effect on every server you join.\nTo reset it, type \"vermilion_addonnag_do_not_ask 0\" into the console!", function()
					RunConsoleCommand("vermilion_addonnag_do_not_ask", "1")
					frame:Close()
				end, { Confirm = "Yes", Deny = "No", Default = false })
			end)
			donotaskButton:SetPos(330, panel:GetTall() - 50)
			donotaskButton:SetSize(180, 35)
			donotaskButton:SetParent(panel)
		end
	end)
	
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		if(GetConVarNumber("vermilion_addonnag_do_not_ask") == 0) then
			MODULE:NetStart("VAddonListRequest")
			net.SendToServer()
		end
	end)
	
end

Vermilion:RegisterModule(MODULE)