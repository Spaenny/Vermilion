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
MODULE.Name = "Battery Meter"
MODULE.ID = "battery_meter"
MODULE.Description = "Provides a small battery meter on the top of the screen."
MODULE.Author = "Ned"
MODULE.Permissions = {

}
MODULE.WBWidth = 0
MODULE.LastBatteryLevel = system.BatteryPower()

function MODULE:InitServer()
	
end

function MODULE:InitClient()
	CreateClientConVar("vermilion_battery_meter", 1, true, false)
	self:AddHook("HUDPaint", function()
		if(GetConVarNumber("vermilion_battery_meter") == 0) then return end
		if(MODULE.LastBatteryLevel != system.BatteryPower()) then
			if(MODULE.LastBatteryLevel == 255) then
				Vermilion:AddNotify("Computer unplugged!")
			end
			if(system.BatteryPower() == 255) then
				Vermilion:AddNotify("Computer plugged in!")
			end
			if(system.BatteryPower() == 20) then
				Vermilion:AddNotify("Low battery: 20%!")
			elseif(system.BatteryPower() == 15) then
				Vermilion:AddNotify("Low battery: 15%!")
			elseif(system.BatteryPower() == 10) then
				Vermilion:AddNotify("Low battery: 10%!", NOTIFY_ERROR)
			elseif(system.BatteryPower() == 5) then
				Vermilion:AddNotify("Critical battery: 5%!", NOTIFY_ERROR)
			end
			MODULE.LastBatteryLevel = system.BatteryPower()
		end
		if(system.BatteryPower() == 255) then return end
		MODULE.WBWidth = draw.WordBox( 8, (ScrW() / 2) - (MODULE.WBWidth / 2), 10, "Battery Level: " .. tostring(system.BatteryPower()) .. "%", "Default", Color(0, 0, 0, 255), Color(255, 255, 255, 255))
	end)
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		if(Vermilion:GetModule("client_settings") != nil) then
			Vermilion:GetModule("client_settings"):AddOption("vermilion_battery_meter", "Enable Battery Meter", "Checkbox", "Features", {})
		end
	end)
end

Vermilion:RegisterModule(MODULE)