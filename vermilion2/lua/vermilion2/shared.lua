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

Vermilion.Languages = {}
Vermilion.Modules = {}

--[[

	//		Languages		\\

]]--

function Vermilion.GetActiveLanguage()
	return "en"
end

function Vermilion:CreateLangBody(locale)
	
	local body = {}
	
	body.Locale = locale
	
	body.Translations = {}
	
	function body:Add(key, value)
		self.Translations[key] = value
	end
	
	function body:TranslateStr(key, values)
		if(not istable(values)) then return key end
		if(self.Translations[key] == nil) then return key end
		return string.format(self.Translations[key], unpack(values))
	end
	
	return body
	
end

function Vermilion:RegisterLanguage(body)
	self.Languages[body.Locale] = body
end

function Vermilion:TranslateStr(key, values)
	if(self.Languages[self.GetActiveLanguage()] != nil) then
		return self.Languages[self.GetActiveLanguage()]:TranslateStr(key, values)
	end
	return key
end

function Vermilion:LoadLanguages()
	for i,langFile in pairs(file.Find("vermilion2/lang/*.lua", "LUA")) do
		self.Log("Compiling language file: vermilion2/lang/" .. langFile)
		local compiled = CompileFile("vermilion2/lang/" .. langFile)
		if(isfunction(compiled)) then
			AddCSLuaFile("vermilion2/lang/" .. langFile)
			compiled()
		else
			self.Log("Failed to compile language file vermilion2/lang/" .. langFile)
		end
	end
end

Vermilion:LoadLanguages()





--[[

	//		Hooks		\\

]]--

Vermilion.Hooks = {}
Vermilion.SafeHooks = {}

function Vermilion:AddHook(hookType, hookName, safe, callback)
	if(safe) then
		if(self.SafeHooks[hookType] == nil) then self.SafeHooks[hookType] = {} end
		self.SafeHooks[hookType][hookName] = callback
		return
	end
	if(self.Hooks[hookType] == nil) then self.Hooks[hookType] = {} end
	self.Hooks[hookType][hookName] = callback
end

function Vermilion:DelHook(hookType, hookName, safe)
	if(safe) then
		if(self.SafeHooks[hookType] == nil) then return end
		self.SafeHooks[hookType][hookName] = nil
		return
	end
	if(self.Hooks[hookType] == nil) then return end
	self.Hooks[hookType][hookName] = nil
end


local oldHook = hook.Call

local vHookCall = function(evtName, gmTable, ...)
	local a, b, c, d, e, f
	if(Vermilion.SafeHooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.SafeHooks[evtName]) do
			hookFunc(...)
		end
	end
	if(Vermilion.Hooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.Hooks[evtName]) do
			a, b, c, d, e, f = hookFunc(...)
			if(a != nil) then return a, b, c, d, e, f end
		end
	end
	for i,mod in pairs(Vermilion.Modules) do
		a, b, c, d, e, f = mod:DistributeEvent(evtName, ...)
		if(a != nil) then return a, b, c, d, e, f end
		if(mod.Hooks != nil) then
			local hookList = mod.Hooks[evtName]
			if(hookList != nil) then
				for i,hookFunc in pairs(hookList) do
					a, b, c, d, e, f = hookFunc(...)
					if(a != nil) then
						return a, b, c, d, e, f
					end
				end
			end
		end
	end
	return oldHook(evtName, gmTable, ...)
end

hook.Call = vHookCall
timer.Create("Vermilion_OverrideHookCall", 1, 0, function()
	if(hook.Call != vHookCall) then
		hook.Call = vHookCall
	end
end)





--[[

	//		Client Startup		\\

]]--

if(SERVER) then
	util.AddNetworkString("Vermilion_ClientStart")
	
	Vermilion:AddHook("PlayerInitialSpawn", "SendVermilionActivate", true, function(ply)
		net.Start("Vermilion_ClientStart")
		net.Send(ply)
	end)
else
	net.Receive("Vermilion_ClientStart", function()
		timer.Simple(1, function() Vermilion:LoadModules() end)
	end)
end





--[[
	//		Module Loading		\\
]]--

function Vermilion:LoadModules()
	self.Log("Loading modules...")
	local files,dirs = file.Find("vermilion2/modules/*", "LUA")
	for index,dir in pairs(dirs) do
		if(file.Exists("vermilion2/modules/" .. dir .. "/init.lua", "LUA")) then
			local fle = CompileFile("vermilion2/modules/" .. dir .. "/init.lua")
			if(isfunction(fle)) then
				if(SERVER) then AddCSLuaFile("vermilion2/modules/" .. dir .. "/init.lua") end
				xpcall(fle, function(err)
					Vermilion.Log("Error loading module: " .. err)
					debug.Trace()
				end)
			end
		end
	end
	for index,mod in pairs(self.Modules) do
		mod:InitShared()
		if(SERVER) then
			mod:InitServer()
		else
			mod:InitClient()
		end
	end
	hook.Call(Vermilion.Event.MOD_LOADED)
	hook.Call(Vermilion.Event.MOD_POST)
