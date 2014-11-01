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
MODULE.Name = "Death Notice"
MODULE.ID = "deathnotice"
MODULE.Description = "Broadcasts a notification when someone dies."
MODULE.Author = "Ned"
MODULE.Permissions = {

}

MODULE.HitGroupTranslations = {
	"head",
	"chest",
	"stomach",
	"left arm",
	"right arm",
	"left leg",
	"right leg"
}

function MODULE:InitShared()
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		local mod = Vermilion:GetModule("server_settings")
		if(mod != nil) then
			mod:AddOption("deathnotice", "enabled", "Enable Death Notices", "Checkbox", "Misc")
			mod:AddOption("deathnotice", "debugmode", "Enable Death Notice Debug Output", "Checkbox", "Misc")
		end
	end)
end

function MODULE:InitServer()
	self:AddHook("PhysgunDrop", function(vplayer, ent)
		if(IsValid(ent)) then
			ent:SetPhysicsAttacker(vplayer, 5)
		end
	end)
	
	self:AddHook("DoPlayerDeath", "DeathNotice", function(victim, attacker, dmg)
		if(not MODULE:GetData("enabled", true)) then return end
		local inflictor = dmg:GetInflictor()
		
		if(attacker == nil or victim == nil) then return end
		
		local typ = dmg:GetDamageType()
		
		local suicide = false
		
		if(victim == attacker) then
			suicide = true
		end
		
		local distance = nil
		if(not suicide) then
			distance = math.Round(victim:GetPos():Distance(attacker:GetPos()) * 0.01905)
		end
		
		local weapon_types = {
			0,
			8194,
			4098,
			536875010,
			67112960
		}
		
		if(typ == DMG_CRUSH) then
			local dropper = attacker
			if(inflictor:GetPhysicsAttacker(5) != nil) then
				dropper = inflictor:GetPhysicsAttacker(5)
			end
			MODULE:HandlePhysics(victim, dropper, inflictor, dmg, suicide)
		elseif(typ == DMG_BULLET or typ == DMG_CLUB or typ == DMG_BUCKSHOT or table.HasValue(weapon_types, typ)) then
			MODULE:HandleWeapon(victim, attacker, inflictor, dmg, suicide, distance)
		elseif(typ == DMG_BURN or typ == 268435464 or typ == DMG_FALL or typ == DMG_SHOCK or typ == DMG_DROWN or typ == DMG_ACID or typ == DMG_NERVEGAS or typ == DMG_POISON or typ == DMG_RADIATION) then
			MODULE:HandleEnvironmental(victim, attacker, inflictor, dmg, suicide)
		elseif(typ == DMG_BLAST or typ == DMG_BLAST_SURFACE or typ == 134217792) then
			MODULE:HandleExplosive(victim, attacker, inflictor, dmg, suicide, distance)
		elseif(typ == DMG_VEHICLE or typ == 17) then
			local driver = attacker
			if(attacker:IsVehicle() and attacker:GetDriver() != nil) then
				driver = attacker:GetDriver()
			end
			MODULE:HandleVehicle(victim, driver, inflictor, dmg)
		else
			MODULE:HandleGeneric(victim, attacker, inflictor, dmg, suicide, distance)
		end
	end)
	
	function MODULE:HandleGeneric(victim, attacker, inflictor, dmg, suicide, distance)
		if(self:GetData("debugmode", false, true)) then Msg("[GENERIC]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(dmg:GetDamageType() == DMG_DISSOLVE or dmg:GetDamageType() == 67108865) then
			if(attacker:IsPlayer()) then
				Vermilion:BroadcastNotification(victim:GetName() .. " was fizzled by " .. attacker:GetName())
			else
				Vermilion:BroadcastNotification(victim:GetName() .. " was fizzled.")
			end
		end
	end
	
	function MODULE:HandlePhysics(victim, attacker, inflictor, dmg, suicide)
		if(self:GetData("debugmode", false, true)) then Msg("[PHYSICS]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(attacker:IsPlayer()) then
			Vermilion:BroadcastNotification(victim:GetName() .. " was crushed by " .. attacker:GetName())
		else
			if(suicide or not IsValid(attacker)) then
				Vermilion:BroadcastNotification(victim:GetName() .. " crushed him/herself.")
			else
				Vermilion:BroadcastNotification(victim:GetName() .. " was crushed.")
			end
		end
	end
	
	function MODULE:HandleWeapon(victim, attacker, inflictor, dmg, suicide, distance)
		if(self:GetData("debugmode", false, true)) then Msg("[WEAPON]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = nil
			if(IsValid(attacker:GetActiveWeapon())) then
				weapon = string.lower(VToolkit.GetWeaponName(attacker:GetActiveWeapon():GetClass()))
			end
			if(weapon != nil) then
				if(suicide) then
					Vermilion:BroadcastNotification(victim:GetName() .. " killed him/herself with a " .. weapon)
				else
					local server_best = self:GetData("longest_shot", {}, true)[weapon] or 0
					local server_best_owner = self:GetData("longest_shot_holder", {}, true)[weapon] or ""
					local shotat = MODULE.HitGroupTranslations[victim:LastHitGroup()]
					if(shotat != nil) then
						shotat = " with a direct hit to the " .. shotat .. "."
					else
						shotat = "."
					end
					if(distance > server_best) then
						local recordtext = ""
						if(server_best_owner != "") then
							recordtext = " (NEW RECORD FOR THIS WEAPON! Old: " .. tostring(server_best) .. "m - " .. server_best_owner .. ")" 
						end
						
						Vermilion:BroadcastNotification(victim:GetName() .. " was killed by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away" .. shotat .. recordtext)
						self:GetData("longest_shot", {}, true)[weapon] = distance
						self:SetData("longest_shot_holder", {}, true)[weapon] = attacker:GetName()
					else
						Vermilion:BroadcastNotification(victim:GetName() .. " was killed by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away" .. shotat)
					end
				end
			else
				local shotat = MODULE.HitGroupTranslations[victim:LastHitGroup()]
				if(shotat != nil) then
					shotat = " with a direct hit to the " .. shotat .. "."
				else
					shotat = "."
				end
				Vermilion:BroadcastNotification(victim:GetName() .. " was killed by " .. attacker:GetName() .. " from " .. tostring(distance) .. "m away" .. shotat)
			end
		end
	end
	
	function MODULE:HandleEnvironmental(victim, attacker, inflictor, dmg, suicide)
		if(self:GetData("debugmode", false, true)) then Msg("[ENV]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(dmg:GetDamageType() == DMG_FALL) then
			Vermilion:BroadcastNotification(victim:GetName() .. " was dominated by Isaac Newton!")
		elseif(dmg:GetDamageType() == DMG_BURN or dmg:GetDamageType() == 268435464) then
			Vermilion:BroadcastNotification(victim:GetName() .. " burned to death.")
		end
	end
	
	function MODULE:HandleVehicle(victim, attacker, inflictor, dmg)
		if(self:GetData("debugmode", false, true)) then Msg("[VEHICLE]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(attacker:IsPlayer()) then
			local vehicleName = nil
			for i,k in pairs(list.Get("Vehicles")) do
				if(k.Class == inflictor:GetClass()) then
					vehicleName = i
					break
				end
			end
			if(vehicleName != nil) then
				Vermilion:BroadcastNotification(victim:GetName() .. " was run over by " .. attacker:GetName() .. " in a " .. vehicleName)
			else
				Vermilion:BroadcastNotification(victim:GetName() .. " was run over by " .. attacker:GetName())
			end
		end
	end
	
	function MODULE:HandleExplosive(victim, attacker, inflictor, dmg, suicide, distance)
		if(self:GetData("debugmode", false, true)) then Msg("[EXPLOSIVE]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = nil
			if(IsValid(attacker:GetActiveWeapon())) then
				weapon = string.lower(VToolkit.GetWeaponName(attacker:GetActiveWeapon():GetClass()))
			end
			if(weapon != nil and inflictor:GetClass() != "prop_physics") then
				if(suicide) then
					Vermilion:BroadcastNotification(victim:GetName() .. " has blown him/herself up with a " .. weapon)
				else
					local server_best = self:GetData("longest_shot", {}, true)[weapon] or 0
					local server_best_owner = self:GetData("longest_shot_holder", {}, true)[weapon] or ""
					if(distance > server_best) then
						local recordtext = ""
						if(server_best_owner != "") then
							recordtext = " (NEW RECORD FOR THIS WEAPON! Old: " .. tostring(server_best) .. "m - " .. server_best_owner .. ")" 
						end
						Vermilion:BroadcastNotification(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away." .. recordtext)
						self:GetData("longest_shot", {}, true)[weapon] = distance
						self:SetData("longest_shot_holder", {}, true)[weapon] = attacker:GetName()
					else
						Vermilion:BroadcastNotification(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away.")
					end
				end
			else
				if(suicide) then
					Vermilion:BroadcastNotification(victim:GetName() .. " has blown him/herself up.")
				else
					Vermilion:BroadcastNotification(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " from " .. tostring(distance) .. "m away.")
				end
			end
		end
	end
end

function MODULE:InitClient()
	
end

Vermilion:RegisterModule(MODULE)