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
MODULE.Name = "Bans"
MODULE.ID = "bans"
MODULE.Description = "Manages the ban system."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"ban_user",
	"unban_user",
	"kick_user",
	"manage_bans"
}

function MODULE:InitServer()
	
end

function MODULE:InitClient()
	Vermilion.Menu:AddCategory("player", 4)

	Vermilion.Menu:AddPage({
			ID = "bans",
			Name = "Kick/Ban Management",
			Order = 1,
			Category = "player",
			Size = { 600, 560 },
			Conditional = function(vplayer)
				return Vermilion:HasPermission("manage_bans")
			end,
			Builder = function(panel)
				local label = VToolkit:CreateLabel(Vermilion:TranslateStr("under_construction"))
				label:SetFont("DermaLarge")
				label:SizeToContents()
				label:SetPos((panel:GetWide() - label:GetWide()) / 2, (panel:GetTall() - label:GetTall()) / 2)
				label:SetParent(panel)
			end
		})
end

Vermilion:RegisterModule(MODULE)