end

function Vermilion:CreateBaseModule()
	if(Vermilion.ModuleBase == nil) then
		local base = {}
		base.Name = "Base Module"
		base.ID = "BaseModule"
		base.Description = "The author of this module doesn't know how to customise the module data. Get rid of it!"
		base.Author = "n00b"
		base.Hooks = {}
		base.Localisations = {}
		base.Permissions = {}
		base.PermissionDefinitions = {}
		base.DataChangeHooks = {}
		
		function base:InitClient() end
		function base:InitServer() end
		function base:InitShared() end
		function base:Destroy() end
		
		function base:RegisterChatCommands() end
		
		function base:GetData(name, default, set)
			if(Vermilion.Data.Module[self.ID] == nil) then Vermilion.Data.Module[self.ID] = {} end
			if(Vermilion.Data.Module[self.ID][name] == nil) then
				if(set) then self:SetData(name, default) end
				return default
			end
			return Vermilion:GetModuleData(self.ID, name, default)
		end
		
		function base:SetData(name, value)
			Vermilion:SetModuleData(self.ID, name, value)
		end
		
		function base:AddDataChangeHook(dataName, hookName, cHook)
			if(self.DataChangeHooks[dataName] == nil) then self.DataChangeHooks[dataName] = {} end
			self.DataChangeHooks[dataName][hookName] = cHook
		end
		
		function base:RemoveDataChangeHook(dataName, hookName)
			if(self.DataChangeHooks[dataName] == nil) then return end
			self.DataChangeHooks[dataName][hookName] = nil
		end
		
		function base:AddHook(evtName, id, func)
			if(func == nil) then
				func = id
				id = evtName
			end
			if(self.Hooks[evtName] == nil) then
				self.Hooks[evtName] = {}
			end
			self.Hooks[evtName][id] = func
		end
		function base:RemoveHook(evtName, id)
			if(self.Hooks[evtName] != nil) then
				self.Hooks[evtName][id] = nil
			else
			
			end
		end
		
		function base:NetHook(nstr, func)
			net.Receive(nstr, function(len, ply)
				func(ply)
			end)
		end
		
		base:AddHook("VDefinePermission", function(permission)
			if(base.PermissionDefinitions[permission] != nil) then return base.PermissionDefinitions[permission] end
		end)
		
		
		function base:DistributeEvent(event, parameters) end
		
		Vermilion.ModuleBase = base
	end
	
	local base = {}
	
	setmetatable(base, { __index = Vermilion.ModuleBase })
	
	return base
end

function Vermilion:RegisterModule(mod)
	Vermilion.Modules[mod.ID] = mod
	if(SERVER) then
		for i,k in pairs(mod.Permissions) do
			table.insert(self.AllPermissions, { Permission = k, Owner = mod.ID })
		end
		if(mod.NetworkStrings != nil) then
			for i,k in pairs(mod.NetworkStrings) do
				util.AddNetworkString(k)
			end
		end
	end
	if(mod.ConVars != nil) then
		if(SERVER and mod.ConVars.Server != nil) then
			for i,k in pairs(mod.ConVars.Server) do
				local flags = k.Flags or {}
				CreateConVar(k.Name, k.Value, flags, k.HelpText)
			end
		end
		if(CLIENT and mod.ConVars.Client != nil) then
			for i,k in pairs(mod.ConVars.Client) do
				CreateClientConVar(k.Name, k.Value, k.Keep or true, k.Userdata or false)
			end
		end
	end
end

function Vermilion:GetModule(name)
	return self.Modules[name]
end

if(SERVER) then
	util.AddNetworkString("VPlayerInitialSpawn")
	
	Vermilion:AddHook("PlayerInitialSpawn", "VClientNotify", true, function(vplayer)
		net.Start("VPlayerInitialSpawn")
		net.WriteTable({vplayer:GetName(), vplayer:SteamID(), Vermilion:GetUser(vplayer):GetRankName(), vplayer:EntIndex()})
		net.Broadcast()
	end)
else
	net.Receive("VPlayerInitialSpawn", function()
		hook.Run("PlayerInitialSpawn", unpack(net.ReadTable()))
	end)
end
